import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:cancionero/secrets.dart' as secrets;
import 'package:cancionero/servicio/auth_service.dart';
import 'package:cancionero/vista/lista_canciones_vista.dart';
import 'package:cancionero/vista/registro_vista.dart';
import 'package:cancionero/vista/gradient_scaffold.dart';
import 'package:cancionero/vista/tema.dart';

class LoginVista extends StatefulWidget {
  const LoginVista({super.key});

  @override
  State<LoginVista> createState() => _LoginVistaState();
}

class _LoginVistaState extends State<LoginVista> {
  final AuthService _authService = AuthService();
  User? usuario;
  bool cargando = false;

  // Campos para correo/contraseña
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _passwordVisible = false;

  bool _autoTestTriggered = false; 

  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    try {
      _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
        if (!mounted) return;
        setState(() => usuario = u);
        if (u != null) {
          // Cuando hay usuario, navegamos a la lista de canciones
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ListaCancionesVista()),
          );
        }
      });
    } catch (e) {
      // En entornos de test o cuando Firebase no está inicializado, evitamos crash y permitimos tests sin Firebase.
      // ignore: avoid_print
      print('No se pudo suscribir a authStateChanges: $e');
      _authSub = null;
    }

    // Disparador de prueba automático (solo en modo debug y Windows) para verificar Google Sign-In.
    if (kDebugMode && !_autoTestTriggered) {
      try {
        if (Platform.isWindows && _googleDisponible) {
          _autoTestTriggered = true;
          Future.delayed(const Duration(seconds: 2), () async {
            // Intentamos iniciar el flujo de Google Sign-In para validar la implementación en Windows.
            await _iniciarSesionGoogle();
          });
        }
      } catch (_) {}
    }
  }

  bool get _googleDisponible {
    try {
      if (kIsWeb || Platform.isAndroid || Platform.isIOS) return true;
      // Para Windows permitimos Google si el Client ID de Desktop está configurado
      if (Platform.isWindows)
        return !secrets.googleDesktopClientId.contains('TU_CLIENT_ID');
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _iniciarSesionGoogle() async {
    if (!mounted) return;
    setState(() => cargando = true);
    try {
      final u = await _authService.signInWithGoogle();
      if (u != null) {
        // el servicio ya crea el documento del usuario en Firestore
      }
    } on MissingPluginException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Google Sign-In no está disponible en esta plataforma.',
            ),
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        if (e.code == 'permission-denied') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permiso de Firestore denegado. Revisa tus reglas en Firebase Console.',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error de Firebase: ${e.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al iniciar sesión: $e')));
      }
    } finally {
      if (!mounted) return;
      setState(() => cargando = false);
    }
  }

  Future<void> _cerrarSesion() async {
    await _authService.signOut();
  }

  Future<void> _iniciarSesionCorreo() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce correo y contraseña.')),
      );
      return;
    }

    setState(() => cargando = true);
    try {
      final u = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      if (u != null) {
        // login OK
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al iniciar sesión: $e')));
    } finally {
      setState(() => cargando = false);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: cargando
              ? const CircularProgressIndicator(color: Colors.white)
              : usuario == null
                  ? Container(
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
                          const SizedBox(height: 8),
                          Text(
                            'Bienvenido al Cancionero',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),

                          // Google Sign-In
                          if (_googleDisponible)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: Image.asset(
                                  'assets/logo.png',
                                  width: 24,
                                  height: 24,
                                ),
                                label: const Text('Iniciar sesión con Google'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: kDarkBlue,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _iniciarSesionGoogle,
                              ),
                            )
                          else if (Platform.isWindows)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                children: [
                                  Text(
                                    'Google Sign-In no está configurado para Windows.',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(height: 6),
                                  TextButton(
                                    onPressed: () {
                                      // Mostrar instrucción rápida
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Añade tu Client ID de tipo "Desktop" en lib/secrets.dart y recompila.',
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('Cómo configurar'),
                                  ),
                                ],
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'Google Sign-In no disponible en esta plataforma. Usa correo y contraseña.',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),

                          const SizedBox(height: 20),

                          // Formulario correo/contraseña
                          TextField(
                            controller: _emailCtrl,
                            decoration: InputDecoration(
                              labelText: 'Correo',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(Icons.email),
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
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                              ),
                            ),
                            obscureText: !_passwordVisible,
                          ),
                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _iniciarSesionCorreo,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kLightBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Iniciar sesión'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegistroVista(),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withOpacity(0.14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Registrarse'),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundImage: usuario!.photoURL != null
                                    ? NetworkImage(usuario!.photoURL!)
                                    : null,
                                radius: 36,
                                child: usuario!.photoURL == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Hola, ${usuario!.displayName ?? usuario!.email}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const ListaCancionesVista(),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kLightBlue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Continuar'),
                              ),
                              TextButton(
                                onPressed: _cerrarSesion,
                                child: const Text('Cerrar sesión'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
