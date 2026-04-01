import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SeguridadVista extends StatefulWidget {
  const SeguridadVista({super.key});

  @override
  State<SeguridadVista> createState() => _SeguridadVistaState();
}

class _SeguridadVistaState extends State<SeguridadVista> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool obscure = true;
  bool obscureConfirm = true;
  bool loading = false;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: passwordController,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText: 'Nueva contrasena',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      obscure = !obscure;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: confirmPasswordController,
              obscureText: obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirmar nueva contrasena',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      obscureConfirm = !obscureConfirm;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: loading ? null : cambiarPassword,
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Cambiar contrasena'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> cambiarPassword() async {
    if (passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe la nueva contrasena')),
      );
      return;
    }

    if (confirmPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirma la nueva contrasena')),
      );
      return;
    }

    if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contrasenas no coinciden')),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await FirebaseAuth.instance.currentUser?.updatePassword(
        passwordController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Contrasena actualizada')));
      passwordController.clear();
      confirmPasswordController.clear();
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String mensaje = 'No se pudo cambiar la contrasena';

      if (e.code == 'requires-recent-login') {
        mensaje = 'Debes iniciar sesion de nuevo para cambiar la contrasena';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }
}
