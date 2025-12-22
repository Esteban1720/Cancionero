import 'package:flutter/material.dart';
import 'package:cancionero/modelo/cancion.dart';
import 'package:cancionero/servicio/servicio_almacenamiento.dart';
import 'package:cancionero/vista/gradient_scaffold.dart';
import 'package:cancionero/servicio/deteccion_tonalidad.dart';
import 'package:cancionero/vista/tema.dart';
import 'package:cancionero/servicio/transposicion_notas.dart';
import 'editar_cancion_vista.dart';

class DetalleCancionVista extends StatefulWidget {
  final Cancion cancion;
  final ServicioAlmacenamiento almacenamiento;

  const DetalleCancionVista({
    super.key,
    required this.cancion,
    required this.almacenamiento,
  });

  @override
  State<DetalleCancionVista> createState() => _DetalleCancionVistaState();
}

class _DetalleCancionVistaState extends State<DetalleCancionVista> {
  double _tamanoLetra = 22.0;
  static const double _minTamano = 12.0;
  static const double _maxTamano = 48.0;
  static const double _pasoTamano = 2.0;

  // Subtítulos
  double _tamanoSubtitulo = 14.0;
  static const double _minTamSubtitulo = 8.0;
  static const double _maxTamSubtitulo = 40.0;

  Future<void> _eliminarCancion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar canción'),
        content: const Text('¿Seguro que deseas eliminar esta canción?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmar == true) {
      await widget.almacenamiento.eliminarCancion(widget.cancion.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
  }

  // Reenvía a la función compartida que normaliza accidentales y transpone
  String _transposeNotasTexto(String texto, int semitones) {
    return transponerNotasTexto(texto, semitones);
  }

  Future<void> _aplicarTransposicion(int semitones) async {
    final nuevoTexto = _transposeNotasTexto(widget.cancion.notas, semitones);
    setState(() {});
    final actualizado = widget.cancion.copiarCon(notas: nuevoTexto);
    await widget.almacenamiento.actualizarCancion(actualizado);
    // mantener sincronizado el modelo en memoria
    widget.cancion.notas = nuevoTexto;
    setState(() {});
    // Mostrar confirmación breve
    final descripcion = semitones == 2
        ? 'Subido 1 tono'
        : semitones == -2
        ? 'Bajado 1 tono'
        : semitones == 1
        ? 'Subido 1/2 tono'
        : 'Bajado 1/2 tono';
    // Removido: No mostrar mensaje de transposición aplicada
  }

  List<List<String>> _getTokensByLine() {
    final text = widget.cancion.notas;
    if (text.isEmpty) return [];
    final lines = text.split('\n');
    return lines
        .map(
          (line) => line
              .trim()
              .split(RegExp(r'\s*\-\s*'))
              .where((t) => t.isNotEmpty)
              .toList(),
        )
        .toList();
  }

  Future<void> _editarCancion() async {
    final actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (c) => EditarCancionVista(
          almacenamiento: widget.almacenamiento,
          cancion: widget.cancion,
        ),
      ),
    );
    if (!mounted) return;
    if (actualizado == true) Navigator.of(context).pop(true);
  }

  @override
  void initState() {
    super.initState();
    _tamanoLetra = widget.cancion.tamanoLetra;
    // Inicializar tamaño de subtítulos a partir del modelo (si existía)
    _tamanoSubtitulo =
        widget.cancion.subtituloFontSize ?? (widget.cancion.tamanoLetra * 0.6);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: Text(widget.cancion.titulo),
        actions: [
          IconButton(onPressed: _editarCancion, icon: const Icon(Icons.edit)),
          IconButton(
            onPressed: _eliminarCancion,
            icon: const Icon(Icons.delete_forever),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cuadro superior con la tonalidad detectada (estilo acorde a la app)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.music_note, color: Colors.white70),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Tonalidad',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white70),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: kLightBlue.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            detectarTonalidad(widget.cancion.notas),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Subtítulo (opcional)
              if ((widget.cancion.subtitulo ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    widget.cancion.subtitulo ?? '',
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                          fontSize: _tamanoSubtitulo,
                        ) ??
                        TextStyle(
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                          fontSize: _tamanoSubtitulo,
                        ),
                  ),
                ),
              // Mostrar notas con saltos y un token por línea
              Builder(
                builder: (c) {
                  final lines = _getTokensByLine();
                  if (lines.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(lines.length, (lineIndex) {
                      final tokens = lines[lineIndex];
                      if (tokens.isEmpty) return const SizedBox(height: 8);
                      final subtitle =
                          (widget.cancion.subtitulosLineas ?? []).length >
                              lineIndex
                          ? widget.cancion.subtitulosLineas![lineIndex]
                          : null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tokens.join(' - '),
                              style:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(
                                    fontSize: _tamanoLetra,
                                    height: 1.4,
                                  ) ??
                                  TextStyle(
                                    fontSize: _tamanoLetra,
                                    height: 1.4,
                                  ),
                            ),
                            if (subtitle != null && subtitle.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  subtitle,
                                  style:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color: Colors.white70,
                                        fontStyle: FontStyle.italic,
                                        fontSize: _tamanoSubtitulo,
                                      ) ??
                                      TextStyle(
                                        color: Colors.white70,
                                        fontStyle: FontStyle.italic,
                                        fontSize: _tamanoSubtitulo,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 18),
              // Controles de transposición
              Text(
                'Transponer notas',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _aplicarTransposicion(-2),
                    icon: const Icon(Icons.arrow_downward),
                    label: const Text('Bajar 1 tono'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _aplicarTransposicion(-1),
                    icon: const Icon(Icons.arrow_downward_outlined),
                    label: const Text('Bajar 1/2 tono'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _aplicarTransposicion(1),
                    icon: const Icon(Icons.arrow_upward_outlined),
                    label: const Text('Subir 1/2 tono'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _aplicarTransposicion(2),
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('Subir 1 tono'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Tamaño de letra',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Slider(
                min: _minTamano,
                max: _maxTamano,
                divisions: ((_maxTamano - _minTamano) / _pasoTamano).round(),
                value: _tamanoLetra,
                label: '${_tamanoLetra.toInt()} pt',
                onChanged: (v) async {
                  setState(() => _tamanoLetra = v);
                  final actualizado = widget.cancion.copiarCon(
                    tamanoLetra: _tamanoLetra,
                  );
                  await widget.almacenamiento.actualizarCancion(actualizado);
                  widget.cancion.tamanoLetra = _tamanoLetra;
                },
              ),

              const SizedBox(height: 18),
              Text(
                'Tamaño de subtítulos',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Slider(
                min: _minTamSubtitulo,
                max: _maxTamSubtitulo,
                divisions: ((_maxTamSubtitulo - _minTamSubtitulo) / 1).round(),
                value: _tamanoSubtitulo,
                label: '${_tamanoSubtitulo.toInt()} pt',
                onChanged: (v) async {
                  setState(() => _tamanoSubtitulo = v);
                  final actualizado = widget.cancion.copiarCon(
                    subtituloFontSize: _tamanoSubtitulo,
                  );
                  await widget.almacenamiento.actualizarCancion(actualizado);
                  widget.cancion.subtituloFontSize = _tamanoSubtitulo;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
