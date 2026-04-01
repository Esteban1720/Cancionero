import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CancionesRecibidasVista extends StatelessWidget {
  const CancionesRecibidasVista({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No hay sesion iniciada')),
      );
    }

    final recibidasRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('canciones_recibidas')
        .orderBy('fecha_compartida', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Canciones Recibidas')),
      body: StreamBuilder<QuerySnapshot>(
        stream: recibidasRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudieron cargar las canciones recibidas'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final canciones = snapshot.data!.docs;

          if (canciones.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavia no has recibido canciones de tus amigos.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: canciones.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = canciones[index];
              final data = doc.data() as Map<String, dynamic>;
              final bloques = (data['bloques'] as List?) ?? const [];
              final remitente = data['remitente_nombre'] ?? 'Amigo';

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color.fromARGB(255, 255, 236, 204),
                    child: Icon(Icons.library_music),
                  ),
                  title: Text(data['titulo'] ?? 'Cancion'),
                  subtitle: Text(
                    'Compartida por $remitente - ${bloques.length} secciones',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      '/ver-cancion',
                      arguments: {
                        'titulo': data['titulo'] ?? 'Cancion',
                        'bloques': List<Map<String, dynamic>>.from(
                          bloques.map(
                            (item) => Map<String, dynamic>.from(item as Map),
                          ),
                        ),
                        'actualizadoEn': data['fecha_compartida'],
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
