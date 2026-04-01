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

                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final amigo = doc.data() as Map<String, dynamic>;
                      final foto = amigo['foto'] ?? '';
                      final nombre = amigo['nombre'] ?? 'Amigo';
                      final ultimoMensaje =
                          amigo['ultimo_mensaje'] ?? 'Abre el chat';

                      return ListTile(
                        leading: AvatarSeguro(imageUrl: foto),
                        title: Text(nombre),
                        subtitle: Text(ultimoMensaje),
                        trailing: const Icon(Icons.chat_bubble_outline),
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
                    }).toList(),
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
