import 'package:flutter/material.dart';
import 'package:cancionero/vista/lista_canciones_vista.dart';
import 'package:cancionero/vista/tema.dart';

void main() {
  runApp(const CancioneroApp());
}

class CancioneroApp extends StatelessWidget {
  const CancioneroApp({super.key});

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
      home: const ListaCancionesVista(),
    );
  }
}
