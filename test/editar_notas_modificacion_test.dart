import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Reemplazar nota mantiene guiones y separadores', () {
    final text = 'MI - RE - FA - SI - LA - DO';
    final noteRegex = RegExp(
      r"(?:DO|RE|MI|FA|SOL|LA|SI)(?:#|b)?(?=\$|[\s\-\n,;])",
      caseSensitive: false,
    );
    final matches = noteRegex.allMatches(text).toList();
    // Reemplazar la segunda nota (RE) por DO#
    final index = 1;
    final m = matches[index];
    final nuevo = '${text.substring(0, m.start)}DO#${text.substring(m.end)}';
    expect(nuevo, 'MI - DO# - FA - SI - LA - DO');

    // Reemplazar una nota que ya tiene accidental, sin duplicar
    var text2 = 'MI - RE# - FA - SI';
    final matches2 = noteRegex.allMatches(text2).toList();
    final m2 = matches2[1];
    final nuevo2 =
        '${text2.substring(0, m2.start)}LA#${text2.substring(m2.end)}';
    expect(nuevo2, 'MI - LA# - FA - SI');
  });

  test('Insertar salto no duplica guiones y genera nueva línea', () {
    var text = 'MI - RE - FA - ';
    // Simular comportamiento de salto
    var trimmed = text.replaceFirst(RegExp(r'[ \t\r]+$'), '');
    // The function in the app removes trailing separators before adding newline
    trimmed = trimmed.replaceFirst(RegExp(r'(\s*[-,;]\s*)$'), '');
    var result = trimmed.isEmpty ? '' : '$trimmed\n';
    expect(result, 'MI - RE - FA\n');

    // Añadir una nota después del salto y normalizar
    var result2 = '${result}SOL - ';
    result2 = result2.replaceAll(RegExp(r'(\s*[\-;,]\s*)+'), ' - ');
    expect(result2.contains('--'), false);
  });

  test('Eliminar nota mantiene guiones correctamente', () {
    var text = 'MI - RE - FA - SI - LA - DO';
    final noteRegex = RegExp(
      r"(?:DO|RE|MI|FA|SOL|LA|SI)(?:#|b)?(?=\$|[\s\-\n,;])",
      caseSensitive: false,
    );
    final matches = noteRegex.allMatches(text).toList();
    final index = 1; // eliminar RE
    final m = matches[index];
    var nuevo = text.substring(0, m.start) + text.substring(m.end);
    nuevo = nuevo.replaceAll(RegExp(r'\s+'), ' ');
    nuevo = nuevo.replaceAll(RegExp(r'(\s*[\-;,]\s*)+'), ' - ');
    nuevo = nuevo.replaceAll(RegExp(r'(^\s*[-,;]\s*)|(\s*[-,;]\s*$)'), '');
    nuevo = nuevo.trim();
    expect(nuevo, 'MI - FA - SI - LA - DO');
  });
}
