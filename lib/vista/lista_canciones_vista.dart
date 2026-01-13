import 'package:flutter/material.dart';
import 'package:cancionero/modelo/cancion.dart';
import 'package:cancionero/servicio/servicio_almacenamiento.dart';
import 'dart:io';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cancionero/servicio/firestore_service.dart';
import 'package:cancionero/servicio/auth_service.dart';
import 'package:cancionero/vista/gradient_scaffold.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cancionero/vista/tema.dart';
import 'detalle_cancion_vista.dart';
import 'editar_cancion_vista.dart';
import 'package:cancionero/vista/login.dart';

class ListaCancionesVista extends StatefulWidget {
  const ListaCancionesVista({super.key});

  @override
  State<ListaCancionesVista> createState() => _ListaCancionesVistaState();
}

class _ListaCancionesVistaState extends State<ListaCancionesVista> {
  final ServicioAlmacenamiento almacenamiento = ServicioAlmacenamiento();
  final FirestoreService _firestore = FirestoreService();
  final AuthService _authService = AuthService();
  late Future<List<Cancion>> _cancionesFuturo;
  Stream<List<Map<String, dynamic>>>? _cancionesFirestoreStream;
  Stream<List<Map<String, dynamic>>>? _compartidasFirestoreStream;
  final TextEditingController _controladorBusqueda = TextEditingController();
  String _busqueda = '';
  bool _isLoggedIn = false;
  String? _usuarioNombre;
  // 0 = Mis canciones, 1 = Compartidas
  int _selectedSongView = 0;

