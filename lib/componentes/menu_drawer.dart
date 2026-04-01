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
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 255, 225, 182),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: ImagenSegura(
                                imageUrl: foto,
                                height: 220,
                                width: double.infinity,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        );
                      },
                      child: AvatarSeguro(imageUrl: foto, radius: 35),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      usuario['user'] ?? 'Usuario',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 34,
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
                  await FirebaseAuth.instance.signOut();

                  if (!context.mounted) {
                    return;
                  }

                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/inicio', (route) => false);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
