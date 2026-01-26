/// Modelo que representa una operación pendiente de sincronización
class SyncOperation {
  final String id;
  final String operationType; // 'create', 'update', 'delete'
  final String cancionId;
  final String uid;
  final Map<String, dynamic>? cancionData; // null para delete
  final DateTime createdAt;
  final DateTime updatedAt;
  bool isSynced;
  String? errorMessage;

  SyncOperation({
    required this.id,
    required this.operationType,
    required this.cancionId,
    required this.uid,
    this.cancionData,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.errorMessage,
  });

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      operationType: json['operationType'] as String,
      cancionId: json['cancionId'] as String,
      uid: json['uid'] as String,
      cancionData: json['cancionData'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'operationType': operationType,
    'cancionId': cancionId,
    'uid': uid,
    'cancionData': cancionData,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isSynced': isSynced,
    'errorMessage': errorMessage,
  };

  SyncOperation copyWith({
    String? id,
    String? operationType,
    String? cancionId,
    String? uid,
    Map<String, dynamic>? cancionData,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? errorMessage,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      cancionId: cancionId ?? this.cancionId,
      uid: uid ?? this.uid,
      cancionData: cancionData ?? this.cancionData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
