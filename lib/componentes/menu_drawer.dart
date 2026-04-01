import 'package:cancionero/componentes/imagenes_seguras.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user!.uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Drawer(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        Map<String, dynamic> usuario =
            snapshot.data!.data() as Map<String, dynamic>;
        final String foto = usuario['foto'] ?? '';

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 255, 225, 182),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        showDialog(
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
                                    imageUrl: foto,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    borderRadius: BorderRadius.circular(10),
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: AvatarSeguro(imageUrl: foto, radius: 35),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      usuario['user'] ?? 'Usuario',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Inicio'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.library_music),
                title: const Text('Mis Canciones'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/mis-canciones');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Perfil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/perfil');
                },
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Seguridad'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/seguridad');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar Sesion'),
                onTap: () async {
                  Navigator.pop(context);

                  if (!context.mounted) {
                    return;
                  }

                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/inicio', (route) => false);

                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
