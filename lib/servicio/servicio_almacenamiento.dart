import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:cancionero/modelo/cancion.dart';

class ServicioAlmacenamiento {
  static const _nombreArchivo = 'canciones.txt';

  Future<File> _obtenerArchivoLocal() async {
    // Intentar guardar en carpeta pública Documents (persistente tras desinstalar)
    try {
      if (Platform.isAndroid) {
        final docs = await getExternalStorageDirectories(
          type: StorageDirectory.documents,
        );
        if (docs != null && docs.isNotEmpty) {
          final dir = Directory(path.join(docs.first.path, 'Cancionero'));
          if (!await dir.exists()) await dir.create(recursive: true);
          return File(path.join(dir.path, _nombreArchivo));
        }
      }
    } catch (_) {
      // Ignorar y usar fallback
    }

    // Fallback: almacenamiento interno de la app
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(path.join(appDir.path, 'Cancionero'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return File(path.join(dir.path, _nombreArchivo));
  }

  Future<List<Cancion>> cargarCanciones() async {
    try {
      final file = await _obtenerArchivoLocal();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      return Cancion.listaDesdeJson(content);
    } catch (e) {
      return [];
    }
  }

  Future<void> guardarCanciones(List<Cancion> canciones) async {
    final file = await _obtenerArchivoLocal();
    final content = Cancion.listaAJson(canciones);
    await file.writeAsString(content, flush: true);
  }

  /// Exportar una copia de seguridad a la carpeta Downloads/Cancionero/backups (o a Documents si downloads no disponible).
  /// Devuelve la ruta del archivo exportado o null en caso de error.
  Future<String?> exportarCancionesASD() async {
    try {
      final canciones = await cargarCanciones();
      final content = Cancion.listaAJson(canciones);
      Directory dir;
      final downloads = await getExternalStorageDirectories(
        type: StorageDirectory.downloads,
      );
      if (downloads != null && downloads.isNotEmpty) {
        dir = Directory(
          path.join(downloads.first.path, 'Cancionero', 'backups'),
        );
      } else {
        final appDoc = await getApplicationDocumentsDirectory();
        dir = Directory(path.join(appDoc.path, 'backups'));
      }
      if (!await dir.exists()) await dir.create(recursive: true);
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File(
        path.join(dir.path, 'canciones_backup_$timestamp.json'),
      );
      await file.writeAsString(content, flush: true);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Importar la copia de seguridad más reciente desde Downloads/Cancionero/backups
  Future<bool> importarUltimaCopiaDesdeSD() async {
    try {
      Directory dir;
      final downloads = await getExternalStorageDirectories(
        type: StorageDirectory.downloads,
      );
      if (downloads != null && downloads.isNotEmpty) {
        dir = Directory(
          path.join(downloads.first.path, 'Cancionero', 'backups'),
        );
      } else {
        final appDoc = await getApplicationDocumentsDirectory();
        dir = Directory(path.join(appDoc.path, 'backups'));
      }
      if (!await dir.exists()) return false;
      final files = await dir
          .list()
          .where((e) => e is File && e.path.toLowerCase().endsWith('.json'))
          .toList();
      if (files.isEmpty) return false;
      files.sort(
        (a, b) => (b as File).lastModifiedSync().compareTo(
          (a as File).lastModifiedSync(),
        ),
      );
      final latest = files.first as File;
      final content = await latest.readAsString();
      final lista = Cancion.listaDesdeJson(content);
      await guardarCanciones(lista);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Guardar canciones a la ruta custom seleccionada (directory path + filename)
  Future<String?> guardarCancionesEnRuta(
    String directoryPath,
    String filename,
  ) async {
    try {
      final canciones = await cargarCanciones();
      final content = Cancion.listaAJson(canciones);
      final dir = Directory(directoryPath);
      if (!await dir.exists()) await dir.create(recursive: true);
      final file = File(path.join(dir.path, filename));
      await file.writeAsString(content, flush: true);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Cargar canciones desde un archivo especificado por ruta absoluta (json o txt con json dentro)
  Future<bool> cargarDesdeArchivo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return false;
      final lista = Cancion.listaDesdeJson(content);
      await guardarCanciones(lista);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> agregarCancion(Cancion cancion) async {
    final canciones = await cargarCanciones();
    canciones.add(cancion);
    await guardarCanciones(canciones);
  }

  Future<void> actualizarCancion(Cancion cancion) async {
    final canciones = await cargarCanciones();
    final idx = canciones.indexWhere((s) => s.id == cancion.id);
    if (idx != -1) {
      canciones[idx] = cancion;
      await guardarCanciones(canciones);
    }
  }

  Future<void> eliminarCancion(String id) async {
    final canciones = await cargarCanciones();
    canciones.removeWhere((s) => s.id == id);
    await guardarCanciones(canciones);
  }
}
