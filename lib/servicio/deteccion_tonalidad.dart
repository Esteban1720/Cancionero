String detectarTonalidad(String texto) {
  if (texto.trim().isEmpty) return 'Desconocida';

  // Parse tokens: aceptar espacios, comas, guiones, punto y coma
  final tokens = texto
      .trim()
      .split(RegExp(r'[\s,\-;]+'))
      .where((t) => t.isNotEmpty)
      .toList();

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

  final present = <int>{};
  for (final t in tokens) {
    final m = RegExp(
      r"^(DO|RE|MI|FA|SOL|LA|SI)(#|b)?$",
      caseSensitive: false,
    ).firstMatch(t);
    if (m == null) continue;
    final base = m.group(1)!.toUpperCase();
    final acc = (m.group(2) ?? '');
    var sem = baseMap[base]!;
    if (acc == '#') sem += 1;
    if (acc.toLowerCase() == 'b') sem -= 1;
    sem %= 12;
    if (sem < 0) sem += 12;
    present.add(sem);
  }

  if (present.isEmpty) return 'Desconocida';

  // Major scale intervals (semitones from tonic)
  const majorIntervals = [0, 2, 4, 5, 7, 9, 11];

  String semToName(int s) {
    const map = {
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
    return map[s]!;
  }

  int best = -1;
  int bestScore = -1;
  for (var tonic = 0; tonic < 12; tonic++) {
    final scale = majorIntervals.map((i) => (tonic + i) % 12).toSet();
    final score = present.where((p) => scale.contains(p)).length;
    if (score > bestScore) {
      bestScore = score;
      best = tonic;
    }
  }

  if (bestScore <= 0) return 'Desconocida';

  return '${semToName(best)} mayor';
}
