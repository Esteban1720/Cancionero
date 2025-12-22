import 'package:flutter/material.dart';
import 'package:cancionero/modelo/cancion.dart';
import 'package:cancionero/servicio/servicio_almacenamiento.dart';
import 'dart:io';

import 'package:cancionero/vista/gradient_scaffold.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:cancionero/vista/tema.dart';
import 'detalle_cancion_vista.dart';
import 'editar_cancion_vista.dart';

class ListaCancionesVista extends StatefulWidget {
  const ListaCancionesVista({super.key});

  @override
  State<ListaCancionesVista> createState() => _ListaCancionesVistaState();
}

class _ListaCancionesVistaState extends State<ListaCancionesVista> {
  final ServicioAlmacenamiento almacenamiento = ServicioAlmacenamiento();
  late Future<List<Cancion>> _cancionesFuturo;
  final TextEditingController _controladorBusqueda = TextEditingController();
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarCanciones();
  }

  void _cargarCanciones() {
    _cancionesFuturo = almacenamiento.cargarCanciones();
  }

  Future<void> _refrescar() async {
    if (!mounted) return;
    setState(() {
      _cargarCanciones();
    });
  }

  void _irAgregarCancion() async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (c) => EditarCancionVista(almacenamiento: almacenamiento),
      ),
    );
    if (!mounted) return;
    if (resultado == true) _refrescar();
  }

  Future<void> _guardarArchivosUsuario() async {
    if (!await _ensureStoragePermission()) return;

    // Elegir carpeta donde guardar usando FilePicker (directory picker)
    String? selectedDirectory;
    try {
      selectedDirectory = await FilePicker.platform.getDirectoryPath();
    } catch (e) {
      selectedDirectory = null;
    }
    if (selectedDirectory == null) return; // usuario canceló

    // Pedir nombre de archivo al usuario
    final filenameController = TextEditingController(
      text:
          'canciones_${DateTime.now().toIso8601String().replaceAll(':', '-')}.txt',
    );
    final save = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Guardar archivo'),
        content: TextField(
          controller: filenameController,
          decoration: const InputDecoration(labelText: 'Nombre de archivo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (save != true) return;
    var filename = filenameController.text.trim();
    if (filename.isEmpty) filename = 'canciones.txt';
    if (!filename.toLowerCase().endsWith('.txt')) filename = '$filename.txt';

    final pathSaved = await almacenamiento.guardarCancionesEnRuta(
      selectedDirectory,
      filename,
    );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (pathSaved != null) {
      messenger.showSnackBar(
        SnackBar(content: Text('Archivo guardado: $pathSaved')),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Error al guardar el archivo')),
      );
    }
  }

  Future<void> _cargarDesdeArchivo() async {
    if (!await _ensureStoragePermission()) return;
    // Seleccionar archivo (txt o json)
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'json'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return; // cancelado
    final filePath = result.files.single.path;
    if (filePath == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cargar canciones'),
        content: const Text(
          'Esto reemplazará las canciones actuales con las del archivo seleccionado. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Cargar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmar != true) return;

    final ok = await almacenamiento.cargarDesdeArchivo(filePath);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      await _refrescar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Importación completada')),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Error al importar desde el archivo')),
      );
    }
  }

  Future<bool> _ensureStoragePermission() async {
    // On Android we try MANAGE_EXTERNAL_STORAGE first (Android 11+), then fall back to STORAGE.
    if (!Platform.isAndroid) return true;

    // If already granted, return true
    if (await Permission.manageExternalStorage.isGranted) return true;
    if (await Permission.storage.isGranted) return true;

    // Request manage external storage first (on Android 11 this opens special dialog)
    final manageStatus = await Permission.manageExternalStorage.request();
    if (manageStatus.isGranted) return true;

    final status = await Permission.storage.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied || status.isDenied) {
      if (!mounted) return false;
      final open = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Permiso necesario'),
          content: const Text(
            'Para exportar/importar canciones se requiere acceso al almacenamiento. ¿Abrir configuración para habilitarlo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Abrir ajustes'),
            ),
          ],
        ),
      );
      if (open == true) {
        await openAppSettings();
      }
    }
    return false;
  }

  void _irVerCancion(Cancion cancion) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (c) => DetalleCancionVista(
          cancion: cancion,
          almacenamiento: almacenamiento,
        ),
      ),
    );
    if (!mounted) return;
    if (resultado == true) _refrescar();
  }

  @override
  void dispose() {
    _controladorBusqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Mis canciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Guardar',
            onPressed: _guardarArchivosUsuario,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Cargar canciones',
            onPressed: _cargarDesdeArchivo,
          ),
        ],
      ),
      body: FutureBuilder<List<Cancion>>(
        future: _cancionesFuturo,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final todasCanciones = snapshot.data ?? [];
          final cancionesFiltradas = _busqueda.isEmpty
              ? todasCanciones
              : todasCanciones
                    .where(
                      (s) => s.titulo.toLowerCase().contains(
                        _busqueda.toLowerCase(),
                      ),
                    )
                    .toList();
          return Column(
            children: [
              const SizedBox(height: 12),
              SafeArea(
                child: Column(
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/logo.png',
                        width: 220,
                        height: 220,
                        semanticLabel: 'Logo Cancionero',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
                      child: Text(
                        'Mis canciones',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    // Buscador
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      child: TextField(
                        controller: _controladorBusqueda,
                        onChanged: (v) => setState(() => _busqueda = v.trim()),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white70,
                          ),
                          hintText: 'Buscar canción por título',
                          hintStyle: TextStyle(
                            color: Colors.white.withAlpha(204),
                          ),
                          filled: true,
                          fillColor: kDarkBlue.withAlpha(40),
                          suffixIcon: _busqueda.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _busqueda = '';
                                      _controladorBusqueda.clear();
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: todasCanciones.isEmpty
                    ? Center(
                        child: Text(
                          'No hay canciones. Usa el botón + para agregar una.',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : cancionesFiltradas.isEmpty
                    ? Center(
                        child: Text(
                          'No se encontraron canciones que coincidan con tu búsqueda.',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: cancionesFiltradas.length,
                        itemBuilder: (context, index) {
                          final cancion = cancionesFiltradas[index];
                          final cardBg = kLightBlue.withAlpha(36);
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 6.0,
                            ),
                            child: Card(
                              color: cardBg,
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                title: Text(
                                  cancion.titulo,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                onTap: () => _irVerCancion(cancion),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _irAgregarCancion,
        tooltip: 'Agregar canción',
        child: const Icon(Icons.add),
      ),
    );
  }
}
