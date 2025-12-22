String? validarNotasTexto(String? v) {
  if (v == null || v.trim().isEmpty) return 'Las notas son requeridas';
  // Aceptar varios separadores comunes: espacio, salto de línea, coma, punto y coma o guión
  final tokens = v.split(RegExp(r'[\s,\-;]+')).where((t) => t.isNotEmpty);
  final perClean = RegExp(
    r'^(?:DO|RE|MI|FA|SOL|LA|SI)(?:#|b)?$',
    caseSensitive: false,
  );
  for (final t in tokens) {
    if (!perClean.hasMatch(t)) {
      return 'Solo notas válidas (DO, RE, MI, ...), usa el teclado de notas';
    }
  }
  return null;
}
