import 'package:flutter/material.dart';
import 'package:cancionero/modelo/cancion.dart';
import 'package:cancionero/servicio/servicio_almacenamiento.dart';
import 'package:cancionero/vista/gradient_scaffold.dart';
import 'package:cancionero/vista/teclado_notas.dart';
import 'package:cancionero/vista/validacion_notas.dart';
import 'dart:math';

class EditarCancionVista extends StatefulWidget {
  final ServicioAlmacenamiento almacenamiento;
  final Cancion? cancion;

  /// Callbacks opcionales para persistencia en la nube
  final Future<void> Function(Cancion)? onSave;
  final Future<void> Function(Cancion)? onUpdate;

  const EditarCancionVista({
    super.key,
    required this.almacenamiento,
    this.cancion,
    this.onSave,
    this.onUpdate,
  });

  @override
  State<EditarCancionVista> createState() => _EditarCancionVistaState();
}

class _EditarCancionVistaState extends State<EditarCancionVista> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controladorTitulo;
  late final TextEditingController _controladorNotas;
  int? _selectedIndex;

  // Cursor/posición actual (línea donde se insertará la nota)
  int _cursorLineIndex = 0;

  // Lista de índices de líneas seleccionadas para subtítulos (permite múltiples)
  final List<int> _selectedSubtitleLineIndices = [0];

  // Subtítulos por línea
  final List<TextEditingController> _controladoresSubtitulosLineas = [];

  @override
  void initState() {
    super.initState();
    _controladorTitulo = TextEditingController(
      text: widget.cancion?.titulo ?? '',
    );
    _controladorNotas = TextEditingController(
      text: widget.cancion?.notas ?? '',
    );

    // Inicializar controladores de subtítulos por línea a partir del modelo
    final initial = widget.cancion?.subtitulosLineas ?? [];
    for (var s in initial) {
      _controladoresSubtitulosLineas.add(TextEditingController(text: s));
    }

    // Mantener sincronizados los controladores de subtítulos con las líneas
    _controladorNotas.addListener(() {
      _ensureSubtitleControllers();
      _updateCursorLine();
      // Rebuild para mostrar/ocultar campos si cambió número de líneas
      setState(() {});
    });

    // Asegurarnos de que la cantidad de controladores coincida con las líneas
    _ensureSubtitleControllers();
    // Inicializar índice de línea de cursor
    _updateCursorLine();
  }

  @override
  void dispose() {
    _controladorTitulo.dispose();
    _controladorNotas.dispose();
    for (var c in _controladoresSubtitulosLineas) {
      c.dispose();
    }
    _controladoresSubtitulosLineas.clear();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final titulo = _controladorTitulo.text.trim();
    final notas = _controladorNotas.text.trim();
    final errorNotas = validarNotasTexto(notas);
    if (errorNotas != null) {
      // Mostrar error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorNotas)));
      return;
    }
    final id =
        widget.cancion?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Compilar lista de subtítulos por línea (manteniendo orden)
    final subtitlesLines = _controladoresSubtitulosLineas
        .map((c) => c.text.trim())
        .toList();
    final subtitlesLinesOrNull = subtitlesLines.every((s) => s.isEmpty)
        ? null
        : subtitlesLines;

    final cancion = Cancion(
      id: id,
      titulo: titulo,
      notas: notas,
      subtitulosLineas: subtitlesLinesOrNull,
      tamanoLetra: widget.cancion?.tamanoLetra ?? 22.0,
    );
    try {
      if (widget.cancion == null) {
        if (widget.onSave != null) {
          await widget.onSave!(cancion);
        } else {
          await widget.almacenamiento.agregarCancion(cancion);
        }
      } else {
        if (widget.onUpdate != null) {
          await widget.onUpdate!(cancion);
        } else {
          await widget.almacenamiento.actualizarCancion(cancion);
        }
      }
    } catch (e) {
      if (!mounted) return;
      // Mostrar mensaje amigable al usuario y no propagar la excepción al caller.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar la canción: $e')));
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String? _validarNotas(String? v) {
    // Reemplazada por la función reutilizable en `validacion_notas.dart`.
    return validarNotasTexto(v);
  }

  List<String> _getNotasTokens() {
    final text = _controladorNotas.text;
    if (text.trim().isEmpty) return [];
    return text
        .trim()
        .split(RegExp(r'\s*\-\s*|[\s,;]+'))
        .where((t) => t.isNotEmpty)
        .toList();
  }

  List<List<String>> _getTokensByLine() {
    final text = _controladorNotas.text;
    if (text.isEmpty) return [];
    final lines = text.split('\n');
    return lines
        .map(
          (line) {
            // Si la línea está vacía, devolver una lista vacía (pero seguir siendo una línea)
            if (line.trim().isEmpty) return <String>[];
            return line
                .trim()
                .split(RegExp(r'\s*\-\s*'))
                .where((t) => t.isNotEmpty)
                .toList();
          },
        )
        .toList();
  }

  String _normalizeNotasText(String text) {
    if (text.trim().isEmpty) return '';
    
    // Count trailing newlines to preserve them
    var trailingNewlineCount = 0;
    for (var i = text.length - 1; i >= 0; i--) {
      if (text[i] == '\n') {
        trailingNewlineCount++;
      } else {
        break;
      }
    }
    
    // Remove CR and tabs
    var s = text.replaceAll('\r', '').replaceAll('\t', ' ');
    
    // Split by lines BEFORE any other processing to preserve line structure
    final originalLines = s.split('\n');
    
    // Process each line individually
    final processedLines = originalLines.map((line) {
      var l = line.trim();
      if (l.isEmpty) {
        // Keep empty lines as empty
        return '';
      }
      // Remove CR and normalize separators
      l = l.replaceAll(RegExp(r'(\s*[\-;,]\s*)+'), ' - ');
      // Remove dangling separators
      l = l.replaceAll(RegExp(r'^(\s*[-,;]\s*)+'), '');
      l = l.replaceAll(RegExp(r'(\s*[-,;]\s*)+$'), '');
      // Collapse multiple spaces
      l = l.replaceAll(RegExp(r'\s+'), ' ');
      return l.trim();
    }).toList();
    
    // Find first and last non-empty lines to trim only the extremes
    var firstNonEmpty = 0;
    var lastNonEmpty = processedLines.length - 1;
    
    while (firstNonEmpty <= lastNonEmpty && processedLines[firstNonEmpty].isEmpty) {
      firstNonEmpty++;
    }
    while (lastNonEmpty >= firstNonEmpty && processedLines[lastNonEmpty].isEmpty) {
      lastNonEmpty--;
    }
    
    // Extract lines from first to last non-empty (preserving all internal lines, even empty ones)
    if (firstNonEmpty > lastNonEmpty) {
      // All empty
      return '';
    }
    
    s = processedLines.sublist(firstNonEmpty, lastNonEmpty + 1).join('\n');
    
    // Remove duplicate hyphens
    s = s.replaceAll(RegExp(r'\s*\-\s*\-\s*'), ' - ');
    
    // Restore trailing newlines exactly as they were in the original
    if (trailingNewlineCount > 0) {
      s = s + '\n' * trailingNewlineCount;
    }
    
    return s;
  }

  String _controllerSafeText() => _controladorNotas.text;

  void _ensureSubtitleControllers() {
    final lines = _getTokensByLine();
    final count = lines.length;
    // Preserve existing texts when possible
    final old = _controladoresSubtitulosLineas.map((c) => c.text).toList();
    // Resize controllers
    while (_controladoresSubtitulosLineas.length < count) {
      _controladoresSubtitulosLineas.add(TextEditingController());
    }
    while (_controladoresSubtitulosLineas.length > count) {
      _controladoresSubtitulosLineas.removeLast().dispose();
    }
    // Populate with previous values or model-provided subtitles (only if empty)
    final fromModel = widget.cancion?.subtitulosLineas ?? [];
    for (var i = 0; i < count; i++) {
      final ctrl = _controladoresSubtitulosLineas[i];
      if (i < old.length && old[i].isNotEmpty) {
        ctrl.text = old[i];
      } else if (ctrl.text.isEmpty) {
        ctrl.text = i < fromModel.length ? (fromModel[i] ?? '') : ctrl.text;
      }
    }
  }

  void _updateCursorLine() {
    final text = _controladorNotas.text;
    final sel = _controladorNotas.selection.baseOffset;
    final pos = (sel < 0) ? text.length : min(sel, text.length);
    final before = text.substring(0, pos);
    final newIndex = before.split('\n').length - 1;
    if (newIndex != _cursorLineIndex) {
      setState(() {
        _cursorLineIndex = newIndex;
      });
    }
  }

  void _mostrarTecladoNotas(BuildContext context, {int? selectedIndex}) {
    // Si se abrió el teclado con una nota seleccionada, actualizar la línea
    if (selectedIndex != null) {
      final lines = _getTokensByLine();
      var remaining = selectedIndex;
      var foundLine = 0;
      for (var i = 0; i < lines.length; i++) {
        if (remaining < lines[i].length) {
          foundLine = i;
          break;
        }
        remaining -= lines[i].length;
      }
      setState(() {
        _cursorLineIndex = foundLine;
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      builder: (c) => TecladoNotas(
        selectedIndex: selectedIndex,
        onInsert: (token) {
          var raw = _controladorNotas.text;
          // Normalize initial whitespace chars
          raw = raw.replaceAll(RegExp(r'[\t\r]+'), '');
          final hadNewline = raw.endsWith('\n');
          // Remove trailing spaces/tabs but keep a trailing newline if present
          var trimmed = raw.replaceFirst(RegExp(r'[ \t\r]+$'), '');

          if (token == ' ') {
            // Mantener compatibilidad: agregar espacio
            _controladorNotas.text = '$raw ';
            // normalize to avoid accidental duplicates
            _controladorNotas.text = _normalizeNotasText(_controllerSafeText());
            _controladorNotas.selection = TextSelection.collapsed(
              offset: _controladorNotas.text.length,
            );
            _selectedIndex = null;
            setState(() {});
            return;
          }

          if (token == '\n') {
            // Salto: eliminar separador al final si existe y añadir nueva línea
            var t = trimmed;
            if (t.endsWith(' - ')) {
              t = t.substring(0, t.length - 3).trimRight();
            }
            _controladorNotas.text = t.isEmpty ? '' : '$t\n';
            // normalize lines
            _controladorNotas.text = _normalizeNotasText(_controllerSafeText());
            setState(() {});
            return;
          }

          // Inserción de nota: preservar newline si existía
          if (hadNewline) {
            // Raw already ends with '\n', so append note after the newline
            var base = raw;
            _controladorNotas.text = '$base$token - ';
            _controladorNotas.text = _normalizeNotasText(_controllerSafeText());
            _controladorNotas.selection = TextSelection.collapsed(
              offset: _controladorNotas.text.length,
            );
            _selectedIndex = null;
            setState(() {});
            return;
          }

          // No trailing newline: use trimmed form
          var t = trimmed;
          if (t.isEmpty) {
            _controladorNotas.text = '$token - ';
          } else if (t.endsWith(' - ')) {
            // Ya hay separador, simplemente añadir nota
            _controladorNotas.text = '$t$token - ';
          } else {
            // No hay separador: añadir uno antes de la nota
            _controladorNotas.text = '$t - $token - ';
          }

          _controladorNotas.text = _normalizeNotasText(_controllerSafeText());
          _controladorNotas.selection = TextSelection.collapsed(
            offset: _controladorNotas.text.length,
          );
          _selectedIndex = null;
          setState(() {});
        },
        onReplaceAt: (index, token) {
          final text = _controladorNotas.text;
          // Match notes including optional accidental (# or b) and ensure the
          // accidental is consumed as part of the match (use lookahead for
          // separators/end instead of word boundary which can split on '#').
          final noteRegex = RegExp(
            r"(?:DO|RE|MI|FA|SOL|LA|SI)(?:#|b)?(?=$|[\s\-\n,;])",
            caseSensitive: false,
          );
          final matches = noteRegex.allMatches(text).toList();
          if (index >= 0 && index < matches.length) {
            final m = matches[index];
            // Replace only inside the line containing the match to avoid
            // affecting other lines and their separators/newlines.
            final textStr = text;
            final lines = textStr.split('\n');
            // Find which line contains the match
            var pos = 0;
            var lineIndex = 0;
            for (var i = 0; i < lines.length; i++) {
              final l = lines[i];
              if (m.start >= pos && m.start <= pos + l.length) {
                lineIndex = i;
                break;
              }
              pos += l.length + 1; // +1 for the '\n'
            }
            final localStart = m.start - pos;
            final localEnd = m.end - pos;
            var line = lines[lineIndex];
            // Perform replacement within the line
            var newLine =
                line.substring(0, localStart) +
                token +
                line.substring(localEnd);
            // Normalize the line only
            newLine = newLine.replaceAll(RegExp(r'\s+'), ' ');
            newLine = newLine.replaceAll(RegExp(r'(\s*[\-;,]\s*)+'), ' - ');
            newLine = newLine.replaceAll(RegExp(r'^\s*[-,;]\s*'), '');
            newLine = newLine.replaceAll(RegExp(r'(\s*[-,;]\s*)+\$'), '');
            newLine = newLine.trim();
            lines[lineIndex] = newLine;
            var nuevo = lines.join('\n');
            // Preserve trailing newline if original had one
            if (textStr.endsWith('\n') && !nuevo.endsWith('\n')) {
              nuevo = '$nuevo\n';
            }
            // Keep trailing space to facilitate further insertions (like before)
            _controladorNotas.text = nuevo.isNotEmpty ? '$nuevo ' : '';
            // Move caret to after the replaced token in the new text
            final newLocalStart = newLine.indexOf(token);
            final caretPos = (newLocalStart >= 0)
                ? (pos + newLocalStart + token.length)
                : min(m.start + token.length, (_controladorNotas.text.length));
            _controladorNotas.selection = TextSelection.collapsed(
              offset: min(caretPos, _controladorNotas.text.length),
            );
            // Deselect current selection
            _selectedIndex = null;
            setState(() {});
          }
        },
        onDeleteAt: (index) {
          final text = _controladorNotas.text;
          final noteRegex = RegExp(
            r"(?:DO|RE|MI|FA|SOL|LA|SI)(?:#|b)?(?=$|[\s\-\n,;])",
            caseSensitive: false,
          );
          final matches = noteRegex.allMatches(text).toList();
          if (index >= 0 && index < matches.length) {
            final m = matches[index];
            // Delete only the matched note and normalize the affected line,
            // preserving newlines and other lines intact.
            final textStr = text;
            final lines = textStr.split('\n');
            // Find which line contains the match
            var pos = 0;
            var lineIndex = 0;
            for (var i = 0; i < lines.length; i++) {
              final l = lines[i];
              if (m.start >= pos && m.start <= pos + l.length) {
                lineIndex = i;
                break;
              }
              pos += l.length + 1; // +1 for the '\n'
            }
            final localStart = m.start - pos;
            final localEnd = m.end - pos;
            final line = lines[lineIndex];
            var newLine =
                line.substring(0, localStart) + line.substring(localEnd);
            // Normalize inside the line but DO NOT remove newlines
            newLine = newLine.replaceAll(RegExp(r'\s+'), ' ');
            newLine = newLine.replaceAll(RegExp(r'(\s*[\-;,]\s*)+'), ' - ');
            newLine = newLine.replaceAll(RegExp(r'^\s*[-,;]\s*'), '');
            newLine = newLine.replaceAll(RegExp(r'\s*[-,;]\s*\$'), '');
            newLine = newLine.trim();
            lines[lineIndex] = newLine;
            
            // Remove trailing empty lines one by one when we delete from the last line
            // This ensures the line count (X/Y) stays accurate
            while (lines.isNotEmpty && lineIndex >= lines.length - 1 && lines.last.trim().isEmpty) {
              lines.removeLast();
              lineIndex = lines.length - 1;
            }
            
            var nuevo = lines.join('\n');
            // Preserve trailing newline if original had one
            if (textStr.endsWith('\n') && !nuevo.endsWith('\n')) {
              nuevo = '$nuevo\n';
            }
            // Keep trailing space to facilitate further insertions like before
            _controladorNotas.text = nuevo.isNotEmpty ? '$nuevo ' : '';
            _controladorNotas.selection = TextSelection.collapsed(
              offset: _controladorNotas.text.length,
            );
            _selectedIndex = null;
            // Recalculate which line the cursor is on
            _updateCursorLine();
            setState(() {});
          }
        },
        onBackspace: () {
          var text = _controladorNotas.text;
          if (text.isEmpty) return;

          final hadTrailingNewline = text.endsWith('\n');
          final lines = text.split('\n');
          var lastIndex = lines.length - 1;

          // If last line is empty, remove it and continue on previous line
          // This behaves like a real keyboard: backspace on empty line deletes the line
          if (lines[lastIndex].trim().isEmpty) {
            if (lastIndex == 0) {
              // nothing to remove
              return;
            }
            lines.removeAt(lastIndex);
            lastIndex = lines.length - 1;
            
            // After removing the empty line, recursively handle the previous line
            var nuevo = lines.join('\n');
            if (hadTrailingNewline && !nuevo.endsWith('\n')) {
              nuevo = '$nuevo\n';
            }
            _controladorNotas.text = nuevo.isNotEmpty ? '$nuevo ' : '';
            _controladorNotas.selection = TextSelection.collapsed(
              offset: _controladorNotas.text.length,
            );
            _updateCursorLine();
            setState(() {});
            return;
          }

          var lastLine = lines[lastIndex];

          // Find last note in lastLine; if none, try previous non-empty line
          final noteRegex = RegExp(
            r"(?:DO|RE|MI|FA|SOL|LA|SI)(?:#|b)?(?=$|[\s\-\n,;])",
            caseSensitive: false,
          );
          var matches = noteRegex.allMatches(lastLine).toList();
          if (matches.isEmpty) {
            // try previous lines
            var found = false;
            for (var i = lastIndex - 1; i >= 0; i--) {
              if (lines[i].trim().isEmpty) continue;
              final mm = noteRegex.allMatches(lines[i]).toList();
              if (mm.isNotEmpty) {
                lastIndex = i;
                lastLine = lines[i];
                matches = mm;
                found = true;
                break;
              }
            }
            if (!found) return; // nothing to delete anywhere
          }

          final m = matches.last;
          var newLine =
              lastLine.substring(0, m.start) + lastLine.substring(m.end);
          // Normalize only the affected line
          newLine = newLine.replaceAll(RegExp(r'\s+'), ' ');
          newLine = newLine.replaceAll(RegExp(r'(\s*[\-;,]\s*)+'), ' - ');
          newLine = newLine.replaceAll(RegExp(r'^\s*[-,;]\s*'), '');
          newLine = newLine.replaceAll(RegExp(r'(\s*[-,;]\s*)+\$'), '');
          newLine = newLine.trim();

          lines[lastIndex] = newLine;
          var nuevo = lines.join('\n');
          if (hadTrailingNewline && !nuevo.endsWith('\n')) nuevo = '$nuevo\n';

          _controladorNotas.text = nuevo.isNotEmpty ? '$nuevo ' : '';
          _controladorNotas.selection = TextSelection.collapsed(
            offset: _controladorNotas.text.length,
          );
          _updateCursorLine();
          setState(() {});
        },
        onClear: () {
          _controladorNotas.clear();
          setState(() {});
        },
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.cancion != null;
    return GradientScaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar canción' : 'Agregar canción'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _controladorTitulo,
                decoration: const InputDecoration(
                  labelText: 'Título de la canción',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El título es requerido'
                    : null,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      _mostrarTecladoNotas(context, selectedIndex: null),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Builder(
                      builder: (context) {
                        final lines = _getTokensByLine();
                        final totalLines = lines.isEmpty ? 1 : lines.length;
                        final currentLine = _cursorLineIndex.clamp(
                          0,
                          totalLines - 1,
                        );
                        return Stack(
                          children: [
                            _controladorNotas.text.isEmpty
                                ? const Text('Notas musicales (usar teclado)')
                                : SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: () {
                                        var flatIndex = 0;
                                        final widgets = <Widget>[];
                                        final totalLines =
                                            lines.isEmpty ? 1 : lines.length;

                                        for (
                                          var lineIndex = 0;
                                          lineIndex < lines.length;
                                          lineIndex++
                                        ) {
                                          final tokens = lines[lineIndex];
                                          widgets.add(
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8.0,
                                              ),
                                              child: Container(
                                                decoration:
                                                    lineIndex == currentLine
                                                    ? BoxDecoration(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.08),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      )
                                                    : null,
                                                padding:
                                                    lineIndex == currentLine
                                                    ? const EdgeInsets.all(6.0)
                                                    : null,
                                                child: Wrap(
                                                  spacing: 8.0,
                                                  runSpacing: 8.0,
                                                  children: () {
                                                    final children = <Widget>[];
                                                    for (
                                                      var i = 0;
                                                      i < tokens.length;
                                                      i++
                                                    ) {
                                                      final token = tokens[i];
                                                      final idx = flatIndex++;
                                                      final selected =
                                                          _selectedIndex == idx;
                                                      children.add(
                                                        ChoiceChip(
                                                          label: Text(token),
                                                          selected: selected,
                                                          onSelected: (s) {
                                                            setState(
                                                              () =>
                                                                  _selectedIndex =
                                                                      s
                                                                      ? idx
                                                                      : null,
                                                            );
                                                            if (s) {
                                                              _mostrarTecladoNotas(
                                                                context,
                                                                selectedIndex:
                                                                    idx,
                                                              );
                                                            }
                                                          },
                                                        ),
                                                      );
                                                      if (i <
                                                          tokens.length - 1) {
                                                        children.add(
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      6.0,
                                                                ),
                                                            child: Text(
                                                              ' - ',
                                                              style:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .textTheme
                                                                      .bodyLarge
                                                                      ?.copyWith(
                                                                        fontSize:
                                                                            16,
                                                                      ),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                    return children;
                                                  }(),
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        // Subtítulos por línea (múltiples secciones)
                                        _ensureSubtitleControllers();
                                        widgets.add(
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 16.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    const Text(
                                                      'Subtítulos por línea:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          // Agregar nuevo índice si hay líneas disponibles
                                                          if (_selectedSubtitleLineIndices
                                                                  .length <
                                                              totalLines) {
                                                            _selectedSubtitleLineIndices
                                                                .add(0);
                                                          }
                                                        });
                                                      },
                                                      icon: const Icon(
                                                          Icons.add_circle),
                                                      tooltip:
                                                          'Agregar subtítulo',
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                // Generar una sección por cada subtítulo seleccionado
                                                ..._selectedSubtitleLineIndices
                                                    .asMap()
                                                    .entries
                                                    .map((entry) {
                                                  final sectionIndex =
                                                      entry.key;
                                                  final selectedLineIndex =
                                                      entry.value;

                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 12.0),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12.0),
                                                      decoration:
                                                          BoxDecoration(
                                                        border: Border.all(
                                                            color: Colors
                                                                .grey[400]!),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Expanded(
                                                                child:
                                                                    DropdownButton<
                                                                        int>(
                                                                  isExpanded:
                                                                      true,
                                                                  value: selectedLineIndex
                                                                      .clamp(
                                                                          0,
                                                                          totalLines -
                                                                              1),
                                                                  onChanged:
                                                                      (value) {
                                                                    if (value !=
                                                                        null) {
                                                                      setState(
                                                                          () {
                                                                        _selectedSubtitleLineIndices[
                                                                            sectionIndex] =
                                                                            value;
                                                                      });
                                                                    }
                                                                  },
                                                                  items: List
                                                                      .generate(
                                                                    totalLines,
                                                                    (index) =>
                                                                        DropdownMenuItem<
                                                                            int>(
                                                                      value:
                                                                          index,
                                                                      child: Text(
                                                                        'Línea ${index + 1}',
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              IconButton(
                                                                onPressed: () {
                                                                  setState(() {
                                                                    if (_selectedSubtitleLineIndices
                                                                            .length >
                                                                        1) {
                                                                      _selectedSubtitleLineIndices
                                                                          .removeAt(
                                                                              sectionIndex);
                                                                    }
                                                                  });
                                                                },
                                                                icon: const Icon(
                                                                  Icons
                                                                      .remove_circle,
                                                                  color: Colors
                                                                      .red,
                                                                ),
                                                                tooltip:
                                                                    'Eliminar',
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 8),
                                                          TextFormField(
                                                            controller: selectedLineIndex <
                                                                    _controladoresSubtitulosLineas
                                                                        .length
                                                                ? _controladoresSubtitulosLineas[
                                                                    selectedLineIndex]
                                                                : TextEditingController(),
                                                            decoration:
                                                                InputDecoration(
                                                              labelText:
                                                                  'Subtítulo para línea ${selectedLineIndex + 1}',
                                                              hintText:
                                                                  'Ej: Do – la - si',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ],
                                            ),
                                          ),
                                        );

                                        return widgets;
                                      }(),
                                    ),
                                  ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Chip(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                                label: Text(
                                  'Línea ${currentLine + 1}/$totalLines',
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
