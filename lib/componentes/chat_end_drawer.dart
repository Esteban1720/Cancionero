import 'package:cancionero/componentes/imagenes_seguras.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatEndDrawer extends StatelessWidget {
  final String currentUid;

  const ChatEndDrawer({super.key, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color.fromARGB(255, 220, 238, 255),
              child: const Text(
                'Chats con amigos',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(currentUid)
                    .collection('amigos')
                    .orderBy('nombre')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Todavia no tienes amigos para chatear'),
                      ),
                    );
                  }

                  final totalNoLeidos = snapshot.data!.docs.fold<int>(
                    0,
                    (total, doc) {
                      final amigo = doc.data() as Map<String, dynamic>;
                      return total + ((amigo['mensajes_no_leidos'] ?? 0) as num).toInt();
                    },
                  );

                  return ListView(
                    children: [
                      if (totalNoLeidos > 0)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            'Tienes $totalNoLeidos mensaje${totalNoLeidos == 1 ? '' : 's'} sin leer',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 18, 87, 148),
                            ),
                          ),
                        ),
                      ...snapshot.data!.docs.map((doc) {
                        final amigo = doc.data() as Map<String, dynamic>;
                        final foto = amigo['foto'] ?? '';
                        final nombre = amigo['nombre'] ?? 'Amigo';
                        final ultimoMensaje =
                            amigo['ultimo_mensaje'] ?? 'Abre el chat';
                        final noLeidos =
                            ((amigo['mensajes_no_leidos'] ?? 0) as num).toInt();

                        return ListTile(
                          leading: AvatarSeguro(imageUrl: foto),
                          title: Text(nombre),
                          subtitle: Text(ultimoMensaje),
                          trailing: noLeidos > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      220,
                                      53,
                                      69,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '$noLeidos',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.chat_bubble_outline),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).pushNamed(
                              '/chat',
                              arguments: {
                                'amigoUid': doc.id,
                                'nombreAmigo': nombre,
                                'fotoAmigo': foto,
                              },
                            );
                          },
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
