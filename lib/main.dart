import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cancionero/vista/lista_canciones_vista.dart';
import 'package:cancionero/vista/tema.dart';
import 'package:cancionero/vista/login.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseInicializado = true;
  try {
    // Inicializar Firebase con las opciones generadas por FlutterFire CLI
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Habilitar persistencia offline de Firestore
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  } catch (e) {
    // Si falla la inicialización mostramos una vista con instrucciones
    firebaseInicializado = false;
  }

  runApp(CancioneroApp(firebaseOk: firebaseInicializado));
}

class CancioneroApp extends StatelessWidget {
  final bool firebaseOk;
  const CancioneroApp({super.key, this.firebaseOk = true});

  @override
  Widget build(BuildContext context) {
    final esquemaColor =
        ColorScheme.fromSeed(
          seedColor: kDarkBlue,
          brightness: Brightness.dark,
        ).copyWith(
          primary: kDarkBlue,
          primaryContainer: kLightBlue,
          secondary: kLightBlue,
        );

    return MaterialApp(
      title: 'Cancionero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: esquemaColor,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        cardTheme: CardThemeData(
          color: kDarkBlue.withAlpha(31),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: firebaseOk ? const LoginVista() : const _FirebaseErrorVista(),
    );
  }
}

class _FirebaseErrorVista extends StatelessWidget {
  const _FirebaseErrorVista();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error de Firebase')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Firebase no está correctamente inicializado en esta plataforma.',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 12),
            Text(
              'En Windows debes generar el archivo `firebase_options.dart` con `flutterfire configure` y luego inicializar Firebase con `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              'Pasos resumidos:\n1) Instalar flutterfire CLI: `dart pub global activate flutterfire_cli`\n2) Ejecutar: `flutterfire configure` y seguir el asistente\n3) Importar y usar `DefaultFirebaseOptions` en `main.dart`',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
