# Sistema de Sincronización Offline-First

## Resumen

La aplicación ahora funciona completamente sin conexión a internet. Todas las operaciones (agregar, modificar, eliminar canciones) se guardan localmente de inmediato, y cuando hay conexión a internet, se sincronizan automáticamente con Firestore.

## Cómo funciona

### 1. **Almacenamiento Local**
- Todas las canciones se guardan primero en el almacenamiento local del dispositivo
- Esto garantiza que los cambios estén siempre disponibles, incluso sin internet

### 2. **Cola de Sincronización**
- Cuando hay un usuario autenticado, todas las operaciones se agregan a una cola
- La cola almacena:
  - Creación de canciones
  - Actualización de canciones
  - Eliminación de canciones
- Cada operación tiene un estado: pendiente o sincronizada

### 3. **Sincronización Automática**
- El sistema detecta automáticamente cuando hay conexión a internet
- Cuando se detecta conexión, intenta sincronizar todas las operaciones pendientes
- La sincronización se reinténta cada 30 segundos si hay operaciones pendientes
- Las operaciones se procesan en orden

### 4. **Indicador Visual**
- En la barra superior de la aplicación aparece un indicador cuando hay operaciones pendientes
- Muestra un icono de sincronización con el número de operaciones pendientes
- Desaparece cuando todas las operaciones están sincronizadas

## Flujo de operaciones

### Agregar una canción

1. Usuario escribe los datos de la canción
2. Se guarda **inmediatamente** en el almacenamiento local
3. Si hay usuario autenticado:
   - Se agrega a la cola de sincronización
   - Se intenta subir a Firestore
   - Si hay error, se reintenta automáticamente

### Modificar una canción

1. Usuario edita los datos
2. Se actualiza **inmediatamente** en el almacenamiento local
3. Si hay usuario autenticado:
   - Se agrega a la cola de sincronización
   - Se intenta subir a Firestore
   - Si hay error, se reintenta automáticamente

### Eliminar una canción

1. Usuario confirma la eliminación
2. Se elimina **inmediatamente** del almacenamiento local
3. Si hay usuario autenticado:
   - Se agrega a la cola de sincronización
   - Se intenta eliminar de Firestore
   - Si hay error, se reintenta automáticamente

## Archivos relacionados

### Nuevos archivos creados

1. **`lib/modelo/sync_queue.dart`**
   - Define la clase `SyncOperation`
   - Representa una operación pendiente de sincronización

2. **`lib/servicio/connectivity_service.dart`**
   - Detecta la disponibilidad de conexión a internet
   - Proporciona un stream para escuchar cambios de conectividad

3. **`lib/servicio/sync_service.dart`**
   - Gestiona toda la lógica de sincronización
   - Mantiene la cola de operaciones
   - Sincroniza automáticamente cuando hay conexión
   - Reintenta operaciones fallidas

### Archivos modificados

1. **`pubspec.yaml`**
   - Se agregaron dependencias:
     - `connectivity_plus`: Para detectar la conexión a internet
     - `sqflite`: Para almacenamiento local avanzado (opcional para futuras mejoras)

2. **`lib/vista/lista_canciones_vista.dart`**
   - Integración de `SyncService`
   - Cambio de callbacks para usar sincronización offline-first
   - Indicador visual en la barra de acciones

## Comportamiento sin conexión

- ✅ Crear canciones
- ✅ Modificar canciones
- ✅ Eliminar canciones
- ✅ Ver todas tus canciones
- ✅ Buscar canciones
- ✅ Editar tamaño de letra

Todas estas operaciones funcionan completamente sin internet. Los cambios se guardan localmente y se sincronizan cuando la conexión regresa.

## Comportamiento con conexión

- ✅ Todo lo anterior funciona igual
- ✅ Cambios se sincronizan automáticamente a Firestore
- ✅ Se pueden ver cambios desde otros dispositivos
- ✅ Se pueden compartir canciones con amigos
- ✅ Se reciben solicitudes de amistad

## Manejo de errores

Si una operación falla al sincronizar:
- El sistema intenta reintentarla automáticamente cada 30 segundos
- El indicador de sincronización muestra que hay operaciones pendientes
- El usuario puede reintentar manualmente o esperar a que se reintente

## Limitaciones

Las siguientes características requieren conexión a internet:
- ✗ Compartir canciones con otros usuarios
- ✗ Ver canciones compartidas
- ✗ Gestionar amigos
- ✗ Ver solicitudes de amistad

Estas operaciones seguirán requiriendo conexión porque involucran cambios en múltiples usuarios simultáneamente.
