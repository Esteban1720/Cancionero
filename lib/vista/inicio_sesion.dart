import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class InicioSesion extends StatefulWidget {
  const InicioSesion({super.key});

  @override
  State<InicioSesion> createState() => _InicioSesionState();
}

class _InicioSesionState extends State<InicioSesion> {
  static const String _googleServerClientId =
      '383332243396-bab0vantsna96rokt3ssc13jbllgq8ac.apps.googleusercontent.com';

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey1 = GlobalKey<FormState>();
  bool _loading = false;
  bool _googleLoading = false;
  bool _obscurePassword = true;
  bool _googleInitialized = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: <Widget>[
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 2, 180, 250),
                  Color.fromARGB(121, 10, 6, 255),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Image.asset('assets/logo.png', height: 300),
          ),
          Transform.translate(
            offset: const Offset(0, -40),
            child: Center(
              child: SingleChildScrollView(
                child: Card(
                  elevation: 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 260,
                    bottom: 20,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey1,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            TextFormField(
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              keyboardType: TextInputType.emailAddress,
                              controller: emailController,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person),
                                labelText: 'Correo:',
                                labelStyle: TextStyle(fontSize: 20.1),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingrese el correo';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 40),
                            TextFormField(
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              controller: passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Contrasena:',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                labelStyle: const TextStyle(fontSize: 20.1),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingrese la contrasena';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                backgroundColor: Theme.of(context).primaryColor,
                              ),
                              onPressed: () {
                                if (_formKey1.currentState!.validate()) {
                                  _login();
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const Text(
                                    'Iniciar Sesion',
                                    style: TextStyle(
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontSize: 20,
                                    ),
                                  ),
                                  if (_loading)
                                    Container(
                                      height: 20,
                                      width: 20,
                                      margin: const EdgeInsets.only(left: 20),
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 52),
                              ),
                              onPressed: _googleLoading ? null : _loginWithGoogle,
                              icon: _googleLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.alternate_email),
                              label: Text(
                                _googleLoading
                                    ? 'Ingresando con Google...'
                                    : 'Continuar con Google',
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const Text('No estas registrado?'),
                                TextButton(
                                  onPressed: () {
                                    _showRegister(context);
                                  },
                                  child: const Text(
                                    'Registrarse',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _login() async {
    setState(() {
      _loading = true;
    });

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await _asegurarPerfilYCancionesAntiguas(cred.user);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/dashboard',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al iniciar sesion')));
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _showRegister(BuildContext context) {
    Navigator.of(context).pushNamed('/registro');
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _googleLoading = true;
    });

    try {
      final googleSignIn = GoogleSignIn.instance;

      if (!_googleInitialized) {
        await googleSignIn.initialize(
          serverClientId: _googleServerClientId,
        );
        _googleInitialized = true;
      }

      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final user = userCredential.user;

      await _asegurarPerfilYCancionesAntiguas(user);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/dashboard',
        (route) => false,
      );
    } on GoogleSignInException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Google Sign-In: ${e.code.name}${e.description == null ? '' : ' - ${e.description}'}',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Firebase Auth: ${e.code}${e.message == null ? '' : ' - ${e.message}'}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo iniciar sesion con Google: $e'),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _googleLoading = false;
      });
    }
  }

  Future<void> _asegurarPerfilYCancionesAntiguas(User? user) async {
    if (user == null) {
      return;
    }

    final userRef = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);
    final userDoc = await userRef.get();
    final datosActuales = userDoc.data() ?? <String, dynamic>{};
    final nombreGoogle = (user.displayName ?? '').trim();
    final email = (user.email ?? '').trim();
    final nombreActual = (datosActuales['user'] ?? '').toString().trim();
    final nombreResuelto = nombreGoogle.isNotEmpty
        ? nombreGoogle
        : nombreActual.isNotEmpty
        ? nombreActual
        : email.isNotEmpty
        ? email.split('@').first
        : 'Usuario';

    final actualizacion = <String, dynamic>{
      'user': nombreResuelto,
      'user_lower': nombreResuelto.toLowerCase(),
      'email': email,
      'foto': ((user.photoURL ?? '').trim().isNotEmpty
              ? user.photoURL
              : datosActuales['foto']) ??
          '',
    };

    if (!userDoc.exists) {
      actualizacion['fecha_registro'] = FieldValue.serverTimestamp();
      actualizacion['fecha_nacimiento'] = null;
    }

    await userRef.set(actualizacion, SetOptions(merge: true));
    await _migrarCancionesAntiguas(user.uid, datosActuales);
  }

  Future<void> _migrarCancionesAntiguas(
    String uid,
    Map<String, dynamic> datosUsuario,
  ) async {
    final nuevasCancionesRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('canciones');

    final existentesSnapshot = await nuevasCancionesRef.get();
    final batchActualizacion = FirebaseFirestore.instance.batch();
    final firmasExistentes = existentesSnapshot.docs
        .map((doc) => ((doc.data())['firma_legacy'] ?? '').toString())
        .where((firma) => firma.isNotEmpty)
        .toSet();

    var cancionesActualizadas = 0;

    for (final doc in existentesSnapshot.docs) {
      final data = doc.data();
      final bloquesActuales = data['bloques'];
      final yaTieneBloques = bloquesActuales is List && bloquesActuales.isNotEmpty;

      if (yaTieneBloques) {
        final firma = _firmaLegacy(data['titulo'] ?? '', bloquesActuales);
        if (firma.isNotEmpty) {
          firmasExistentes.add(firma);
        }
        continue;
      }

      final normalizada = _normalizarCancionLegacy(data);
      if (normalizada == null) {
        continue;
      }

      final firma = _firmaLegacy(normalizada['titulo'], normalizada['bloques']);
      batchActualizacion.set(doc.reference, {
        'titulo': normalizada['titulo'],
        'bloques': normalizada['bloques'],
        'actualizado_en': FieldValue.serverTimestamp(),
        'firma_legacy': firma,
        'migrada_legacy': true,
      }, SetOptions(merge: true));
      firmasExistentes.add(firma);
      cancionesActualizadas++;
    }

    if (cancionesActualizadas > 0) {
      await batchActualizacion.commit();
    }

    final cancionesLegacy = <Map<String, dynamic>>[];

    final cancionesEmbebidas = datosUsuario['canciones'];
    if (cancionesEmbebidas is List) {
      for (final item in cancionesEmbebidas) {
        if (item is Map) {
          cancionesLegacy.add(Map<String, dynamic>.from(item));
        }
      }
    }

    final cancionesEmbebidasAlternas = datosUsuario['mis_canciones'];
    if (cancionesEmbebidasAlternas is List) {
      for (final item in cancionesEmbebidasAlternas) {
        if (item is Map) {
          cancionesLegacy.add(Map<String, dynamic>.from(item));
        }
      }
    }

    Future<void> cargarTopLevelLegacy(
      String fieldPath,
      String origen,
    ) async {
      try {
        final query = await FirebaseFirestore.instance
            .collection('canciones')
            .where(fieldPath, isEqualTo: uid)
            .get();

        for (final doc in query.docs) {
          final mapa = Map<String, dynamic>.from(doc.data());
          mapa['_legacy_id'] = doc.id;
          mapa['_legacy_origen'] = origen;
          cancionesLegacy.add(mapa);
        }
      } catch (_) {
        // Si la coleccion antigua ya no existe o las reglas no permiten leerla,
        // seguimos sin interrumpir el inicio de sesion.
      }
    }

    await cargarTopLevelLegacy('uid', 'canciones.uid');
    await cargarTopLevelLegacy('user_uid', 'canciones.user_uid');

    final batch = FirebaseFirestore.instance.batch();
    var migradas = 0;

    for (final legacy in cancionesLegacy) {
      final normalizada = _normalizarCancionLegacy(legacy);
      if (normalizada == null) {
        continue;
      }

      final firma = _firmaLegacy(normalizada['titulo'], normalizada['bloques']);
      if (firmasExistentes.contains(firma)) {
        continue;
      }

      final destino = nuevasCancionesRef.doc();
      batch.set(destino, {
        ...normalizada,
        'creado_en': FieldValue.serverTimestamp(),
        'actualizado_en': FieldValue.serverTimestamp(),
        'firma_legacy': firma,
        'migrada_legacy': true,
      });
      firmasExistentes.add(firma);
      migradas++;
    }

    if (migradas > 0) {
      await batch.commit();
    }
  }

  Map<String, dynamic>? _normalizarCancionLegacy(Map<String, dynamic> legacy) {
    final titulo = (legacy['titulo'] ??
            legacy['nombre'] ??
            legacy['cancion'] ??
            legacy['title'] ??
            '')
        .toString()
        .trim();

    final bloquesRaw = legacy['bloques'] ??
        legacy['secciones'] ??
        legacy['partes'] ??
        legacy['contenido'] ??
        legacy['notas'];

    final bloques = _normalizarBloquesLegacy(
      bloquesRaw,
      subtitulosRaw: legacy['subtitulos'],
      subtituloRaw: legacy['subtitulo'],
    );

    if (titulo.isEmpty || bloques.isEmpty) {
      return null;
    }

    return {
      'titulo': titulo,
      'bloques': bloques,
    };
  }

  List<Map<String, dynamic>> _normalizarBloquesLegacy(
    dynamic bloquesRaw, {
    dynamic subtitulosRaw,
    dynamic subtituloRaw,
  }) {
    final resultado = <Map<String, dynamic>>[];
    final subtitulos = subtitulosRaw is List
        ? subtitulosRaw.map((item) => '$item'.trim()).toList()
        : <String>[];

    if (bloquesRaw is List) {
      for (var i = 0; i < bloquesRaw.length; i++) {
        final item = bloquesRaw[i];
        if (item is Map) {
          final mapa = Map<String, dynamic>.from(item);
          final subtitulo =
              (mapa['subtitulo'] ?? mapa['titulo'] ?? mapa['nombre'] ?? '')
                  .toString()
                  .trim();
          final notas = _normalizarNotasLegacy(
            mapa['notas'] ?? mapa['acordes'] ?? mapa['contenido'],
          );

          if (notas.isNotEmpty) {
            resultado.add({
              'subtitulo': subtitulo,
              'notas': notas,
            });
          }
        } else if (item is List || item is String) {
          final notas = _normalizarNotasLegacy(item);
          if (notas.isNotEmpty) {
            resultado.add({
              'subtitulo': _resolverSubtituloLegacy(
                subtitulos,
                subtituloRaw,
                resultado.length,
              ),
              'notas': notas,
            });
          }
        }
      }
    } else if (bloquesRaw is String) {
      final notas = _normalizarNotasLegacy(bloquesRaw);
      if (notas.isNotEmpty) {
        resultado.add({
          'subtitulo': _resolverSubtituloLegacy(
            subtitulos,
            subtituloRaw,
            0,
          ),
          'notas': notas,
        });
      }
    }

    return resultado;
  }

  List<String> _normalizarNotasLegacy(dynamic notasRaw) {
    if (notasRaw is List) {
      return notasRaw
          .map((item) => '$item'.trim())
          .where((n) => n.isNotEmpty)
          .toList();
    }

    if (notasRaw is String) {
      return notasRaw
          .replaceAll('–', '-')
          .replaceAll('—', '-')
          .split(RegExp(r'\s*-\s*|[\n,;/|]+'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .map(_normalizarCapitalizacionNota)
          .toList();
    }

    return const [];
  }

  String _resolverSubtituloLegacy(
    List<String> subtitulos,
    dynamic subtituloRaw,
    int index,
  ) {
    if (subtitulos.length > index && subtitulos[index].isNotEmpty) {
      return subtitulos[index];
    }

    final subtituloUnico = (subtituloRaw ?? '').toString().trim();
    if (subtituloUnico.isNotEmpty) {
      return subtituloUnico;
    }

    return 'Seccion ${index + 1}';
  }

  String _normalizarCapitalizacionNota(String nota) {
    if (nota.isEmpty) {
      return nota;
    }

    final base = nota.toLowerCase();
    return base[0].toUpperCase() + base.substring(1);
  }

  String _firmaLegacy(String titulo, dynamic bloques) {
    return '${titulo.trim().toLowerCase()}::${bloques.toString().toLowerCase()}';
  }
}
