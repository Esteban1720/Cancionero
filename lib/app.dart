import 'package:cancionero/vista/chat.dart';
import 'package:cancionero/vista/canciones_recibidas.dart';
import 'package:cancionero/vista/dasboard.dart';
import 'package:cancionero/vista/inicio_sesion.dart';
import 'package:cancionero/vista/mis_canciones.dart';
import 'package:cancionero/vista/perfil.dart';
import 'package:cancionero/vista/registro.dart';
import 'package:cancionero/vista/seguridad.dart';
import 'package:cancionero/vista/ver_cancion.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 12, 12, 12),
        ),
      ),
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/':
          case '/inicio':
            return MaterialPageRoute(builder: (_) => const InicioSesion());
          case '/registro':
            return MaterialPageRoute(builder: (_) => const Registro());
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const Dasboard());
          case '/perfil':
            return MaterialPageRoute(builder: (_) => const PerfilVista());
          case '/mis-canciones':
            return MaterialPageRoute(builder: (_) => const MisCancionesVista());
          case '/canciones-recibidas':
            return MaterialPageRoute(
              builder: (_) => const CancionesRecibidasVista(),
            );
          case '/ver-cancion':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => VerCancionVista(
                titulo: args['titulo'] ?? 'Cancion',
                bloques: List<Map<String, dynamic>>.from(
                  (args['bloques'] as List? ?? const []).map(
                    (item) => Map<String, dynamic>.from(item as Map),
                  ),
                ),
                actualizadoEn: args['actualizadoEn'],
              ),
            );
          case '/seguridad':
            return MaterialPageRoute(builder: (_) => const SeguridadVista());
          case '/chat':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => ChatVista(
                amigoUid: args?['amigoUid'] ?? '',
                nombreAmigo: args?['nombreAmigo'] ?? 'Chat',
                fotoAmigo: args?['fotoAmigo'] ?? '',
              ),
            );
          default:
            return MaterialPageRoute(builder: (_) => const InicioSesion());
        }
      },
    );
  }
}
