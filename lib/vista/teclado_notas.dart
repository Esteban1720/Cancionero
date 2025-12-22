import 'package:flutter/material.dart';
import 'package:cancionero/vista/tema.dart';

typedef InsertCallback = void Function(String token);
typedef ReplaceAtCallback = void Function(int index, String token);
typedef DeleteAtCallback = void Function(int index);

class TecladoNotas extends StatefulWidget {
  final InsertCallback onInsert;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onClose;
  // Texto actual (opcional) para mostrar tokens seleccionables
  final String? currentText;
  // Callbacks para editar un token seleccionado
  final ReplaceAtCallback? onReplaceAt;
  final DeleteAtCallback? onDeleteAt;
  // Índice seleccionado para editar
  final int? selectedIndex;

  const TecladoNotas({
    super.key,
    required this.onInsert,
    required this.onBackspace,
    required this.onClear,
    required this.onClose,
    this.currentText,
    this.onReplaceAt,
    this.onDeleteAt,
    this.selectedIndex,
  });

  @override
  State<TecladoNotas> createState() => _TecladoNotasState();
}

class _TecladoNotasState extends State<TecladoNotas> {
  // Notas en notación latina
  static const List<String> _notas = [
    'DO',
    'RE',
    'MI',
    'FA',
    'SOL',
    'LA',
    'SI',
  ];
  String _accidental = ''; // '', '#' o 'b'

  List<String> _tokensFromText(String? text) {
    if (text == null || text.trim().isEmpty) return [];
    return text
        .trim()
        .split(RegExp(r'[\s,\-;]+'))
        .where((t) => t.isNotEmpty)
        .toList();
  }

  Widget _buildNotaButton(String nota) {
    final label = nota + _accidental;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: kLightBlue.withOpacity(0.12),
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
      onPressed: () {
        if (widget.selectedIndex != null && widget.onReplaceAt != null) {
          widget.onReplaceAt!(widget.selectedIndex!, label);
        } else {
          widget.onInsert(label);
        }
      },
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: controles rápidos
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Accidentales separados: Natural, Sostenido (#), Bemol (b)
                ElevatedButton(
                  onPressed: () => setState(() => _accidental = ''),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accidental.isEmpty
                        ? kLightBlue.withOpacity(0.25)
                        : kLightBlue.withOpacity(0.12),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                  ),
                  child: const Text('Natural'),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _accidental = '#'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accidental == '#'
                        ? kLightBlue.withOpacity(0.25)
                        : kLightBlue.withOpacity(0.12),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                  ),
                  child: const Text('Sostenido'),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _accidental = 'b'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accidental == 'b'
                        ? kLightBlue.withOpacity(0.25)
                        : kLightBlue.withOpacity(0.12),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                  ),
                  child: const Text('Bemol'),
                ),
                ElevatedButton.icon(
                  onPressed: () => widget.onInsert('\n'),
                  icon: const Icon(Icons.keyboard_return),
                  label: const Text('Salto'),
                ),
                IconButton(
                  onPressed: () {
                    if (widget.selectedIndex != null &&
                        widget.onDeleteAt != null) {
                      widget.onDeleteAt!(widget.selectedIndex!);
                    } else {
                      widget.onBackspace();
                    }
                  },
                  icon: const Icon(Icons.backspace),
                  tooltip: 'Borrar último / seleccionado',
                ),
                IconButton(
                  onPressed: widget.onClear,
                  icon: const Icon(Icons.delete_forever),
                  tooltip: 'Borrar todo',
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                  tooltip: 'Cerrar',
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Grid de notas
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final count = (constraints.maxWidth ~/ 100).clamp(2, 6);
                    return GridView.count(
                      crossAxisCount: count,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.3,
                      children: _notas.map(_buildNotaButton).toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
