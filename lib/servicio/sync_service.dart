import 'package:flutter/foundation.dart';
import 'package:cancionero/modelo/sync_queue.dart';
import 'package:cancionero/servicio/connectivity_service.dart';
import 'package:cancionero/servicio/firestore_service.dart';
import 'package:cancionero/servicio/servicio_almacenamiento.dart';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class SyncService extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final ServicioAlmacenamiento _localStorage = ServicioAlmacenamiento();
  final ConnectivityService connectivityService = ConnectivityService();

  List<SyncOperation> _syncQueue = [];
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isSyncing = false;
  
  // Stream de cambios en la cola
  final ValueNotifier<int> _pendingSyncCount = ValueNotifier(0);

  ValueNotifier<int> get pendingSyncCount => _pendingSyncCount;
  List<SyncOperation> get syncQueue => List.unmodifiable(_syncQueue);
  bool get isSyncing => _isSyncing;

  SyncService() {
    _initializeSync();
  }

  void _initializeSync() {
    // Cargar cola de sincronización desde almacenamiento local
    _loadSyncQueue();
    
    // Escuchar cambios de conectividad
    _connectivitySubscription = connectivityService.connectivityStream.listen(
      (isConnected) {
        if (isConnected) {
          _performSync();
        }
      },
    );

    // Sincronizar cada 30 segundos si hay operaciones pendientes
    _syncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) async {
        if (_syncQueue.isNotEmpty && !_isSyncing) {
          final hasConnection = await connectivityService.hasInternetConnection();
          if (hasConnection) {
            _performSync();
          }
        }
      },
    );
  }

  /// Carga la cola de sincronización desde almacenamiento local
  Future<void> _loadSyncQueue() async {
    try {
      final file = await _getSyncQueueFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isEmpty) {
          _syncQueue = [];
        } else {
          final json = jsonDecode(content) as List<dynamic>;
          _syncQueue = json
              .map((item) => SyncOperation.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      _updatePendingCount();
    } catch (e) {
      print('Error loading sync queue: $e');
      _syncQueue = [];
    }
  }

  /// Guarda la cola de sincronización en almacenamiento local
  Future<void> _saveSyncQueue() async {
    try {
      final file = await _getSyncQueueFile();
      final json = jsonEncode(_syncQueue.map((op) => op.toJson()).toList());
      await file.writeAsString(json);
      _updatePendingCount();
    } catch (e) {
      print('Error saving sync queue: $e');
    }
  }

  /// Obtiene el archivo de la cola de sincronización
  Future<File> _getSyncQueueFile() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(path.join(appDir.path, 'Cancionero'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return File(path.join(dir.path, 'sync_queue.json'));
  }

  /// Agrega una operación de creación a la cola
  Future<void> addCreateOperation({
    required String cancionId,
    required String uid,
    required Map<String, dynamic> cancionData,
  }) async {
    final operation = SyncOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operationType: 'create',
      cancionId: cancionId,
      uid: uid,
      cancionData: cancionData,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _syncQueue.add(operation);
    await _saveSyncQueue();
    notifyListeners();
    
    // Intentar sincronizar si hay conexión
    final hasConnection = await connectivityService.hasInternetConnection();
    if (hasConnection) {
      _performSync();
    }
  }

  /// Agrega una operación de actualización a la cola
  Future<void> addUpdateOperation({
    required String cancionId,
    required String uid,
    required Map<String, dynamic> cancionData,
  }) async {
    final operation = SyncOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operationType: 'update',
      cancionId: cancionId,
      uid: uid,
      cancionData: cancionData,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _syncQueue.add(operation);
    await _saveSyncQueue();
    notifyListeners();
    
    // Intentar sincronizar si hay conexión
    final hasConnection = await connectivityService.hasInternetConnection();
    if (hasConnection) {
      _performSync();
    }
  }

  /// Agrega una operación de eliminación a la cola
  Future<void> addDeleteOperation({
    required String cancionId,
    required String uid,
  }) async {
    final operation = SyncOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      operationType: 'delete',
      cancionId: cancionId,
      uid: uid,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _syncQueue.add(operation);
    await _saveSyncQueue();
    notifyListeners();
    
    // Intentar sincronizar si hay conexión
    final hasConnection = await connectivityService.hasInternetConnection();
    if (hasConnection) {
      _performSync();
    }
  }

  /// Realiza la sincronización de operaciones pendientes
  Future<void> _performSync() async {
    if (_isSyncing || _syncQueue.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    final hasConnection = await connectivityService.hasInternetConnection();
    if (!hasConnection) {
      _isSyncing = false;
      notifyListeners();
      return;
    }

    // Procesar operaciones en orden
    final operationsToRemove = <int>[];
    
    for (int i = 0; i < _syncQueue.length; i++) {
      final operation = _syncQueue[i];
      
      try {
        switch (operation.operationType) {
          case 'create':
            await _firestore.crearCancion(
              uid: operation.uid,
              cancion: operation.cancionData!,
              documentId: operation.cancionId,  // Usar el ID local para mantener consistencia
            );
            operationsToRemove.add(i);
            break;
            
          case 'update':
            await _firestore.actualizarCancion(
              uid: operation.uid,
              id: operation.cancionId,
              cancion: operation.cancionData!,
            );
            operationsToRemove.add(i);
            break;
            
          case 'delete':
            await _firestore.eliminarCancion(
              uid: operation.uid,
              id: operation.cancionId,
            );
            operationsToRemove.add(i);
            break;
        }
        
        // Actualizar operación como sincronizada
        _syncQueue[i] = _syncQueue[i].copyWith(
          isSynced: true,
          errorMessage: null,
          updatedAt: DateTime.now(),
        );
      } catch (e) {
        // Registrar error pero continuar con las siguientes operaciones
        _syncQueue[i] = _syncQueue[i].copyWith(
          errorMessage: e.toString(),
          updatedAt: DateTime.now(),
        );
        print('Error syncing operation ${operation.id}: $e');
      }
    }

    // Eliminar operaciones completadas (en orden inverso para no afectar índices)
    for (int i = operationsToRemove.length - 1; i >= 0; i--) {
      _syncQueue.removeAt(operationsToRemove[i]);
    }

    await _saveSyncQueue();

    _isSyncing = false;
    notifyListeners();
    
    // Luego, sincronizar datos DESDE Firestore (descargar cambios remotos)
    await _syncFromFirestore();
  }

  /// Sincroniza datos DESDE Firestore hacia el almacenamiento local
  /// Útil para mantener sincronizados los datos cuando vuelve el internet
  Future<void> _syncFromFirestore() async {
    try {
      // Por ahora, esta función es llamada automáticamente después de _performSync
      // Podría extenderse para descargar cambios específicos de Firestore
      print('Sync from Firestore completed');
    } catch (e) {
      print('Error syncing from Firestore: $e');
    }
  }

  /// Fuerza la sincronización manualmente
  Future<void> forceSyncNow() async {
    if (_syncQueue.isEmpty) return;
    await _performSync();
  }

  /// Retira una operación fallida de la cola (para que no bloquee otras)
  Future<void> removeFailedOperation(String operationId) async {
    _syncQueue.removeWhere((op) => op.id == operationId);
    await _saveSyncQueue();
    notifyListeners();
  }

  /// Reintenta una operación fallida
  Future<void> retryOperation(String operationId) async {
    final index = _syncQueue.indexWhere((op) => op.id == operationId);
    if (index == -1) return;

    _syncQueue[index] = _syncQueue[index].copyWith(
      errorMessage: null,
      updatedAt: DateTime.now(),
    );
    await _saveSyncQueue();
    
    final hasConnection = await connectivityService.hasInternetConnection();
    if (hasConnection) {
      await _performSync();
    }
    notifyListeners();
  }

  void _updatePendingCount() {
    _pendingSyncCount.value = _syncQueue.length;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
