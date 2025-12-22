String transponerNotasTexto(String texto, int semitones) {
  final notaRegex = RegExp(
    // No \\b al final porque los accidentales (#/b) no son "word chars" y romperían la coincidencia
    r"\b(DO|RE|MI|FA|SOL|LA|SI)((?:#|b)*)",
    caseSensitive: false,
  );

  String reemplazo(Match m) {
    final base = m.group(1)!.toUpperCase();
    final accSeq =
        (m.group(2) ?? ''); // puede ser '', '#', '##', 'b', 'bb', etc.

    // Mapa base a semitonos (DO = 0)
    final baseMap = {
      'DO': 0,
      'RE': 2,
      'MI': 4,
      'FA': 5,
      'SOL': 7,
      'LA': 9,
      'SI': 11,
    };

    var sem = baseMap[base]!;

    // Normalizar la secuencia de accidentales: cada '#' suma 1, cada 'b' resta 1
    if (accSeq.isNotEmpty) {
      var delta = 0;
      for (var i = 0; i < accSeq.length; i++) {
        final ch = accSeq[i];
        if (ch == '#') delta += 1;
        if (ch == 'b' || ch == 'B') delta -= 1;
      }
      sem += delta;
    }

    sem = (sem + semitones) % 12;
    if (sem < 0) sem += 12;

    // Convertir semitono a notación latina preferida con '#' para sostenido
    const semToNota = {
      0: 'DO',
      1: 'DO#',
      2: 'RE',
      3: 'RE#',
      4: 'MI',
      5: 'FA',
      6: 'FA#',
      7: 'SOL',
      8: 'SOL#',
      9: 'LA',
      10: 'LA#',
      11: 'SI',
    };

    return semToNota[sem]!;
  }

  return texto.replaceAllMapped(notaRegex, (m) => reemplazo(m));
}
