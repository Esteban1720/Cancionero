import 'package:cancionero/componentes/chat_end_drawer.dart';
import 'package:cancionero/componentes/imagenes_seguras.dart';
import 'package:cancionero/componentes/menu_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Dasboard extends StatefulWidget {
  const Dasboard({super.key});

  @override
  State<Dasboard> createState() => _DasboardState();
}

class _DasboardState extends State<Dasboard> {
  int opcionSeleccionada = 0;
  bool mostrarAmigos = false;
  bool buscando = false;
  final TextEditingController buscarController = TextEditingController();
  List<QueryDocumentSnapshot> resultadosBusqueda = [];
  final Map<String, String> estadosRelacionCache = {};
  final Set<String> solicitudesEnProceso = {};

  @override
  void dispose() {
    buscarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No hay sesion iniciada')),
      );
    }

    return Scaffold(
      drawer: const MenuDrawer(),
      endDrawer: ChatEndDrawer(currentUid: user.uid),
      appBar: AppBar(
        title: const Text('Cancionero'),
        backgroundColor: Colors.transparent,
        actions: [
          Builder(
            builder: (context) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(user.uid)
                    .collection('amigos')
                    .snapshots(),
                builder: (context, snapshot) {
                  final totalNoLeidos = (snapshot.data?.docs ?? []).fold<int>(
                    0,
                    (total, doc) {
                      final amigo = doc.data() as Map<String, dynamic>;
                      return total +
                          ((amigo['mensajes_no_leidos'] ?? 0) as num).toInt();
                    },
                  );

                  return IconButton(
                    onPressed: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.chat),
                        if (totalNoLeidos > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 220, 53, 69),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                totalNoLeidos > 99 ? '99+' : '$totalNoLeidos',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get(),
        builder: (context, snapshot) {
          final datos = snapshot.data?.data() as Map<String, dynamic>?;
          final nombre = datos?['user'] ?? 'Mi perfil';
          final foto = datos?['foto'] ?? '';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            opcionSeleccionada = 0;
                          });
                        },
                        child: const Text('Publicaciones'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            opcionSeleccionada = 1;
                          });
                        },
                        child: const Text('Amigos'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed('/perfil');
                      },
                      child: AvatarSeguro(imageUrl: foto, radius: 26),
                    ),
                  ],
                ),
              ),
              Expanded(child: construirContenido(user.uid, nombre)),
            ],
          );
        },
      ),
    );
  }

  Widget construirContenido(String uid, String nombre) {
    if (opcionSeleccionada == 1) {
      return vistaAmigos(uid);
    }

    return vistaPublicaciones(uid, nombre);
  }

  Widget vistaPublicaciones(String uid, String nombre) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection('amigos')
          .snapshots(),
      builder: (context, amigosSnapshot) {
        final amigosIds =
            amigosSnapshot.data?.docs.map((doc) => doc.id).toList() ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('publicaciones')
              .orderBy('fecha_publicacion', descending: true)
              .snapshots(),
          builder: (context, publicacionesSnapshot) {
            if (!publicacionesSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final publicaciones = publicacionesSnapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final autorUid = data['uid'];
              return autorUid == uid || amigosIds.contains(autorUid);
            }).toList();

            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  color: const Color.fromARGB(255, 226, 241, 255),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Bienvenido $nombre. Aqui miras las fotos y videos que publican tus amigos.',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (amigosIds.isEmpty && publicaciones.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No hay publicacion'),
                    ),
                  ),
                if (amigosIds.isNotEmpty && publicaciones.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No hay publicacion'),
                    ),
                  ),
                ...publicaciones.map((doc) {
                  final publicacion = doc.data() as Map<String, dynamic>;
                  return tarjetaPublicacion(doc.id, publicacion, uid);
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget tarjetaPublicacion(
    String publicacionId,
    Map<String, dynamic> publicacion,
    String currentUid,
  ) {
    final tipo = publicacion['tipo'] ?? 'Foto';
    final archivoUrl = publicacion['archivo_url'] ?? '';
    final fotoUsuario = publicacion['foto_usuario'] ?? '';

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: AvatarSeguro(imageUrl: fotoUsuario),
            title: Text(publicacion['nombre'] ?? 'Usuario'),
            subtitle: Text(publicacion['descripcion'] ?? ''),
            trailing: Icon(tipo == 'Video' ? Icons.videocam : Icons.image),
          ),
          if (archivoUrl.isNotEmpty && tipo == 'Foto')
            Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: () {
                  abrirImagenGrande(archivoUrl);
                },
                child: ImagenSegura(
                  imageUrl: archivoUrl,
                  height: 220,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          if (archivoUrl.isNotEmpty && tipo == 'Video')
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.play_circle, size: 60),
                    const SizedBox(height: 8),
                    Text(archivoUrl),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('publicaciones')
                        .doc(publicacionId)
                        .collection('likes')
                        .doc(currentUid)
                        .snapshots(),
                    builder: (context, likeSnapshot) {
                      final yaDioLike = likeSnapshot.data?.exists ?? false;

                      return TextButton.icon(
                        onPressed: () {
                          toggleLike(publicacionId, currentUid);
                        },
                        icon: Icon(
                          yaDioLike ? Icons.favorite : Icons.favorite_border,
                          color: yaDioLike ? Colors.red : null,
                        ),
                        label: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('publicaciones')
                              .doc(publicacionId)
                              .collection('likes')
                              .snapshots(),
                          builder: (context, likesSnapshot) {
                            final totalLikes =
                                likesSnapshot.data?.docs.length ?? 0;
                            return Text('Likes $totalLikes');
                          },
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      abrirComentarios(publicacionId, currentUid);
                    },
                    icon: const Icon(Icons.comment_outlined),
                    label: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('publicaciones')
                          .doc(publicacionId)
                          .collection('comentarios')
                          .snapshots(),
                      builder: (context, comentariosSnapshot) {
                        final totalComentarios =
                            comentariosSnapshot.data?.docs.length ?? 0;
                        return Text('Comentarios $totalComentarios');
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget vistaAmigos(String uid) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: buscarController,
                decoration: const InputDecoration(
                  hintText: 'Buscar amigo',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: buscando ? null : () => buscarUsuarios(uid),
              child: buscando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Buscar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (resultadosBusqueda.isNotEmpty) ...[
          const Text(
            'Resultados de busqueda',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...resultadosBusqueda.map((doc) {
            final usuario = doc.data() as Map<String, dynamic>;
            final foto = usuario['foto'] ?? '';

            return Card(
              child: ListTile(
                leading: AvatarSeguro(imageUrl: foto),
                title: Text(usuario['user'] ?? 'Usuario'),
                subtitle: estadoRelacionWidget(
                  uid,
                  doc.id,
                  usuario['email'] ?? '',
                ),
                trailing: estadoBotonRelacion(uid, doc.id, usuario),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
        const Text(
          'Solicitudes enviadas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .collection('solicitudes_enviadas')
              .orderBy('fecha', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No tienes solicitudes enviadas'),
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final solicitud = doc.data() as Map<String, dynamic>;
                final foto = solicitud['foto'] ?? '';

                return Card(
                  child: ListTile(
                    leading: AvatarSeguro(imageUrl: foto),
                    title: Text(solicitud['nombre'] ?? 'Usuario'),
                    subtitle: const Text('Solicitud enviada'),
                    trailing: TextButton(
                      onPressed: () {
                        cancelarSolicitudEnviada(uid, doc.id);
                      },
                      child: const Text('Cancelar'),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    mostrarAmigos = !mostrarAmigos;
                  });
                },
                child: Text(mostrarAmigos ? 'Ocultar amigos' : 'Tus amigos'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (mostrarAmigos) ...[
          const Text(
            'Lista de amigos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(uid)
                .collection('amigos')
                .orderBy('nombre')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Todavia no tienes amigos agregados'),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final amigo = doc.data() as Map<String, dynamic>;
                  final foto = amigo['foto'] ?? '';
                  return Card(
                    child: ListTile(
                      leading: AvatarSeguro(imageUrl: foto),
                      title: Text(amigo['nombre'] ?? 'Amigo'),
                      subtitle: const Text('Amigo agregado'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          eliminarAmigo(uid, doc.id);
                        },
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
        const Text(
          'Solicitudes de amistad',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .collection('solicitudes_recibidas')
              .orderBy('fecha', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No tienes solicitudes pendientes'),
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final solicitud = doc.data() as Map<String, dynamic>;
                final foto = solicitud['foto'] ?? '';

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: AvatarSeguro(imageUrl: foto),
                          title: Text(solicitud['nombre'] ?? 'Usuario'),
                          subtitle: Text(solicitud['email'] ?? ''),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  aceptarSolicitud(uid, doc.id, solicitud);
                                },
                                child: const Text('Aceptar'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade300,
                                ),
                                onPressed: () {
                                  eliminarSolicitud(uid, doc.id);
                                },
                                child: const Text('Eliminar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget estadoRelacionWidget(
    String currentUid,
    String otherUid,
    String email,
  ) {
    final estadoCache = estadosRelacionCache[otherUid];
    if (estadoCache != null) {
      if (estadoCache == 'amigo') {
        return const Text('Ya es tu amigo');
      }
      if (estadoCache == 'enviada') {
        return const Text('Solicitud pendiente');
      }
      if (estadoCache == 'recibida') {
        return const Text('Te envio una solicitud');
      }
      return Text(email);
    }

    return FutureBuilder<String>(
      future: obtenerEstadoRelacion(currentUid, otherUid),
      builder: (context, snapshot) {
        final estado = snapshot.data ?? 'cargando';

        if (snapshot.hasData && estadosRelacionCache[otherUid] != estado) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            setState(() {
              estadosRelacionCache[otherUid] = estado;
            });
          });
        }

        if (estado == 'amigo') {
          return const Text('Ya es tu amigo');
        }
        if (estado == 'enviada') {
          return const Text('Solicitud pendiente');
        }
        if (estado == 'recibida') {
          return const Text('Te envio una solicitud');
        }

        return Text(email);
      },
    );
  }

  Widget estadoBotonRelacion(
    String currentUid,
    String otherUid,
    Map<String, dynamic> usuario,
  ) {
    if (solicitudesEnProceso.contains(otherUid)) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final estadoCache = estadosRelacionCache[otherUid];
    if (estadoCache != null) {
      if (estadoCache == 'amigo') {
        return const Text('Amigo');
      }

      if (estadoCache == 'enviada') {
        return const Text('Pendiente');
      }

      if (estadoCache == 'recibida') {
        return TextButton(
          onPressed: () {
            aceptarSolicitud(currentUid, otherUid, {
              'nombre': usuario['user'] ?? 'Usuario',
              'email': usuario['email'] ?? '',
              'foto': usuario['foto'] ?? '',
            });
          },
          child: const Text('Aceptar'),
        );
      }
    }

    return FutureBuilder<String>(
      future: obtenerEstadoRelacion(currentUid, otherUid),
      builder: (context, snapshot) {
        final estado = snapshot.data ?? 'cargando';

        if (snapshot.hasData && estadosRelacionCache[otherUid] != estado) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            setState(() {
              estadosRelacionCache[otherUid] = estado;
            });
          });
        }

        if (estado == 'cargando') {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (estado == 'amigo') {
          return const Text('Amigo');
        }

        if (estado == 'enviada') {
          return const Text('Pendiente');
        }

        if (estado == 'recibida') {
          return TextButton(
            onPressed: () {
              aceptarSolicitud(currentUid, otherUid, {
                'nombre': usuario['user'] ?? 'Usuario',
                'email': usuario['email'] ?? '',
                'foto': usuario['foto'] ?? '',
              });
            },
            child: const Text('Aceptar'),
          );
        }

        return ElevatedButton(
          onPressed: () {
            enviarSolicitud(otherUid, usuario);
          },
          child: const Text('Agregar'),
        );
      },
    );
  }

  Future<void> buscarUsuarios(String currentUid) async {
    final texto = buscarController.text.trim().toLowerCase();

    if (texto.isEmpty) {
      setState(() {
        resultadosBusqueda = [];
      });
      return;
    }

    setState(() {
      buscando = true;
    });

    final query = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('user_lower', isGreaterThanOrEqualTo: texto)
        .where('user_lower', isLessThanOrEqualTo: '$texto\uf8ff')
        .get();

    final resultados = query.docs.where((doc) => doc.id != currentUid).toList();

    final amigosSnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(currentUid)
        .collection('amigos')
        .get();
    final enviadasSnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(currentUid)
        .collection('solicitudes_enviadas')
        .get();
    final recibidasSnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(currentUid)
        .collection('solicitudes_recibidas')
        .get();

    final amigosIds = amigosSnapshot.docs.map((doc) => doc.id).toSet();
    final enviadasIds = enviadasSnapshot.docs.map((doc) => doc.id).toSet();
    final recibidasIds = recibidasSnapshot.docs.map((doc) => doc.id).toSet();

    setState(() {
      resultadosBusqueda = resultados;
      for (final doc in resultados) {
        if (amigosIds.contains(doc.id)) {
          estadosRelacionCache[doc.id] = 'amigo';
        } else if (enviadasIds.contains(doc.id)) {
          estadosRelacionCache[doc.id] = 'enviada';
        } else if (recibidasIds.contains(doc.id)) {
          estadosRelacionCache[doc.id] = 'recibida';
        } else {
          estadosRelacionCache[doc.id] = 'ninguna';
        }
      }
      buscando = false;
    });
  }

  Future<String> obtenerEstadoRelacion(
    String currentUid,
    String otherUid,
  ) async {
    final amigoDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(currentUid)
        .collection('amigos')
        .doc(otherUid)
        .get();

    if (amigoDoc.exists) {
      return 'amigo';
    }

    final enviadaDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(currentUid)
        .collection('solicitudes_enviadas')
        .doc(otherUid)
        .get();

    if (enviadaDoc.exists) {
      return 'enviada';
    }

    final recibidaDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(currentUid)
        .collection('solicitudes_recibidas')
        .doc(otherUid)
        .get();

    if (recibidaDoc.exists) {
      return 'recibida';
    }

    return 'ninguna';
  }

  Future<void> enviarSolicitud(
    String amigoUid,
    Map<String, dynamic> amigo,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final estadoActual = estadosRelacionCache[amigoUid];
    if (estadoActual != null && estadoActual != 'ninguna') {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya existe una relacion con este usuario'),
        ),
      );
      return;
    }

    setState(() {
      solicitudesEnProceso.add(amigoUid);
      estadosRelacionCache[amigoUid] = 'enviada';
    });

    final miDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();
    final misDatos = miDoc.data() ?? {};

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(amigoUid)
        .collection('solicitudes_recibidas')
        .doc(user.uid)
        .set({
          'uid': user.uid,
          'nombre': misDatos['user'] ?? 'Usuario',
          'email': misDatos['email'] ?? '',
          'foto': misDatos['foto'] ?? '',
          'fecha': FieldValue.serverTimestamp(),
        });

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('solicitudes_enviadas')
        .doc(amigoUid)
        .set({
          'uid': amigoUid,
          'nombre': amigo['user'] ?? 'Usuario',
          'email': amigo['email'] ?? '',
          'foto': amigo['foto'] ?? '',
          'fecha': FieldValue.serverTimestamp(),
        });

    if (!mounted) {
      return;
    }

    setState(() {
      solicitudesEnProceso.remove(amigoUid);
      estadosRelacionCache[amigoUid] = 'enviada';
    });
  }

  Future<void> toggleLike(String publicacionId, String currentUid) async {
    final likeRef = FirebaseFirestore.instance
        .collection('publicaciones')
        .doc(publicacionId)
        .collection('likes')
        .doc(currentUid);

    final likeDoc = await likeRef.get();

    if (likeDoc.exists) {
      await likeRef.delete();
    } else {
      await likeRef.set({
        'uid': currentUid,
        'fecha': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> abrirComentarios(String publicacionId, String currentUid) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _ComentariosSheet(
          publicacionId: publicacionId,
          currentUid: currentUid,
          onEnviar: agregarComentario,
        );
      },
    );
  }

  Future<void> agregarComentario(
    String publicacionId,
    String currentUid,
    String texto,
  ) async {
    if (texto.isEmpty) {
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(currentUid)
        .get();
    final misDatos = userDoc.data() ?? {};

    await FirebaseFirestore.instance
        .collection('publicaciones')
        .doc(publicacionId)
        .collection('comentarios')
        .add({
          'uid': currentUid,
          'nombre': misDatos['user'] ?? 'Usuario',
          'foto_usuario': misDatos['foto'] ?? '',
          'comentario': texto,
          'fecha': FieldValue.serverTimestamp(),
        });
  }

  Future<void> abrirImagenGrande(String imageUrl) async {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: AspectRatio(
            aspectRatio: 1,
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: ImagenSegura(
                imageUrl: imageUrl,
                width: double.infinity,
                fit: BoxFit.contain,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> aceptarSolicitud(
    String currentUid,
    String solicitudUid,
    Map<String, dynamic> solicitud,
  ) async {
    final miDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(currentUid)
        .get();
    final misDatos = miDoc.data() ?? {};

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(currentUid)
        .collection('amigos')
        .doc(solicitudUid)
        .set({
          'uid': solicitudUid,
          'nombre': solicitud['nombre'] ?? 'Amigo',
          'foto': solicitud['foto'] ?? '',
          'email': solicitud['email'] ?? '',
          'ultimo_mensaje': '',
          'mensajes_no_leidos': 0,
          'fecha': FieldValue.serverTimestamp(),
        });

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(solicitudUid)
        .collection('amigos')
        .doc(currentUid)
        .set({
          'uid': currentUid,
          'nombre': misDatos['user'] ?? 'Usuario',
          'foto': misDatos['foto'] ?? '',
          'email': misDatos['email'] ?? '',
          'ultimo_mensaje': '',
          'mensajes_no_leidos': 0,
          'fecha': FieldValue.serverTimestamp(),
        });

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(currentUid)
        .collection('solicitudes_recibidas')
        .doc(solicitudUid)
        .delete();

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(solicitudUid)
        .collection('solicitudes_enviadas')
        .doc(currentUid)
        .delete();

    setState(() {
      estadosRelacionCache[solicitudUid] = 'amigo';
      solicitudesEnProceso.remove(solicitudUid);
    });
  }

  Future<void> eliminarSolicitud(String currentUid, String solicitudUid) async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(currentUid)
        .collection('solicitudes_recibidas')
        .doc(solicitudUid)
        .delete();

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(solicitudUid)
        .collection('solicitudes_enviadas')
        .doc(currentUid)
        .delete();

    setState(() {
      estadosRelacionCache[solicitudUid] = 'ninguna';
      solicitudesEnProceso.remove(solicitudUid);
    });
  }

  Future<void> cancelarSolicitudEnviada(
    String currentUid,
    String amigoUid,
  ) async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(currentUid)
        .collection('solicitudes_enviadas')
        .doc(amigoUid)
        .delete();

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(amigoUid)
        .collection('solicitudes_recibidas')
        .doc(currentUid)
        .delete();

    setState(() {
      estadosRelacionCache[amigoUid] = 'ninguna';
      solicitudesEnProceso.remove(amigoUid);
    });
  }

  Future<void> eliminarAmigo(String currentUid, String amigoUid) async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(currentUid)
        .collection('amigos')
        .doc(amigoUid)
        .delete();

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(amigoUid)
        .collection('amigos')
        .doc(currentUid)
        .delete();

    setState(() {
      estadosRelacionCache[amigoUid] = 'ninguna';
      solicitudesEnProceso.remove(amigoUid);
    });
  }
}

class _ComentariosSheet extends StatefulWidget {
  const _ComentariosSheet({
    required this.publicacionId,
    required this.currentUid,
    required this.onEnviar,
  });

  final String publicacionId;
  final String currentUid;
  final Future<void> Function(String, String, String) onEnviar;

  @override
  State<_ComentariosSheet> createState() => _ComentariosSheetState();
}

class _ComentariosSheetState extends State<_ComentariosSheet> {
  final TextEditingController comentarioController = TextEditingController();
  bool enviando = false;

  @override
  void dispose() {
    comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SizedBox(
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comentarios',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('publicaciones')
                    .doc(widget.publicacionId)
                    .collection('comentarios')
                    .orderBy('fecha', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('Todavia no hay comentarios'),
                    );
                  }

                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final comentario = doc.data() as Map<String, dynamic>;
                      final foto = comentario['foto_usuario'] ?? '';

                      return ListTile(
                        leading: AvatarSeguro(imageUrl: foto),
                        title: Text(comentario['nombre'] ?? 'Usuario'),
                        subtitle: Text(comentario['comentario'] ?? ''),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: comentarioController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un comentario',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: enviando
                      ? null
                      : () async {
                          final texto = comentarioController.text.trim();
                          if (texto.isEmpty) {
                            return;
                          }

                          setState(() {
                            enviando = true;
                          });

                          await widget.onEnviar(
                            widget.publicacionId,
                            widget.currentUid,
                            texto,
                          );

                          if (!mounted) {
                            return;
                          }

                          comentarioController.clear();

                          setState(() {
                            enviando = false;
                          });
                        },
                  child: enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
