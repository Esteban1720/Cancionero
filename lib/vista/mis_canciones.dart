import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MisCancionesVista extends StatefulWidget {
  const MisCancionesVista({super.key});

  @override
  State<MisCancionesVista> createState() => _MisCancionesVistaState();
}

class _MisCancionesVistaState extends State<MisCancionesVista> {
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

  static const Map<String, List<int>> _intervalosEscala = {
    'Mayor': [0, 2, 4, 5, 7, 9, 11],
    'Menor': [0, 2, 3, 5, 7, 8, 10],
  };

  String? _cancionSeleccionadaId;
  int _bloquesIdSeed = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No hay sesion iniciada')),
      );
    }

    final cancionesRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('canciones')
        .orderBy('actualizado_en', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Canciones')),
      body: StreamBuilder<QuerySnapshot>(
        stream: cancionesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('No se pudieron cargar las canciones'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final canciones = snapshot.data!.docs;

          if (canciones.isEmpty) {
            return _vistaVacia(user.uid);
          }
          return _panelListaCanciones(user.uid, canciones);
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'fab-recibidas',
            onPressed: () {
              Navigator.of(context).pushNamed('/canciones-recibidas');
            },
            icon: const Icon(Icons.inbox_outlined),
            label: const Text('Canciones recibidas'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'fab-nueva-cancion',
            onPressed: () => _abrirEditorCancion(user.uid),
            icon: const Icon(Icons.queue_music),
            label: const Text('Nueva cancion'),
          ),
        ],
      ),
    );
  }

  Widget _vistaVacia(String uid) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 241, 219),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.library_music, size: 62),
            ),
            const SizedBox(height: 18),
            const Text(
              'Guarda tus canciones con notas latinas, subtitulos y cambios de tono.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const Text(
              'Crea una cancion, agrega partes como intro o coro y luego visualizala con el tamano que necesites.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _panelListaCanciones(
    String uid,
    List<QueryDocumentSnapshot> canciones,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: canciones.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final doc = canciones[index];
        final data = doc.data() as Map<String, dynamic>;
        final bloques = _parsearBloques(data['bloques']);
        final totalNotas = bloques.fold<int>(
          0,
          (total, bloque) => total + bloque.notas.length,
        );

        return Card(
          color: _cancionSeleccionadaId == doc.id
              ? const Color.fromARGB(255, 232, 244, 255)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    setState(() {
                      _cancionSeleccionadaId = doc.id;
                    });
                    _abrirVisualizacion(doc);
                  },
                  leading: CircleAvatar(
                    backgroundColor: const Color.fromARGB(255, 255, 228, 186),
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    data['titulo'] ?? 'Cancion sin titulo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${bloques.length} secciones - $totalNotas notas',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
                _accionesCancion(uid, doc),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _abrirVisualizacion(QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    await Navigator.of(context).pushNamed(
      '/ver-cancion',
      arguments: {
        'titulo': data['titulo'] ?? 'Cancion sin titulo',
        'bloques': List<Map<String, dynamic>>.from(
          ((data['bloques'] as List?) ?? const []).map(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        ),
        'actualizadoEn': data['actualizado_en'],
      },
    );
  }

  Widget _accionesCancion(
    String uid,
    QueryDocumentSnapshot doc,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => _abrirVisualizacion(doc),
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Ver'),
        ),
        OutlinedButton.icon(
          onPressed: () => _abrirEditorCancion(uid, doc: doc),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar'),
        ),
        ElevatedButton.icon(
          onPressed: () => _compartirCancion(uid, doc),
          icon: const Icon(Icons.share_outlined),
          label: const Text('Compartir'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade300,
          ),
          onPressed: () => _eliminarCancion(uid, doc),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Eliminar'),
        ),
      ],
    );
  }

  Future<void> _abrirEditorCancion(
    String uid, {
    QueryDocumentSnapshot? doc,
  }) async {
    final dataActual = doc?.data() as Map<String, dynamic>?;
    var titulo = dataActual?['titulo'] ?? '';
    final bloquesIniciales = doc == null
        ? [_EditorBloque(id: _nextBloqueId(), subtitulo: 'Intro', notas: [])]
        : _parsearBloques(dataActual?['bloques'])
            .map((bloque) => _EditorBloque.fromBloque(bloque))
            .toList();
    var bloques = bloquesIniciales.isEmpty
        ? <_EditorBloque>[
            _EditorBloque(id: _nextBloqueId(), subtitulo: 'Intro', notas: []),
          ]
        : bloquesIniciales;
    var indiceSeleccionado = 0;
    var tonalidad = 'Do';
    var modo = 'Mayor';
    var guardando = false;
    var cerrandoModal = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final notasEscala = _notasDeEscala(tonalidad, modo);

            void agregarBloque() {
              setModalState(() {
                bloques = [
                  ...bloques,
                  _EditorBloque(
                    id: _nextBloqueId(),
                    subtitulo: 'Seccion ${bloques.length + 1}',
                    notas: [],
                  ),
                ];
                indiceSeleccionado = bloques.length - 1;
              });
            }

            Future<void> guardarCancion() async {
              final tituloLimpio = titulo.trim();

              if (tituloLimpio.isEmpty) {
                _mostrarMensaje('Escribe un titulo para la cancion');
                return;
              }

              final datos = <String, dynamic>{
                'titulo': tituloLimpio,
                'bloques': bloques
                    .map(
                      (bloque) => {
                        'subtitulo': bloque.subtitulo.trim(),
                        'notas': bloque.notas,
                      },
                    )
                    .toList(),
                'actualizado_en': FieldValue.serverTimestamp(),
              };

              setModalState(() {
                guardando = true;
              });

              try {
                if (doc == null) {
                  datos['creado_en'] = FieldValue.serverTimestamp();
                  final nuevoDoc = await FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(uid)
                      .collection('canciones')
                      .add(datos);

                  if (mounted) {
                    setState(() {
                      _cancionSeleccionadaId = nuevoDoc.id;
                    });
                  }
                } else {
                  await FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(uid)
                      .collection('canciones')
                      .doc(doc.id)
                      .update(datos);

                  if (mounted) {
                    setState(() {
                      _cancionSeleccionadaId = doc.id;
                    });
                  }
                }

                if (!context.mounted) {
                  return;
                }

                cerrandoModal = true;
                Navigator.pop(context);
                _mostrarMensaje('Cancion guardada correctamente');
              } on FirebaseException catch (e) {
                _mostrarMensaje(
                  'Firebase: ${e.message ?? e.code}',
                );
              } catch (e) {
                _mostrarMensaje('Error al guardar: $e');
              } finally {
                if (context.mounted && !cerrandoModal) {
                  setModalState(() {
                    guardando = false;
                  });
                }
              }
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  doc == null
                                      ? 'Nueva cancion'
                                      : 'Editar cancion',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: ValueKey('titulo_${doc?.id ?? 'nueva'}'),
                            initialValue: titulo,
                            decoration: const InputDecoration(
                              labelText: 'Titulo',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              titulo = value;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: tonalidad,
                                  decoration: const InputDecoration(
                                    labelText: 'Tonalidad',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _notasCromaticas
                                      .map(
                                        (nota) => DropdownMenuItem(
                                          value: nota,
                                          child: Text(nota),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) {
                                      return;
                                    }
                                    setModalState(() {
                                      tonalidad = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: modo,
                                  decoration: const InputDecoration(
                                    labelText: 'Escala',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _intervalosEscala.keys
                                      .map(
                                        (item) => DropdownMenuItem(
                                          value: item,
                                          child: Text(item),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) {
                                      return;
                                    }
                                    setModalState(() {
                                      modo = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Teclado musical de la escala $tonalidad $modo',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: notasEscala
                                .map(
                                  (nota) => ElevatedButton(
                                    onPressed: () {
                                      setModalState(() {
                                        bloques[indiceSeleccionado].notas = [
                                          ...bloques[indiceSeleccionado].notas,
                                          nota,
                                        ];
                                      });
                                    },
                                    child: Text(nota),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Secciones',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: agregarBloque,
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar seccion'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(bloques.length, (index) {
                            final bloque = bloques[index];
                            return _EditorBloqueCard(
                              key: ValueKey(bloque.id),
                              bloque: bloque,
                              seleccionado: indiceSeleccionado == index,
                              onTap: () {
                                setModalState(() {
                                  indiceSeleccionado = index;
                                });
                              },
                              onSubtituloChanged: (value) {
                                bloque.subtitulo = value;
                              },
                              onEliminarUltimaNota: bloque.notas.isEmpty
                                  ? null
                                  : () {
                                      setModalState(() {
                                        bloque.notas = bloque.notas.sublist(
                                          0,
                                          bloque.notas.length - 1,
                                        );
                                      });
                                    },
                              onEliminarSeccion: bloques.length == 1
                                  ? null
                                  : () {
                                      setModalState(() {
                                        bloques = bloques
                                            .asMap()
                                            .entries
                                            .where(
                                              (item) => item.key != index,
                                            )
                                            .map((item) => item.value)
                                            .toList();
                                        if (indiceSeleccionado >=
                                            bloques.length) {
                                          indiceSeleccionado =
                                              bloques.length - 1;
                                        }
                                      });
                                    },
                              onEliminarNota: (posicion) {
                                setModalState(() {
                                  bloque.notas = bloque.notas
                                      .asMap()
                                      .entries
                                      .where((item) => item.key != posicion)
                                      .map((item) => item.value)
                                      .toList();
                                });
                              },
                            );
                          }),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: guardando ? null : guardarCancion,
                              icon: guardando
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                guardando
                                    ? 'Guardando...'
                                    : (doc == null
                                          ? 'Guardar cancion'
                                          : 'Actualizar'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _eliminarCancion(
    String uid,
    QueryDocumentSnapshot doc,
  ) async {
    final data = doc.data() as Map<String, dynamic>;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar cancion'),
          content: Text(
            'Se eliminara "${data['titulo'] ?? 'esta cancion'}". Esta accion no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade300,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmado != true) {
      return;
    }

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('canciones')
        .doc(doc.id)
        .delete();

    if (!mounted) {
      return;
    }

    if (_cancionSeleccionadaId == doc.id) {
      setState(() {
        _cancionSeleccionadaId = null;
      });
    }

    _mostrarMensaje('Cancion eliminada');
  }

  Future<void> _compartirCancion(
    String uid,
    QueryDocumentSnapshot doc,
  ) async {
    final data = doc.data() as Map<String, dynamic>;
    final amigos = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .collection('amigos')
        .orderBy('nombre')
        .get();

    if (!mounted) {
      return;
    }

    if (amigos.docs.isEmpty) {
      _mostrarMensaje('No tienes amigos agregados para compartir');
      return;
    }

    final amigoSeleccionado = await showModalBottomSheet<QueryDocumentSnapshot>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  'Compartir con un amigo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...amigos.docs.map((amigoDoc) {
                final amigo = amigoDoc.data() as Map<String, dynamic>;
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(amigo['nombre'] ?? 'Amigo'),
                  subtitle: Text(data['titulo'] ?? 'Cancion'),
                  onTap: () => Navigator.pop(context, amigoDoc),
                );
              }),
            ],
          ),
        );
      },
    );

    if (amigoSeleccionado == null) {
      return;
    }

    final miDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();
    final misDatos = miDoc.data() ?? {};

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(amigoSeleccionado.id)
        .collection('canciones_recibidas')
        .add({
          'titulo': data['titulo'] ?? 'Cancion sin titulo',
          'bloques': List<Map<String, dynamic>>.from(
            ((data['bloques'] as List?) ?? const []).map(
              (item) => Map<String, dynamic>.from(item as Map),
            ),
          ),
          'remitente_uid': uid,
          'remitente_nombre': misDatos['user'] ?? 'Usuario',
          'cancion_origen_id': doc.id,
          'fecha_compartida': FieldValue.serverTimestamp(),
        });

    _mostrarMensaje('Cancion compartida correctamente');
  }

  List<String> _notasDeEscala(String tonalidad, String modo) {
    final indexBase = _indiceNota(tonalidad);
    final intervalos = _intervalosEscala[modo] ?? _intervalosEscala['Mayor']!;

    return intervalos
        .map((intervalo) => _notasCromaticas[(indexBase + intervalo) % 12])
        .toList();
  }

  int _indiceNota(String nota) {
    final normalizada = _equivalencias[nota] ?? nota;
    final indice = _notasCromaticas.indexOf(normalizada);
    return indice < 0 ? 0 : indice;
  }

  List<_BloqueCancion> _parsearBloques(dynamic valor) {
    final lista = valor is List ? valor : const [];
    return lista.map((item) {
      final mapa = item is Map<String, dynamic>
          ? item
          : Map<String, dynamic>.from(item as Map);
      final notas = mapa['notas'] is List
          ? List<String>.from((mapa['notas'] as List).map((e) => '$e'))
          : <String>[];

      return _BloqueCancion(
        subtitulo: '${mapa['subtitulo'] ?? ''}',
        notas: notas,
      );
    }).toList();
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  String _nextBloqueId() {
    _bloquesIdSeed++;
    return 'bloque_$_bloquesIdSeed';
  }
}

class _EditorBloqueCard extends StatelessWidget {
  const _EditorBloqueCard({
    super.key,
    required this.bloque,
    required this.seleccionado,
    required this.onTap,
    required this.onSubtituloChanged,
    required this.onEliminarNota,
    this.onEliminarUltimaNota,
    this.onEliminarSeccion,
  });

  final _EditorBloque bloque;
  final bool seleccionado;
  final VoidCallback onTap;
  final ValueChanged<String> onSubtituloChanged;
  final ValueChanged<int> onEliminarNota;
  final VoidCallback? onEliminarUltimaNota;
  final VoidCallback? onEliminarSeccion;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: seleccionado
          ? const Color.fromARGB(255, 237, 247, 255)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('subtitulo_${bloque.id}'),
                    initialValue: bloque.subtitulo,
                    decoration: InputDecoration(
                      labelText: 'Subtitulo de la seccion',
                      suffixIcon: seleccionado
                          ? const Icon(Icons.piano)
                          : null,
                    ),
                    onChanged: onSubtituloChanged,
                    onTap: onTap,
                  ),
                ),
                IconButton(
                  tooltip: 'Seleccionar',
                  onPressed: onTap,
                  icon: const Icon(Icons.check_circle_outline),
                ),
                IconButton(
                  tooltip: 'Borrar ultima nota',
                  onPressed: onEliminarUltimaNota,
                  icon: const Icon(Icons.backspace),
                ),
                IconButton(
                  tooltip: 'Eliminar seccion',
                  onPressed: onEliminarSeccion,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (bloque.notas.isEmpty)
              const Text('Todavia no hay notas')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: bloque.notas
                    .asMap()
                    .entries
                    .map(
                      (entry) => InputChip(
                        label: Text(entry.value),
                        onDeleted: () => onEliminarNota(entry.key),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _BloqueCancion {
  const _BloqueCancion({
    required this.subtitulo,
    required this.notas,
  });

  final String subtitulo;
  final List<String> notas;
}

class _EditorBloque {
  _EditorBloque({
    required this.id,
    required this.subtitulo,
    required this.notas,
  });

  factory _EditorBloque.fromBloque(_BloqueCancion bloque) {
    return _EditorBloque(
      id: 'bloque_${DateTime.now().microsecondsSinceEpoch}_${bloque.subtitulo.hashCode}_${bloque.notas.length}',
      subtitulo: bloque.subtitulo,
      notas: List<String>.from(bloque.notas),
    );
  }

  final String id;
  String subtitulo;
  List<String> notas;
}
