// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:cancionero/main.dart';

void main() {
  testWidgets('La pantalla principal carga (Login)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CancioneroApp());
    await tester.pump();
    // Verificar que la vista de login se renderiza correctamente
    expect(find.text('Iniciar sesión'), findsWidgets);
  });
}
