import 'package:flutter/material.dart';
import 'package:cancionero/servicio/auth_service.dart';
import 'package:cancionero/vista/gradient_scaffold.dart';
import 'package:cancionero/vista/tema.dart';

class RegistroVista extends StatefulWidget {
  const RegistroVista({super.key});

  @override
  State<RegistroVista> createState() => _RegistroVistaState();
}

class _RegistroVistaState extends State<RegistroVista> {
  final AuthService _authService = AuthService();
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _cargando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrarse() async {
    final nombre = _nombreCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (nombre.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rellena nombre, correo y contraseña.')),
      );
      return;
    }

    setState(() => _cargando = true);
    try {
      final u = await _authService.signUpWithEmail(
        email: email,
        password: password,
        nombre: nombre,
      );

      if (u != null) {
        // Registro completado. Pop para dejar que el listener de Login maneje la navegación.
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Registro completado')));
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al registrarse: $e')));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Registro'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: _cargando
              ? const CircularProgressIndicator(color: Colors.white)
              : Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/logo.png', width: 72),
                      const SizedBox(height: 12),
                      Text(
                        'Crea tu cuenta',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nombreCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nombre',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailCtrl,
                        decoration: InputDecoration(
                          labelText: 'Correo',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordCtrl,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        obscureText: _obscure,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _registrarse,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kLightBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Registrarse'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Volver al inicio'),
                        style: TextButton.styleFrom(foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
