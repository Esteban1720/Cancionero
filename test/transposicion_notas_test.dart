import 'package:flutter_test/flutter_test.dart';
import 'package:cancionero/servicio/transposicion_notas.dart';

void main() {
  test('Transposición básica suma 2 semitonos', () {
    final entrada = 'DO RE MI';
    final salida = transponerNotasTexto(entrada, 2);
    expect(salida, 'RE MI FA#');
  });

  test('Normaliza secuencias largas de accidentales antes de transponer', () {
    final entrada = 'SOL######## SI##';
    final salida = transponerNotasTexto(entrada, -2);
    // SOL######## => DO#  (7 + 8 -2 = sem 1 -> DO#)
    // SI## => SI (11 + 2 -2 = 11 -> SI)
    expect(salida, 'DO# SI');
  });

  test('No deja múltiples accidental al transponer varias veces', () {
    var texto = 'LA# LA#';
    texto = transponerNotasTexto(texto, 1); // LA# -> SI
    texto = transponerNotasTexto(texto, 1); // SI -> DO#
    // Resultado debe tener accidentales normalizados y no repetir '##...'
    expect(texto.contains('##'), isFalse);
  });
}
