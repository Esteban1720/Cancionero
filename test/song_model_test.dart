import 'package:flutter_test/flutter_test.dart';
import 'package:cancionero/modelo/cancion.dart';

void main() {
  test('Serialización JSON de Cancion incluye tamanoLetra', () {
    final c = Cancion(
      id: '1',
      titulo: 'Mi canción',
      notas: 'Notas',
      tamanoLetra: 30.0,
    );
    final jsonStr = Cancion.listaAJson([c]);
    final parsed = Cancion.listaDesdeJson(jsonStr);
    expect(parsed.length, 1);
    expect(parsed.first.id, '1');
    expect(parsed.first.titulo, 'Mi canción');
    expect(parsed.first.notas, 'Notas');
    expect(parsed.first.tamanoLetra, 30.0);
  });
}
