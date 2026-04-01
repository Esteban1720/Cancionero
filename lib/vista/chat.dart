import 'package:cancionero/componentes/imagenes_seguras.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatVista extends StatefulWidget {
  final String amigoUid;
  final String nombreAmigo;
  final String fotoAmigo;

  const ChatVista({
    super.key,
    required this.amigoUid,
    required this.nombreAmigo,
    required this.fotoAmigo,
  });

  @override
  State<ChatVista> createState() => _ChatVistaState();
}

class _ChatVistaState extends State<ChatVista> {
  final TextEditingController mensajeController = TextEditingController();
  bool enviando = false;

  @override
  void dispose() {
    mensajeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AvatarSeguro(imageUrl: widget.fotoAmigo),
            const SizedBox(width: 10),
            Text(widget.nombreAmigo),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId(user!.uid, widget.amigoUid))
                  .collection('mensajes')
                  .orderBy('fecha')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final mensajes = snapshot.data!.docs;

                if (mensajes.isEmpty) {
                  return const Center(
                    child: Text('Todavia no hay mensajes en este chat'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: mensajes.length,
                  itemBuilder: (context, index) {
                    final data = mensajes[index].data() as Map<String, dynamic>;
                    final esMio = data['emisor_uid'] == user.uid;

                    return Align(
                      alignment: esMio
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: esMio
                              ? const Color.fromARGB(255, 179, 229, 252)
                              : const Color.fromARGB(255, 238, 238, 238),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(data['mensaje'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: mensajeController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: enviando ? null : enviarMensaje,
                  child: enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> enviarMensaje() async {
    final texto = mensajeController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (texto.isEmpty || user == null) {
      return;
    }

    setState(() {
      enviando = true;
    });

    final myDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();
    final misDatos = myDoc.data() ?? {};
    final idChat = chatId(user.uid, widget.amigoUid);

    await FirebaseFirestore.instance.collection('chats').doc(idChat).set({
      'participantes': [user.uid, widget.amigoUid],
      'ultimo_mensaje': texto,
      'fecha_ultimo_mensaje': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(idChat)
        .collection('mensajes')
        .add({
          'mensaje': texto,
          'emisor_uid': user.uid,
          'emisor_nombre': misDatos['user'] ?? 'Usuario',
          'fecha': FieldValue.serverTimestamp(),
        });

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('amigos')
        .doc(widget.amigoUid)
        .set({'ultimo_mensaje': texto}, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.amigoUid)
        .collection('amigos')
        .doc(user.uid)
        .set({'ultimo_mensaje': texto}, SetOptions(merge: true));

    mensajeController.clear();

    if (mounted) {
      setState(() {
        enviando = false;
      });
    }
  }

  String chatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }
}
