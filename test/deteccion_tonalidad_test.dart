import 'package:flutter_test/flutter_test.dart';
import 'package:cancionero/servicio/deteccion_tonalidad.dart';

void main() {
  test('Detecta DO mayor para escala C mayor', () {
    final texto = 'DO RE MI FA SOL LA SI';
    expect(detectarTonalidad(texto), 'DO mayor');
  });

  test('Detecta SOL mayor cuando hay FA#', () {
    final texto = 'SOL LA SI DO RE MI FA#';
    expect(detectarTonalidad(texto), 'SOL mayor');
  });

  test('Devuelve Desconocida con notas extrañas', () {
    final texto = 'XYZ ABC';
    expect(detectarTonalidad(texto), 'Desconocida');
  });
}
