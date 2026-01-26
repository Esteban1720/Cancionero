# Resumen de Cambios - Sistema Offline-First

## Problema Original
La aplicación no permitía agregar, modificar o eliminar canciones cuando no había conexión a internet. El usuario solo podía trabajar con las canciones locales usando SQLite directo, pero sin sincronización con la nube.

## Solución Implementada
Se ha implementado un sistema completo de **sincronización offline-first** que permite:

1. ✅ **Trabajar sin conexión**: Todas las operaciones (crear, modificar, eliminar) funcionan completamente sin internet
2. ✅ **Almacenamiento local inmediato**: Los cambios se guardan localmente de forma inmediata
3. ✅ **Sincronización automática**: Cuando hay conexión, los cambios se suben automáticamente a Firestore
4. ✅ **Cola de sincronización**: Las operaciones se encolan y se sincronizan en orden
5. ✅ **Indicador visual**: Muestra en la interfaz cuántas operaciones están pendientes de sincronización
6. ✅ **Reintentos automáticos**: Si algo falla, reinténta cada 30 segundos

## Archivos Nuevos Creados

### 1. `lib/modelo/sync_queue.dart`
Define la clase `SyncOperation` que representa una operación pendiente:
- `id`: Identificador único
- `operationType`: 'create', 'update' o 'delete'
- `cancionId`: ID de la canción afectada
- `uid`: Usuario propietario
- `cancionData`: Datos de la canción (para create/update)
- `isSynced`: Si ya fue sincronizada
- `errorMessage`: Mensaje de error si falló

### 2. `lib/servicio/connectivity_service.dart`
Servicio singleton que detecta conectividad:
- `hasInternetConnection()`: Verifica si hay internet en este momento
- `connectivityStream`: Stream que emite cambios de estado de conectividad

### 3. `lib/servicio/sync_service.dart`
Servicio principal de sincronización:
- Mantiene una cola de operaciones pendientes
- Guarda/carga la cola desde almacenamiento local
- Escucha cambios de conectividad
- Sincroniza automáticamente cada 30 segundos si hay conexión
- Reinténta operaciones fallidas
- Emite notificaciones del estado de sincronización

## Archivos Modificados

### 1. `pubspec.yaml`
Se agregaron dos dependencias:
```yaml
connectivity_plus: ^5.0.0  # Detectar cambios de conexión
sqflite: ^2.3.0            # Para almacenamiento local avanzado
```

### 2. `lib/vista/lista_canciones_vista.dart`
Cambios principales:
- Se importa `SyncService`
- Se crea instancia de `SyncService` en `initState`
- Se modifican los callbacks `onSave` y `onUpdate` para:
  1. Guardar localmente primero
  2. Agregar a la cola de sincronización si hay usuario autenticado
- Se agrega indicador visual en el AppBar mostrando operaciones pendientes
- Se libera `SyncService` en `dispose()`

## Cómo Funciona

### Flujo para Crear una Canción
```
Usuario toca "+"
    ↓
EditarCancionVista abre
    ↓
Usuario ingresa datos
    ↓
Usuario guarda
    ↓
Se guarda INMEDIATAMENTE en almacenamiento local
    ↓
Si hay usuario autenticado:
    ├→ Se agrega a la cola de sincronización
    ├→ Se intenta subir a Firestore
    └→ Si falla, se reintenta automáticamente cada 30 seg
    ↓
La lista se actualiza inmediatamente
```

### Flujo para Modificar una Canción
```
Usuario abre una canción
    ↓
Usuario toca editar
    ↓
Usuario cambia datos
    ↓
Usuario guarda
    ↓
Se actualiza INMEDIATAMENTE en almacenamiento local
    ↓
Si hay usuario autenticado:
    ├→ Se agrega a la cola de sincronización
    ├→ Se intenta actualizar en Firestore
    └→ Si falla, se reintenta automáticamente cada 30 seg
    ↓
La lista se actualiza inmediatamente
```

### Flujo para Eliminar una Canción
```
Usuario abre una canción
    ↓
Usuario toca eliminar
    ↓
Se solicita confirmación
    ↓
Usuario confirma
    ↓
Se ELIMINA INMEDIATAMENTE del almacenamiento local
    ↓
Si hay usuario autenticado:
    ├→ Se agrega a la cola de sincronización
    ├→ Se intenta eliminar de Firestore
    └→ Si falla, se reintenta automáticamente cada 30 seg
    ↓
La lista se actualiza inmediatamente
```

## Indicador Visual

En la barra superior (AppBar) aparecerá un indicador cuando hay operaciones pendientes:
- Icono: Spinner de carga amarillo
- Número: Cantidad de operaciones pendientes
- Tooltip: Mensaje explicativo

Ejemplo: `⟳ 3` significa hay 3 operaciones pendientes

El indicador desaparece cuando todo está sincronizado.

## Archivos de Almacenamiento

Las operaciones pendientes se guardan en:
`{ApplicationDocuments}/Cancionero/sync_queue.json`

Estructura del archivo:
```json
[
  {
    "id": "1234567890",
    "operationType": "create",
    "cancionId": "song-123",
    "uid": "user-uid",
    "cancionData": {
      "titulo": "Mi Canción",
      "notas": "Do Re Mi",
      ...
    },
    "createdAt": "2026-01-26T10:30:00.000Z",
    "updatedAt": "2026-01-26T10:30:00.000Z",
    "isSynced": false,
    "errorMessage": null
  }
]
```

## Comportamiento Sin Internet

✅ Crear canciones
✅ Modificar canciones
✅ Eliminar canciones
✅ Ver todas las canciones
✅ Buscar canciones
✅ Cambiar tamaño de letra
✅ Cambiar subtítulos

## Comportamiento Con Internet

✅ Todo lo anterior, más:
✅ Sincronización automática a Firestore
✅ Ver cambios en otros dispositivos
✅ Compartir canciones
✅ Ver canciones compartidas
✅ Gestionar amigos

## Limitaciones Conocidas

Las siguientes características TODAVÍA requieren conexión:
- ✗ Compartir canciones (requiere conexión activa)
- ✗ Ver canciones compartidas (requiere conexión activa)
- ✗ Gestionar solicitudes de amistad (requiere conexión activa)

Esto es por diseño, ya que estas operaciones involucran múltiples usuarios simultáneamente y requieren coordinación en tiempo real.

## Próximas Mejoras Posibles

1. Almacenamiento de canciones compartidas en caché local
2. Sincronización de historial de cambios
3. Resolución automática de conflictos
4. Interfaz para ver/administrar la cola de sincronización
5. Estadísticas de sincronización

## Instalación

1. Ejecutar `flutter pub get` para instalar las nuevas dependencias
2. Ejecutar `flutter run` como normalmente
3. La funcionalidad offline se activará automáticamente

## Testing

Para probar el funcionamiento offline:
1. Desactivar internet en tu dispositivo
2. Agregar/modificar/eliminar canciones
3. Reactivar internet
4. Observar cómo se sincronizan automáticamente

También puedes ver la cola de sincronización en:
`{ApplicationDocuments}/Cancionero/sync_queue.json`
