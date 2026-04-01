import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VerCancionVista extends StatefulWidget {
  const VerCancionVista({
    super.key,
    required this.titulo,
    required this.bloques,
    this.actualizadoEn,
  });

  final String titulo;
  final List<Map<String, dynamic>> bloques;
  final Object? actualizadoEn;

  @override
  State<VerCancionVista> createState() => _VerCancionVistaState();
}

class _VerCancionVistaState extends State<VerCancionVista> {
  static const List<String> _notasCromaticas = [
    'Do',
    'Do#',
    'Re',
    'Re#',
    'Mi',
    'Fa',
    'Fa#',
    'Sol',
    'Sol#',
    'La',
    'La#',
    'Si',
  ];

  static const Map<String, String> _equivalencias = {
    'Dob': 'Si',
    'Reb': 'Do#',
    'Mib': 'Re#',
    'Fab': 'Mi',
    'Solb': 'Fa#',
    'Lab': 'Sol#',
    'Sib': 'La#',
    'Si#': 'Do',
    'Mi#': 'Fa',
  };

  int _transposicion = 0;
  double _tamanoNotas = 20;

  @override
  Widget build(BuildContext context) {
    final bloques = _parsearBloques(widget.bloques);
    final fecha = _resolverFecha(widget.actualizadoEn);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (fecha != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Actualizada: ${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          const Text(
            'Secciones',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (bloques.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('Esta cancion todavia no tiene secciones.'),
              ),
            ),
          ...bloques.map((bloque) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bloque.subtitulo.isEmpty
                          ? 'Seccion sin subtitulo'
                          : bloque.subtitulo,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (bloque.notas.isEmpty)
                      const Text('Sin notas en esta seccion')
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: bloque.notas
                            .map(
                              (nota) => _TarjetaNota(
                                nota: _transponerNota(nota, _transposicion),
                                tamano: _tamanoNotas,
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Card(
            color: const Color.fromARGB(255, 255, 244, 226),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.swap_vert, size: 18),
                        label: Text(
                          _transposicion == 0
                              ? 'Tono original'
                              : 'Transpuesta ${_transposicion > 0 ? '+' : ''}$_transposicion',
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.piano, size: 18),
                        label: Text('${bloques.length} secciones'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _cambiarTransposicion(-2),
                        icon: const Icon(Icons.keyboard_double_arrow_down),
                        label: const Text('-1 tono'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _cambiarTransposicion(-1),
                        icon: const Icon(Icons.remove),
                        label: const Text('-1/2 tono'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _cambiarTransposicion(1),
                        icon: const Icon(Icons.add),
                        label: const Text('+1/2 tono'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _cambiarTransposicion(2),
                        icon: const Icon(Icons.keyboard_double_arrow_up),
                        label: const Text('+1 tono'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _transposicion = 0;
                          });
                        },
                        child: const Text('Restablecer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tamano de notas',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: _tamanoNotas,
                    min: 14,
                    max: 34,
                    divisions: 10,
                    label: _tamanoNotas.toStringAsFixed(0),
                    onChanged: (value) {
                      setState(() {
                        _tamanoNotas = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _cambiarTransposicion(int paso) {
    setState(() {
      _transposicion += paso;
    });
  }

  DateTime? _resolverFecha(Object? valor) {
    if (valor is Timestamp) {
      return valor.toDate();
    }
    if (valor is DateTime) {
      return valor;
    }
    return null;
  }

  int _indiceNota(String nota) {
    final normalizada = _equivalencias[nota] ?? nota;
    final indice = _notasCromaticas.indexOf(normalizada);
    return indice < 0 ? 0 : indice;
  }

  String _transponerNota(String nota, int semitonos) {
    final index = _indiceNota(nota);
    final nuevoIndex = (index + semitonos) % 12;
    final ajustado = nuevoIndex < 0 ? nuevoIndex + 12 : nuevoIndex;
    return _notasCromaticas[ajustado];
  }

  List<_BloqueVisual> _parsearBloques(List<Map<String, dynamic>> bloques) {
    return bloques.map((mapa) {
      final notas = mapa['notas'] is List
          ? List<String>.from((mapa['notas'] as List).map((e) => '$e'))
          : <String>[];
      return _BloqueVisual(
        subtitulo: '${mapa['subtitulo'] ?? ''}',
        notas: notas,
      );
    }).toList();
  }
}

class _TarjetaNota extends StatelessWidget {
  const _TarjetaNota({
    required this.nota,
    required this.tamano,
  });

  final String nota;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 240, 247, 255),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color.fromARGB(255, 200, 221, 247),
        ),
      ),
      child: Text(
        nota,
        style: TextStyle(
          fontSize: tamano,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BloqueVisual {
  const _BloqueVisual({
    required this.subtitulo,
    required this.notas,
  });

  final String subtitulo;
  final List<String> notas;
}
