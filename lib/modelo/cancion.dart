import 'dart:convert';

class Cancion {
  String id;
  String titulo;
  String notas;
  String? subtitulo;
  List<String>? subtitulosLineas;
  double? subtituloFontSize;
  double tamanoLetra;

  Cancion({
    required this.id,
    required this.titulo,
    required this.notas,
    this.subtitulo,
    this.subtitulosLineas,
    this.subtituloFontSize,
    this.tamanoLetra = 22.0,
  });

  factory Cancion.desdeJson(Map<String, dynamic> json) => Cancion(
    id: json['id'] as String,
    titulo: json['title'] as String,
    notas: json['notes'] ?? '',
    subtitulo: json['subtitle'] as String?,
    subtitulosLineas: (json['subtitlesLines'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList(),
    subtituloFontSize: (json['subtitleFontSize'] as num?)?.toDouble(),
    tamanoLetra: (json['fontSize'] as num?)?.toDouble() ?? 22.0,
  );

  Map<String, dynamic> aJson() => {
    'id': id,
    'title': titulo,
    'notes': notas,
    'subtitle': subtitulo,
    'subtitlesLines': subtitulosLineas,
    'subtitleFontSize': subtituloFontSize,
    'fontSize': tamanoLetra,
  };

  Cancion copiarCon({
    String? id,
    String? titulo,
    String? notas,
    String? subtitulo,
    List<String>? subtitulosLineas,
    double? subtituloFontSize,
    double? tamanoLetra,
  }) {
    return Cancion(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      notas: notas ?? this.notas,
      subtitulo: subtitulo ?? this.subtitulo,
      subtitulosLineas: subtitulosLineas ?? this.subtitulosLineas,
      subtituloFontSize: subtituloFontSize ?? this.subtituloFontSize,
      tamanoLetra: tamanoLetra ?? this.tamanoLetra,
    );
  }

  static List<Cancion> listaDesdeJson(String jsonStr) {
    final List<dynamic> list = json.decode(jsonStr) as List<dynamic>;
    return list
        .map((e) => Cancion.desdeJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listaAJson(List<Cancion> canciones) {
    final list = canciones.map((s) => s.aJson()).toList();
    return json.encode(list);
  }
}
