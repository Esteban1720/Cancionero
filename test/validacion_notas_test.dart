import 'package:flutter_test/flutter_test.dart';
import 'package:cancionero/vista/validacion_notas.dart';

void main() {
  test('validarNotasTexto acepta notas válidas', () {
    expect(validarNotasTexto('DO RE MI'), isNull);
    expect(validarNotasTexto('DO# REb SOL'), isNull);
    expect(validarNotasTexto('LA SI FA'), isNull);
    expect(validarNotasTexto('LA# - DO - RE - MI - FA - SOL - SI'), isNull);
    expect(validarNotasTexto('DO,RE,MI'), isNull);
  });

  test('validarNotasTexto rechaza texto vacío', () {
    expect(validarNotasTexto(''), isNotNull);
  });

  test('validarNotasTexto rechaza entradas inválidas', () {
    expect(validarNotasTexto('ABC'), isNotNull);
    expect(validarNotasTexto('DOX RE'), isNotNull);
    expect(validarNotasTexto('DO RE M I'), isNotNull);
  });
}