  // Notificaciones de solicitudes entrantes
  int _pendingRequests = 0;
  StreamSubscription<List<Map<String, dynamic>>>? _solicitudesSub;
  // Flag para evitar usar el controlador tras el dispose (protección adicional)
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _cargarCanciones();
    // Escuchar cambios de autenticación para alternar entre local y Firestore
    FirebaseAuth.instance.authStateChanges().listen((u) {
      if (!mounted) return;
      setState(() {
        _isLoggedIn = u != null;
        _usuarioNombre = u?.displayName ?? (u?.email?.split('@').first ?? null);
        if (_isLoggedIn) {
          _cancionesFirestoreStream = _firestore.obtenerCancionesModelStream(
            u!.uid,
          );
          _compartidasFirestoreStream = _firestore.obtenerCancionesRecibidasStream(u.uid);

          // Escuchar solicitudes entrantes para mostrar notificación/badge
          _solicitudesSub?.cancel();
          _solicitudesSub = _firestore
              .obtenerSolicitudesEntrantesStream(u.uid)
              .listen((lista) {
                if (!mounted) return;
                setState(() {
                  _pendingRequests = lista.length;
                });
              }, onError: (e) {
                // Si las reglas deniegan la consulta, evitamos crash y dejamos 0 solicitudes pendientes.
                if (!mounted) return;
                setState(() {
                  _pendingRequests = 0;
                });
                // Opcional: log para diagnóstico
                // ignore: avoid_print
                print('Error listening solicitudes entrantes: $e');
              });
        } else {
          _cancionesFirestoreStream = null;
          _compartidasFirestoreStream = null;
          _cargarCanciones();
          _solicitudesSub?.cancel();
          _pendingRequests = 0;
        }
      });
    });
  }

  void _cargarCanciones() {
    _cancionesFuturo = almacenamiento.cargarCanciones();
  }

  Future<void> _refrescar() async {
    if (!mounted) return;
    setState(() {
      _cargarCanciones();
    });
  }

  // Safely show a SnackBar if the widget is still mounted and context is valid.
  void _safeShowSnackBar(String message) {
    if (!mounted) return;
    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      // ignore: avoid_print
      print('No se pudo mostrar SnackBar: $e');
    }
  }

  void _irAgregarCancion() async {
    if (_isLoggedIn) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final resultado = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (c) => EditarCancionVista(
            almacenamiento: almacenamiento,
            onSave: (cancion) async {
              // Crear en Firestore para este usuario
              await _firestore.crearCancion(
                uid: user.uid,
                cancion: cancion.toFirestoreMap(),
              );
            },
          ),
        ),
      );
      if (!mounted) return;
      if (resultado == true) {
        // Stream de Firestore se actualizará automáticamente
      }
    } else {
      final resultado = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (c) => EditarCancionVista(almacenamiento: almacenamiento),
        ),
      );
      if (!mounted) return;
      if (resultado == true) _refrescar();
    }
  }

  void _irVerCancion(Cancion cancion, {bool fromFirestore = false}) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (c) => DetalleCancionVista(
          cancion: cancion,
          almacenamiento: almacenamiento,
          onDelete: fromFirestore
              ? (id) async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null)
                    await _firestore.eliminarCancion(uid: user.uid, id: id);
                }
              : null,
          onCreateOrUpdate: fromFirestore
              ? (edited) async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await _firestore.actualizarCancion(
                      uid: user.uid,
                      id: edited.id,
                      cancion: edited.toFirestoreMap(),
                    );
                  }
                }
              : null,
        ),
      ),
    );
    if (!mounted) return;
    if (resultado == true) {
      if (!fromFirestore) _refrescar();
      // Si viene de Firestore, el stream actualiza la lista automáticamente
    }
  }

  Future<void> _abrirListaAmigos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Usar un widget separado que gestione su propio TextEditingController y ciclo de vida
    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (c) => SafeArea(
        child: AmigosModal(
          firestore: _firestore,
          userUid: user.uid,
        ),
      ),
    );
  }

  Future<void> _buscarYAgregarAmigoDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final controller = TextEditingController();
    try {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Buscar usuario por nombre'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Nombre de perfil',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final q = controller.text.trim();
                if (q.isEmpty) return;
                final results = await _firestore.buscarUsuariosPorNombre(q);
                if (!mounted) return;
                Navigator.of(c).pop();

                await showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Resultados'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: results.isEmpty
                          ? const Text('No se encontraron usuarios')
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: results.length,
                              itemBuilder: (context, i) {
                                final r = results[i];
                                final uid = r['uid'] as String? ?? '';
                                final nombre = (r['nombre'] ?? '') as String;
                                final email = (r['usuario'] ?? '') as String;
                                return ListTile(
                                  title: Text(
                                    nombre.isNotEmpty
                                        ? nombre
                                        : (email.isNotEmpty ? email : uid),
                                  ),
                                  subtitle: email.isNotEmpty
                                      ? Text(email)
                                      : null,
                                  trailing: uid == user.uid
                                      ? const Text('Tu perfil')
                                      : TextButton(
                                          child: const Text('Solicitar'),
                                          onPressed: () async {
                                            try {
                                              final me = FirebaseAuth
                                                  .instance
                                                  .currentUser;
                                              final fromNombre =
                                                  me?.displayName ??
                                                  (me?.email
                                                          ?.split('@')
                                                          .first ??
                                                      '');
                                              await _firestore
                                                  .enviarSolicitudAmistad(
                                                    fromUid: user.uid,
                                                    fromNombre: fromNombre,
                                                    toUid: uid,
                                                  );
                                              if (!mounted) return;
                                              Navigator.of(context).pop();
                                              if (mounted) {
                                                final messenger =
                                                    ScaffoldMessenger.maybeOf(
                                                      this.context,
                                                    );
                                                messenger?.showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Solicitud enviada',
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (!mounted) return;
                                              final messenger =
                                                  ScaffoldMessenger.maybeOf(
                                                    this.context,
                                                  );
                                              messenger?.showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: $e'),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                );
                              },
                            ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Buscar'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _seleccionarAmigoYCompartir(Cancion cancion) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Compartir con...'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestore.obtenerAmigosStream(user.uid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              final amigos = snap.data ?? [];
              if (amigos.isEmpty)
                return const Text(
                  'No tienes amigos para compartir. Agrégalos primero.',
                );
              return ListView.builder(
                shrinkWrap: true,
                itemCount: amigos.length,
                itemBuilder: (context, i) {
                  final a = amigos[i];
                  final email = (a['usuario'] ?? '') as String;
                  return ListTile(
                    title: Text(
                      a['nombre'] ?? (email.isNotEmpty ? email : a['uid']),
                    ),
                    subtitle: email.isNotEmpty ? Text(email) : null,
                    onTap: () async {
                      try {
                        await _firestore.compartirCancion(
                          fromUid: user.uid,
                          toUid: a['uid'] as String,
                          cancion: cancion.toFirestoreMap(),
                        );
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        if (mounted) {
                          final messenger = ScaffoldMessenger.maybeOf(
                            this.context,
                          );
                          messenger?.showSnackBar(
                            const SnackBar(content: Text('Canción compartida')),
                          );
                        }
                      } catch (e) {
                        if (!mounted) return;
                        final messenger = ScaffoldMessenger.maybeOf(
                          this.context,
                        );
                        messenger?.showSnackBar(
                          SnackBar(content: Text('Error compartiendo: $e')),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Cancelar suscripciones activas para evitar callbacks después del dispose
    _solicitudesSub?.cancel();

    // Marcar disposed y dispose del controlador de búsqueda
    _disposed = true;
    _controladorBusqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: _isLoggedIn
            ? Text(
                _usuarioNombre ?? 'Mi perfil',
                style: Theme.of(context).textTheme.titleMedium,
              )
            : const Text('Mis canciones'),
        actions: [
          if (_isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.group),
                    tooltip: 'Amigos',
                    onPressed: _abrirListaAmigos,
                  ),
                  if (_pendingRequests > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            _pendingRequests > 9 ? '9+' : '$_pendingRequests',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (_isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () async {
                await _authService.signOut();
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginVista()),
                );
              },
            ),

        ],
      ),
      body: _isLoggedIn
          ? StreamBuilder<List<Map<String, dynamic>>>(
              stream: _cancionesFirestoreStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data ?? [];
                final todasCanciones = docs.map((m) {
                  final id = (m['id'] is String)
                      ? (m['id'] as String)
                      : (m['id']?.toString() ?? '');
                  return Cancion.desdeFirestore(m, id);
                }).toList();
                final cancionesFiltradas = _busqueda.isEmpty
                    ? todasCanciones
                    : todasCanciones
                          .where(
                            (s) => s.titulo.toLowerCase().contains(
                              _busqueda.toLowerCase(),
                            ),
                          )
                          .toList();

                // Las canciones compartidas se muestran únicamente en la vista "Compartidas" (no mostramos preview arriba).

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    // Ya no mostramos preview de compartidas aquí
                    const SizedBox.shrink(),
                    SafeArea(
                      child: Column(
                        children: [
                          Center(
                            child: Image.asset(
                              'assets/logo.png',
                              width: 220,
                              height: 220,
                              semanticLabel: 'Logo Cancionero',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 6.0,
                              bottom: 6.0,
                            ),
                            child: Text(
                              'Mis canciones',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),

                          // Selector central para ver 'Mis canciones' o 'Compartidas'
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ChoiceChip(
                                  label: const Text('Mis canciones'),
                                  selected: _selectedSongView == 0,
                                  onSelected: (s) => setState(() => _selectedSongView = 0),
                                  selectedColor: Colors.white,
                                  labelStyle: TextStyle(
                                      color: _selectedSongView == 0 ? Colors.black : Colors.white),
                                  backgroundColor: Colors.transparent,
                                ),
                                const SizedBox(width: 10),
                                ChoiceChip(
                                  label: const Text('Compartidas'),
                                  selected: _selectedSongView == 1,
                                  onSelected: (s) => setState(() => _selectedSongView = 1),
                                  selectedColor: Colors.white,
                                  labelStyle: TextStyle(
                                      color: _selectedSongView == 1 ? Colors.black : Colors.white),
                                  backgroundColor: Colors.transparent,
                                ),
                              ],
                            ),
                          ),

                          // Buscador
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 6.0,
                            ),
                            child: TextField(
                              controller: _controladorBusqueda,
                              onChanged: (v) =>
                                  setState(() => _busqueda = v.trim()),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.white70,
                                ),
                                hintText: 'Buscar canción por título',
                                hintStyle: TextStyle(
                                  color: Colors.white.withAlpha(204),
                                ),
                                filled: true,
                                fillColor: kDarkBlue.withAlpha(40),
                                suffixIcon: _busqueda.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _busqueda = '';
                                            _controladorBusqueda.clear();
                                          });
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _selectedSongView == 1
                          ? StreamBuilder<List<Map<String, dynamic>>>(
                              stream: _compartidasFirestoreStream,
                              builder: (context, snap) {
                                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                                final compartidas = snap.data ?? [];
                                if (compartidas.isEmpty) {
                                  return Center(
                                    child: Text(
                                      'No hay canciones compartidas para ti.',
                                      style: Theme.of(context).textTheme.bodyLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }
                                return ListView.separated(
                                  itemCount: compartidas.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, i) {
                                    final doc = compartidas[i];
                                    final cancionMap = (doc['cancion'] ?? {}) as Map<String, dynamic>;
                                    final cancion = Cancion.desdeFirestore(cancionMap, 'shared_${doc['id'] ?? i}');
                                    final fromNombre = (doc['fromNombre'] ?? doc['fromUid'])?.toString() ?? '';
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                      child: Card(
                                        color: kLightBlue.withAlpha(36),
                                        clipBehavior: Clip.antiAlias,
                                        child: ListTile(
                                          title: Text(cancion.titulo),
                                          subtitle: fromNombre.isNotEmpty ? Text('Compartida por $fromNombre') : null,
                                          onTap: () async {
                                            final user = FirebaseAuth.instance.currentUser;
                                            if (user == null) return;
                                            await Navigator.of(context).push<bool>(
                                              MaterialPageRoute(
                                                builder: (c) => DetalleCancionVista(
                                                  cancion: cancion,
                                                  almacenamiento: almacenamiento,
                                                  onDelete: (id) async {
                                                    await _firestore.eliminarCancionCompartida(uid: user.uid, sharedId: doc['id'] ?? '');
                                                  },
                                                  onCreateOrUpdate: (edited) async {
                                                    await _firestore.actualizarCancionCompartida(uid: user.uid, sharedId: doc['id'] ?? '', cancion: edited.toFirestoreMap());
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                          trailing: PopupMenuButton<String>(
                                            onSelected: (v) async {
                                              final user = FirebaseAuth.instance.currentUser;
                                              if (user == null) return;
                                              final uid = user.uid;
                                              if (v == 'edit') {
                                                final updated = await Navigator.of(context).push<bool>(
                                                  MaterialPageRoute(
                                                    builder: (c) => EditarCancionVista(
                                                      almacenamiento: almacenamiento,
                                                      cancion: cancion,
                                                      onUpdate: (cUpdated) async {
                                                        await _firestore.actualizarCancionCompartida(
                                                          uid: uid,
                                                          sharedId: doc['id'] ?? '',
                                                          cancion: cUpdated.toFirestoreMap(),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                );
                                                if (!mounted) return;
                                                if (updated == true) {
                                                  _safeShowSnackBar('Canción compartida actualizada');
                                                }
                                              } else if (v == 'move') {
                                                _safeShowSnackBar('Moviendo canción a tus canciones...');
                                                try {
                                                  await _firestore.moverCancionCompartidaAPropias(uid: uid, sharedId: doc['id'] ?? '');
                                                  if (!mounted) return;
                                                  _safeShowSnackBar('Canción movida a Mis canciones');
                                                } catch (e) {
                                                  if (!mounted) return;
                                                  _safeShowSnackBar('Error al mover canción: $e');
                                                }
                                              } else if (v == 'delete') {
                                                final confirmar = await showDialog<bool>(
                                                  context: context,
                                                  builder: (c) => AlertDialog(
                                                    title: const Text('Eliminar canción compartida'),
                                                    content: const Text('¿Seguro que quieres eliminar esta canción compartida?'),
                                                    actions: [
                                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
                                                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Eliminar')),
                                                    ],
                                                  ),
                                                );
                                                if (confirmar == true) {
                                                  try {
                                                    await _firestore.eliminarCancionCompartida(uid: uid, sharedId: doc['id'] ?? '');
                                                    if (!mounted) return;
                                                    _safeShowSnackBar('Canción compartida eliminada');
                                                  } catch (e) {
                                                    if (!mounted) return;
                                                    _safeShowSnackBar('Error al eliminar: $e');
                                                  }
                                                }
                                              }
                                            },
                                            itemBuilder: (c) => [
                                              const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                              const PopupMenuItem(value: 'move', child: Text('Mover a Mis canciones')),
                                              const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            )
                          : (todasCanciones.isEmpty
                              ? Center(
                                  child: Text(
                                    'No hay canciones. Usa el botón + para agregar una.',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : cancionesFiltradas.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No se encontraron canciones que coincidan con tu búsqueda.',
                                        style: Theme.of(context).textTheme.bodyLarge,
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: cancionesFiltradas.length,
                                      itemBuilder: (context, index) {
                                        final cancion = cancionesFiltradas[index];
                                        final cardBg = kLightBlue.withAlpha(36);
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0,
                                            vertical: 6.0,
                                          ),
                                          child: Card(
                                            color: cardBg,
                                            clipBehavior: Clip.antiAlias,
                                            child: ListTile(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              title: Text(
                                                cancion.titulo,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                              ),
                                              onTap: () => _irVerCancion(
                                                cancion,
                                                fromFirestore: _isLoggedIn,
                                              ),
                                              trailing: _isLoggedIn
                                                  ? PopupMenuButton<String>(
                                                      onSelected: (v) async {
                                                        if (v == 'share') {
                                                          await _seleccionarAmigoYCompartir(
                                                            cancion,
                                                          );
                                                        }
                                                      },
                                                      itemBuilder: (c) => [
                                                        const PopupMenuItem(
                                                          value: 'share',
                                                          child: Text('Compartir...'),
                                                        ),
                                                      ],
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                    )),
                    ),
                  ],
                );
              },
            )
          : FutureBuilder<List<Cancion>>(
              future: _cancionesFuturo,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final todasCanciones = snapshot.data ?? [];
                final cancionesFiltradas = _busqueda.isEmpty
                    ? todasCanciones
                    : todasCanciones
                          .where(
                            (s) => s.titulo.toLowerCase().contains(
                              _busqueda.toLowerCase(),
                            ),
                          )
                          .toList();
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    SafeArea(
                      child: Column(
                        children: [
                          Center(
                            child: Image.asset(
                              'assets/logo.png',
                              width: 220,
                              height: 220,
                              semanticLabel: 'Logo Cancionero',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 6.0,
                              bottom: 6.0,
                            ),
                            child: Text(
                              'Mis canciones',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          // Buscador
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 6.0,
                            ),
                            child: TextField(
                              controller: _controladorBusqueda,
                              onChanged: (v) =>
                                  setState(() => _busqueda = v.trim()),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.white70,
                                ),
                                hintText: 'Buscar canción por título',
                                hintStyle: TextStyle(
                                  color: Colors.white.withAlpha(204),
                                ),
                                filled: true,
                                fillColor: kDarkBlue.withAlpha(40),
                                suffixIcon: _busqueda.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _busqueda = '';
                                            _controladorBusqueda.clear();
                                          });
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: todasCanciones.isEmpty
                          ? Center(
                              child: Text(
                                'No hay canciones. Usa el botón + para agregar una.',
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            )
                          : cancionesFiltradas.isEmpty
                          ? Center(
                              child: Text(
                                'No se encontraron canciones que coincidan con tu búsqueda.',
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              itemCount: cancionesFiltradas.length,
                              itemBuilder: (context, index) {
                                final cancion = cancionesFiltradas[index];
                                final cardBg = kLightBlue.withAlpha(36);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 6.0,
                                  ),
                                  child: Card(
                                    color: cardBg,
                                    clipBehavior: Clip.antiAlias,
                                    child: ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      title: Text(
                                        cancion.titulo,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      onTap: () => _irVerCancion(cancion),
                                      trailing: _isLoggedIn
                                          ? PopupMenuButton<String>(
                                              onSelected: (v) async {
                                                if (v == 'share') {
                                                  await _seleccionarAmigoYCompartir(
                                                    cancion,
                                                  );
                                                }
                                              },
                                              itemBuilder: (c) => [
                                                const PopupMenuItem(
                                                  value: 'share',
                                                  child: Text('Compartir...'),
                                                ),
                                              ],
                                            )
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
      // Mostrar el FAB solo en la vista "Mis canciones" (0). En "Compartidas" no se puede agregar.
      floatingActionButton: _selectedSongView == 0
          ? FloatingActionButton(
              onPressed: _irAgregarCancion,
              tooltip: 'Agregar canción',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class AmigosModal extends StatefulWidget {
  final FirestoreService firestore;
  final String userUid;
  const AmigosModal({Key? key, required this.firestore, required this.userUid}) : super(key: key);

  @override
  State<AmigosModal> createState() => _AmigosModalState();
}

class _AmigosModalState extends State<AmigosModal> {
  late final TextEditingController _searchCtrl;
  List<Map<String, dynamic>> _searchResults = [];
  bool _searchLoading = false;
  final Set<String> _currentFriends = {};
  final Set<String> _sentRequests = {};
  StreamSubscription<List<String>>? _outgoingSub;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    // Prefetch current friends once
    widget.firestore.obtenerAmigosStream(widget.userUid).first.then((lista) {
      if (!mounted) return;
      setState(() {
        for (final a in lista) {
          final uid = a['uid'] as String? ?? '';
          if (uid.isNotEmpty) _currentFriends.add(uid);
        }
      });
    }).catchError((_) {});

    // Suscribirse a solicitudes salientes para saber a quiénes ya les enviamos solicitud
    _outgoingSub = widget.firestore
        .obtenerSolicitudesSalientesUidsStream(widget.userUid)
        .listen((lista) {
      if (!mounted) return;
      setState(() {
        _sentRequests.clear();
        _sentRequests.addAll(lista.where((s) => s.isNotEmpty));
      });
    }, onError: (e) {
      // Si la consulta grupal (collectionGroup) es denegada por reglas, evitamos crash y limpiamos la lista.
      if (!mounted) return;
      setState(() {
        _sentRequests.clear();
      });
      // ignore: avoid_print
      print('Error listening solicitudes salientes: $e');
    });
  }

  Future<void> _runSearch(String q) async {
    if (q.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _searchLoading = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _searchLoading = true;
    });
    try {
      final results = await widget.firestore.buscarUsuariosPorNombre(q);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _searchLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _outgoingSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    try {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.25,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Buscar por nombre de perfil',
                          prefixIcon: Icon(Icons.person_search),
                        ),
                        onChanged: (v) => _runSearch(v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        try {
                          _searchCtrl.clear();
                        } catch (_) {}
                        setState(() {
                          _searchResults = [];
                          _searchLoading = false;
                        });
                      },
                    ),
                  ],
                ),
              ),

              if (_searchLoading)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_searchResults.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = _searchResults[i];
                    final uid = r['uid'] as String? ?? '';
                    final nombre = (r['nombre'] ?? '') as String;
                    final email = (r['usuario'] ?? '') as String;
                    final isMe = uid == widget.userUid;
                    final alreadyFriend = _currentFriends.contains(uid);
                    final sent = _sentRequests.contains(uid);
                    return ListTile(
                      title: Text(
                        nombre.isNotEmpty
                            ? nombre
                            : (email.isNotEmpty ? email : uid),
                      ),
                      subtitle: email.isNotEmpty ? Text(email) : null,
                      trailing: isMe
                          ? const Text('Tu perfil')
                          : alreadyFriend
                              ? const Text('Agregado')
                              : sent
                                  ? const Text('Solicitud enviada')
                                  : TextButton(
                                      child: const Text('Agregar'),
                                      onPressed: () async {
                                        if (_sentRequests.contains(uid)) {
                                          _showSnackBar('Ya has enviado una solicitud a este usuario');
                                          return;
                                        }
                                        try {
                                          final me = FirebaseAuth.instance.currentUser;
                                          final fromNombre = me?.displayName ?? (me?.email?.split('@').first ?? '');
                                          await widget.firestore.enviarSolicitudAmistad(
                                            fromUid: widget.userUid,
                                            fromNombre: fromNombre,
                                            toUid: uid,
                                          );
                                          if (!mounted) return;
                                          setState(() {
                                            _sentRequests.add(uid);
                                          });
                                          _showSnackBar('Solicitud enviada');
                                        } catch (e) {
                                          if (!mounted) return;
                                          _showSnackBar('Error: $e');
                                        }
                                      },
                                    ),
                    );
                  },
                )
              else
                const SizedBox.shrink(),

              const Divider(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                child: Text(
                  'Solicitudes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: widget.firestore.obtenerSolicitudesEntrantesStream(widget.userUid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final solicitudes = snap.data ?? [];
                  if (solicitudes.isEmpty) return const Padding(padding: EdgeInsets.all(12.0), child: Text('No tienes solicitudes.'));
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: solicitudes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final s = solicitudes[idx];
                      final fromUid = s['uid'] as String? ?? '';
                      final fromNombre = (s['fromNombre'] ?? '') as String;
                      return ListTile(
                        title: Text(fromNombre.isNotEmpty ? fromNombre : fromUid),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close),
                              color: Colors.red,
                              tooltip: 'Rechazar',
                              onPressed: () async {
                                try {
                                  await widget.firestore.rechazarSolicitud(uid: widget.userUid, fromUid: fromUid);
                                  if (!mounted) return;
                                  _showSnackBar('Solicitud rechazada');
                                } catch (e) {
                                  if (!mounted) return;
                                  _showSnackBar('Error: $e');
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.check),
                              color: Colors.green,
                              tooltip: 'Aceptar',
                              onPressed: () async {
                                try {
                                  await widget.firestore.aceptarSolicitud(uid: widget.userUid, fromUid: fromUid);
                                  if (!mounted) return;
                                  setState(() {
                                    _currentFriends.add(fromUid);
                                  });
                                  _showSnackBar('Solicitud aceptada');
                                } catch (e) {
                                  if (!mounted) return;
                                  _showSnackBar('Error: $e');
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              const Divider(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                child: Text(
                  'Tus amigos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: widget.firestore.obtenerAmigosStream(widget.userUid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final amigos = snap.data ?? [];
                  if (amigos.isEmpty) return const Padding(padding: EdgeInsets.all(12.0), child: Text('No tienes amigos. Agrégalos usando la búsqueda de arriba.'));
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: amigos.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final a = amigos[idx];
                      final email = (a['usuario'] ?? '') as String;
                      return ListTile(
                        title: Text(a['nombre'] ?? (email.isNotEmpty ? email : a['uid'])),
                        subtitle: email.isNotEmpty ? Text(email) : null,
                        onTap: () {},
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

