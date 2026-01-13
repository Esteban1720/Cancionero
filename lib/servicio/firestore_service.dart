import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Crea el documento del usuario en la colección 'usuarios' si no existe.
  /// Guarda campos en español: 'nombre', 'usuario', 'contrasena'.
  Future<void> crearUsuarioSiNoExiste(User user) async {
    final ref = _db.collection('usuarios').doc(user.uid);
    final doc = await ref.get();
    final rawNombre = (user.displayName ?? '').toString().trim();
    final updatedFields = {
      'nombre': rawNombre,
      'nombre_search': rawNombre.toLowerCase(),
      'nombre_tokens': rawNombre.isEmpty
          ? <String>[]
          : rawNombre
                .split(RegExp(r'\s+'))
                .map((s) => s.toLowerCase())
                .where((s) => s.isNotEmpty)
                .toList(),
      'usuario': user.email ?? '',
    };

    if (!doc.exists) {
      // Crear sólo los campos mínimos permitidos por las reglas de seguridad
      await ref.set({
        'nombre': updatedFields['nombre'],
        'usuario': updatedFields['usuario'],
      });

      // Luego añadir el resto de campos mediante merge (esto es un "update" lógico y
      // está permitido cuando request.auth.uid == userId según las reglas)
      await ref.set({
        ...updatedFields,
        'contrasena': null,
        'metodo_autenticacion': 'google',
        'creado_en': FieldValue.serverTimestamp(),
        'idioma': 'es',
      }, SetOptions(merge: true));

      // ejemplo: crear subcolección 'canciones' vacía o con un documento ejemplo
      await ref.collection('canciones').doc('ejemplo').set({
        'titulo': 'Canción de ejemplo',
        'subtitulos': [],
        'notas': [],
        'creado_en': FieldValue.serverTimestamp(),
      });
    } else {
      // Si ya existe, actualizamos campos de nombre/search/tokens para garantizar búsquedas correctas
      await ref.set({...updatedFields}, SetOptions(merge: true));
    }
  }

  /// Crea un usuario registrado por correo
  Future<void> crearUsuarioConCorreo({
    required String uid,
    required String email,
    required String nombre,
  }) async {
    final ref = _db.collection('usuarios').doc(uid);
    final rawNombre = nombre.trim();
    final datos = {
      'nombre': rawNombre,
      'nombre_search': rawNombre.toLowerCase(),
      'nombre_tokens': rawNombre.isEmpty
          ? <String>[]
          : rawNombre
                .split(RegExp(r'\s+'))
                .map((s) => s.toLowerCase())
                .where((s) => s.isNotEmpty)
                .toList(),
      'usuario': email,
      'contrasena': null, // No almacenar contraseña
      'metodo_autenticacion': 'correo',
      'creado_en': FieldValue.serverTimestamp(),
      'idioma': 'es',
    };
    await ref.set(datos);
    await ref.collection('canciones').doc('ejemplo').set({
      'titulo': 'Canción de ejemplo',
      'subtitulos': [],
      'notas': [],
      'creado_en': FieldValue.serverTimestamp(),
    });
  }

  /// Crea una canción para un usuario (retorna el id del documento creado)
  Future<String> crearCancion({
    required String uid,
    required Map<String, dynamic> cancion,
  }) async {
    final ref = _db.collection('usuarios').doc(uid).collection('canciones');
    final docRef = await ref.add({
      ...cancion,
      'creado_en': FieldValue.serverTimestamp(),
    });
    // Guardar id en el documento para fácil referencia si se desea
    await docRef.update({'id': docRef.id});
    return docRef.id;
  }

  /// Actualiza una canción existente del usuario
  Future<void> actualizarCancion({
    required String uid,
    required String id,
    required Map<String, dynamic> cancion,
  }) async {
    final docRef = _db
        .collection('usuarios')
        .doc(uid)
        .collection('canciones')
        .doc(id);
    await docRef.set({
      ...cancion,
      'actualizado_en': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Elimina una canción del usuario
  Future<void> eliminarCancion({
    required String uid,
    required String id,
  }) async {
    final docRef = _db
        .collection('usuarios')
        .doc(uid)
        .collection('canciones')
        .doc(id);
    await docRef.delete();
  }

  /// Devuelve un stream de snapshots (como modelo Cancion)
  Stream<List<dynamic>> obtenerCancionesModelStreamRaw(String uid) {
    return _db
        .collection('usuarios')
        .doc(uid)
        .collection('canciones')
        .orderBy('creado_en', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList(),
        );
  }

  /// Para quienes prefieren mapear a la lista de modelos, el view puede usar esto
  Stream<List<Map<String, dynamic>>> obtenerCancionesModelStream(String uid) {
    return _db
        .collection('usuarios')
        .doc(uid)
        .collection('canciones')
        .orderBy('creado_en', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => {...d.data(), 'id': d.id})
              .cast<Map<String, dynamic>>()
              .toList(),
        );
  }

  /// Buscar usuarios por nombre (prefijo, case-insensitive).
  ///
  /// Implementación:
  /// 1) Intentamos prefijo case-insensitive en `nombre_search`.
  /// 2) Si no hay resultados, buscamos por token con `nombre_tokens` usando `arrayContains`.
  /// 3) Como último recurso traemos hasta 100 usuarios y filtramos localmente por substring.
  Future<List<Map<String, dynamic>>> buscarUsuariosPorNombre(
    String nombre,
  ) async {
    final q = nombre.trim().toLowerCase();

    if (q.isEmpty) return [];

    // 1) Prefijo insensible a mayúsculas usando 'nombre_search'
    try {
      final prefQuery = _db
          .collection('usuarios')
          .orderBy('nombre_search')
          .startAt([q])
          .endAt([q + '\uf8ff']);
      final prefSnap = await prefQuery.get();
      final prefResults = prefSnap.docs
          .map((d) => {...d.data(), 'uid': d.id})
          .toList();
      if (prefResults.isNotEmpty) return prefResults;
    } catch (_) {
      // ignore and try fallback
    }

    // 2) Búsqueda por token (arrayContains) en 'nombre_tokens'
    try {
      final tokenQuery = _db
          .collection('usuarios')
          .where('nombre_tokens', arrayContains: q);
      final tokenSnap = await tokenQuery.get();
      final tokenResults = tokenSnap.docs
          .map((d) => {...d.data(), 'uid': d.id})
          .toList();
      if (tokenResults.isNotEmpty) return tokenResults;
    } catch (_) {}

    // 3) Último recurso: traer muestra limitada y filtrar localmente (case-insensitive substring)
    final sampleSnap = await _db.collection('usuarios').limit(100).get();
    final sampleResults = sampleSnap.docs
        .map((d) => {...d.data(), 'uid': d.id})
        .where((m) {
          final nombreDoc = (m['nombre'] ?? '').toString().toLowerCase();
          return nombreDoc.contains(q);
        })
        .toList();
    return sampleResults;
  }

  /// Agrega una relación de amistad entre dos usuarios (bidireccional).
  Future<void> agregarAmigo({
    required String uid,
    required String amigoUid,
    required String amigoNombre,
  }) async {
    final refA = _db
        .collection('usuarios')
        .doc(uid)
        .collection('amigos')
        .doc(amigoUid);
    final refB = _db
        .collection('usuarios')
        .doc(amigoUid)
        .collection('amigos')
        .doc(uid);

    final batch = _db.batch();
    batch.set(refA, {
      'uid': amigoUid,
      'nombre': amigoNombre,
      'agregado_en': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Intentamos leer el nombre local (si existe) para guardar en el documento del amigo
    final selfDoc = await _db.collection('usuarios').doc(uid).get();
    final miNombre = (selfDoc.exists ? (selfDoc.data()?['nombre'] ?? '') : '');

    batch.set(refB, {
      'uid': uid,
      'nombre': miNombre,
      'agregado_en': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Devuelve stream de amigos del usuario
  Stream<List<Map<String, dynamic>>> obtenerAmigosStream(String uid) {
    return _db
        .collection('usuarios')
        .doc(uid)
        .collection('amigos')
        .orderBy('agregado_en', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'uid': d.id}).toList());
  }

  /// Stream de canciones compartidas con este usuario (documentos en `compartidas`)
  Stream<List<Map<String, dynamic>>> obtenerCancionesRecibidasStream(String uid) {
    return _db
        .collection('usuarios')
        .doc(uid)
        .collection('compartidas')
        .orderBy('compartido_en', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  /// Actualiza una canción dentro del documento compartido (permite editar la copia compartida que está en tu cuenta)
  Future<void> actualizarCancionCompartida({
    required String uid,
    required String sharedId,
    required Map<String, dynamic> cancion,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid != uid) {
      throw FirebaseException(plugin: 'FirestoreService', message: 'Usuario no autenticado o UID no coincide al actualizar compartida');
    }
    final ref = _db.collection('usuarios').doc(uid).collection('compartidas').doc(sharedId);
    try {
      await ref.set({
        'cancion': cancion,
        'actualizado_en': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (e is FirebaseException && (e.code == 'permission-denied' || (e.message ?? '').contains('PERMISSION_DENIED') || (e.message ?? '').contains('Missing or insufficient permissions'))) {
        throw FirebaseException(plugin: 'FirestoreService', message: 'No tienes permiso para editar esta canción compartida.');
      }
      rethrow;
    }
  }

  /// Elimina un documento de 'compartidas' del usuario
  Future<void> eliminarCancionCompartida({
    required String uid,
    required String sharedId,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid != uid) {
      throw FirebaseException(plugin: 'FirestoreService', message: 'Usuario no autenticado o UID no coincide al eliminar compartida');
    }
    final ref = _db.collection('usuarios').doc(uid).collection('compartidas').doc(sharedId);
    try {
      await ref.delete();
    } catch (e) {
      if (e is FirebaseException && (e.code == 'permission-denied' || (e.message ?? '').contains('PERMISSION_DENIED') || (e.message ?? '').contains('Missing or insufficient permissions'))) {
        throw FirebaseException(plugin: 'FirestoreService', message: 'No tienes permiso para eliminar esta canción compartida.');
      }
      rethrow;
    }
  }

  /// Mueve una canción compartida a las canciones propias del usuario: crea en 'canciones' y luego borra la compartida.
  /// Retorna el id de la nueva canción creada.
  Future<String> moverCancionCompartidaAPropias({
    required String uid,
    required String sharedId,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid != uid) {
      throw FirebaseException(plugin: 'FirestoreService', message: 'Usuario no autenticado o UID no coincide al mover compartida');
    }
    final sharedRef = _db.collection('usuarios').doc(uid).collection('compartidas').doc(sharedId);
    try {
      final snap = await sharedRef.get();
      if (!snap.exists) throw FirebaseException(plugin: 'FirestoreService', message: 'Documento compartido no encontrado');
      final cancionMap = (snap.data()?['cancion'] ?? {}) as Map<String, dynamic>;
      // Crear en canciones
      final newId = await crearCancion(uid: uid, cancion: cancionMap);
      // Luego eliminar la compartida
      await sharedRef.delete();
      return newId;
    } catch (e) {
      if (e is FirebaseException && (e.code == 'permission-denied' || (e.message ?? '').contains('PERMISSION_DENIED') || (e.message ?? '').contains('Missing or insufficient permissions'))) {
        throw FirebaseException(plugin: 'FirestoreService', message: 'No tienes permiso para mover esta canción compartida.');
      }
      rethrow;
    }
  }

  /// Comparte una canción del usuario 'fromUid' con el usuario 'toUid'.
  /// Crea un documento en `usuarios/{toUid}/compartidas` con metadatos.
  Future<void> compartirCancion({
    required String fromUid,
    required String toUid,
    required Map<String, dynamic> cancion,
    String? nota,
  }) async {
    // Intentamos escribir directamente; si Firestore devuelve PERMISSION_DENIED, traducimos a mensaje amigable
    final fromDoc = await _db.collection('usuarios').doc(fromUid).get();
    final fromNombre = fromDoc.exists ? (fromDoc.data()?['nombre'] ?? '') : '';

    final ref = _db
        .collection('usuarios')
        .doc(toUid)
        .collection('compartidas')
        .doc();
    try {
      final payload = {
        'fromUid': fromUid,
        'fromNombre': fromNombre,
        'cancion': cancion,
        'compartido_en': FieldValue.serverTimestamp(),
      };
      if (nota != null) payload['nota'] = nota;

      print('compartirCancion: escribiendo compartida para $toUid, payload keys: ${payload.keys}');
      await ref.set(payload);
      print('compartirCancion: compartida OK para $toUid');
    } catch (e) {
      // Si Firestore deniega permisos, traducimos la respuesta para la UI
      if (e is FirebaseException && (e.code == 'permission-denied' || (e.message ?? '').contains('PERMISSION_DENIED') || (e.message ?? '').contains('Missing or insufficient permissions'))) {
        print('compartirCancion: PERMISSION_DENIED al compartir con $toUid');
        throw FirebaseException(
          plugin: 'FirestoreService',
          message: 'No puedes compartir: no sois amigos o la amistad no es recíproca.',
        );
      }

      print('compartirCancion: ERROR al compartir con $toUid: $e');
      throw FirebaseException(
        plugin: 'FirestoreService',
        message: 'Error al compartir canción con $toUid: $e',
      );
    }
  }

  /// Envía una solicitud de amistad al usuario `toUid` desde `fromUid`.
  /// Crea el documento en `usuarios/{toUid}/solicitudes/{fromUid}` con metadatos.
  Future<void> enviarSolicitudAmistad({
    required String fromUid,
    required String fromNombre,
    required String toUid,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid != fromUid) {
      throw FirebaseException(
        plugin: 'FirestoreService',
        message: 'Usuario no autenticado o UID no coincide al enviar solicitud',
      );
    }

    final ref = _db
        .collection('usuarios')
        .doc(toUid)
        .collection('solicitudes')
        .doc(fromUid);

    try {
      await ref.set({
        'fromUid': fromUid,
        'fromNombre': fromNombre,
        'enviado_en': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw FirebaseException(
        plugin: 'FirestoreService',
        message: 'Error al enviar solicitud a $toUid desde $fromUid: $e',
      );
    }
  }

  /// Stream de solicitudes entrantes para el usuario `uid`.
  Stream<List<Map<String, dynamic>>> obtenerSolicitudesEntrantesStream(
    String uid,
  ) {
    return _db
        .collection('usuarios')
        .doc(uid)
        .collection('solicitudes')
        .orderBy('enviado_en', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'uid': d.id}).toList());
  }

  /// Stream de UIDs a quienes `fromUid` ya envió solicitudes pendientes.
  Stream<List<String>> obtenerSolicitudesSalientesUidsStream(String fromUid) {
    return _db
        .collectionGroup('solicitudes')
        .where('fromUid', isEqualTo: fromUid)
        .snapshots()
        .map((s) => s.docs
            .map((d) => d.reference.parent.parent?.id ?? '')
            .where((id) => id.isNotEmpty)
            .toList());
  }

  /// Verifica si `fromUid` ya envió una solicitud a `toUid`.
  Future<bool> tieneSolicitudEnviada({
    required String fromUid,
    required String toUid,
  }) async {
    final doc = await _db
        .collection('usuarios')
        .doc(toUid)
        .collection('solicitudes')
        .doc(fromUid)
        .get();
    return doc.exists;
  }

  /// Acepta una solicitud entrante: agrega la relación de amigos bidireccional y borra la solicitud.
  Future<void> aceptarSolicitud({
    required String uid,
    required String fromUid,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid != uid) {
      throw FirebaseException(
        plugin: 'FirestoreService',
        message: 'Usuario no autenticado o UID no coincide al aceptar solicitud',
      );
    }

    final fromDoc = await _db.collection('usuarios').doc(fromUid).get();
    final fromNombre = fromDoc.exists ? (fromDoc.data()?['nombre'] ?? '') : '';

    final selfDoc = await _db.collection('usuarios').doc(uid).get();
    final miNombre = selfDoc.exists ? (selfDoc.data()?['nombre'] ?? '') : '';

    final refA = _db
        .collection('usuarios')
        .doc(uid)
        .collection('amigos')
        .doc(fromUid);
    final refB = _db
        .collection('usuarios')
        .doc(fromUid)
        .collection('amigos')
        .doc(uid);
    final reqRef = _db
        .collection('usuarios')
        .doc(uid)
        .collection('solicitudes')
        .doc(fromUid);

    // Verificar que la solicitud aún exista antes de aceptar
    final reqSnap = await reqRef.get();
    if (!reqSnap.exists) {
      throw FirebaseException(
        plugin: 'FirestoreService',
        message: 'Solicitud no encontrada o ya procesada entre $uid y $fromUid',
      );
    }

    // Para ayudar a depurar permisos, ejecutamos las operaciones por separado
    // (Esto puede dejar estado parcial si una operación falla; para producción preferir usar batch/transaction)
    try {
      await refA.set({
        'uid': fromUid,
        'nombre': fromNombre,
        'agregado_en': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw FirebaseException(
        plugin: 'FirestoreService',
        message: 'Error al crear la entrada de amigo para $uid <- $fromUid: $e',
      );
    }

    try {
      await refB.set({
        'uid': uid,
        'nombre': miNombre,
        'agregado_en': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw FirebaseException(
        plugin: 'FirestoreService',
        message: 'Error al crear la entrada de amigo para $fromUid <- $uid: $e',
      );
    }

    try {
      await reqRef.delete();
    } catch (e) {
      throw FirebaseException(
        plugin: 'FirestoreService',
        message: 'Error al borrar la solicitud entre $uid y $fromUid: $e',
      );
    }
  }

  /// Rechaza (borra) una solicitud entrante.
  Future<void> rechazarSolicitud({
    required String uid,
    required String fromUid,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid != uid) {
      throw FirebaseException(
        plugin: 'FirestoreService',
        message: 'Usuario no autenticado o UID no coincide al rechazar solicitud',
      );
    }

    final reqRef = _db
        .collection('usuarios')
        .doc(uid)
        .collection('solicitudes')
        .doc(fromUid);
    try {
      await reqRef.delete();
    } catch (e) {
      throw FirebaseException(
        plugin: 'FirestoreService',
        message: 'Error al rechazar solicitud de $fromUid para $uid: $e',
      );
    }
  }
}
