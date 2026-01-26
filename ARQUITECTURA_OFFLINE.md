# Diagrama de Arquitectura - Sistema Offline-First

## Vista General

```
┌─────────────────────────────────────────────────────────┐
│                    APLICACIÓN FLUTTER                    │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────────────────────────────────────────┐   │
│  │         Lista de Canciones Vista                 │   │
│  │ (lista_canciones_vista.dart)                     │   │
│  │                                                   │   │
│  │  [Agregar] [Editar] [Eliminar] [Compartir]     │   │
│  └──────────────────────────────────────────────────┘   │
│                          │                                │
│                          ↓                                │
│  ┌──────────────────────────────────────────────────┐   │
│  │      Editar Canción Vista                        │   │
│  │ (editar_cancion_vista.dart)                      │   │
│  │                                                   │   │
│  │  [Guardar] → onSave/onUpdate callbacks          │   │
│  └──────────────────────────────────────────────────┘   │
│                          │                                │
│                          ↓                                │
│  ┌──────────────────────────────────────────────────┐   │
│  │      Almacenamiento Local                        │   │
│  │ (servicio_almacenamiento.dart)                   │   │
│  │                                                   │   │
│  │  [Guardar Inmediatamente] ✅ SIEMPRE FUNCIONA   │   │
│  └──────────────────────────────────────────────────┘   │
│                          │                                │
│                          ↓                                │
│  ┌──────────────────────────────────────────────────┐   │
│  │      Servicio de Sincronización                  │   │
│  │ (sync_service.dart)                              │   │
│  │                                                   │   │
│  │  1. Cola de Operaciones                          │   │
│  │  2. Verificación de Conectividad                 │   │
│  │  3. Sincronización Automática                    │   │
│  │  4. Reintentos                                   │   │
│  │  5. Notificaciones de Progreso                   │   │
│  └──────────────────────────────────────────────────┘   │
│                          │                                │
│          ┌───────────────┼───────────────┐              │
│          ↓               ↓               ↓              │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐   │
│  │  Conectividad│ │   Cola de    │ │ Firestore    │   │
│  │   Service    │ │  Operaciones │ │   Service    │   │
│  │              │ │              │ │              │   │
│  │ Detecta:     │ │  Mantiene:   │ │  Sube a:     │   │
│  │ ✅ Con WiFi  │ │  - Crear     │ │  ☁️ Cloud    │   │
│  │ ✅ Con datos │ │  - Actualizar│ │    Firestore │   │
│  │ ✅ Sin nada  │ │  - Eliminar  │ │              │   │
│  └──────────────┘ └──────────────┘ └──────────────┘   │
│          ↑               ↑                               │
│          └───────────────┴───────────────┘              │
│                          │                                │
│          ┌───────────────┴───────────────┐              │
│          ↓                               ↓              │
│  ┌──────────────────────┐    ┌──────────────────────┐  │
│  │  Almacenamiento Local│    │  Firestore (Nube)    │  │
│  │                      │    │                      │  │
│  │  canciones.txt       │    │  usuarios/           │  │
│  │  sync_queue.json     │    │    {uid}/            │  │
│  │                      │    │      canciones/      │  │
│  │  (Siempre disponible)│    │        {cancionId}   │  │
│  └──────────────────────┘    └──────────────────────┘  │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## Flujo de Datos para Crear una Canción

### SIN conexión a internet

```
Usuario
   │
   ↓
[Toca +]
   │
   ↓
EditarCancionVista
   │
   ├→ Usuario completa datos
   │
   ├→ [Guardar]
   │
   ↓
onSave callback
   │
   ├→ almacenamiento.agregarCancion()
   │     │
   │     ↓
   │  [ALMACENAMIENTO LOCAL] ✅
   │  (canciones.txt)
   │
   ├→ if (usuario autenticado)
   │    │
   │    ↓
   │  syncService.addCreateOperation()
   │     │
   │     ↓
   │  [COLA DE SINCRONIZACIÓN] ⏳
   │  (sync_queue.json)
   │
   ↓
[Cerrar vista]
   │
   ↓
[Lista actualizada]
   │
   ↓
AppBar muestra: "⟳ 1" (pendiente)
   │
   ↓
[Esperar a que haya conexión...]
```

### CON conexión a internet

```
Usuario
   │
   ↓
[Toca +]
   │
   ↓
EditarCancionVista
   │
   ├→ Usuario completa datos
   │
   ├→ [Guardar]
   │
   ↓
onSave callback
   │
   ├→ almacenamiento.agregarCancion()
   │     │
   │     ↓
   │  [ALMACENAMIENTO LOCAL] ✅
   │  (canciones.txt)
   │
   ├→ if (usuario autenticado)
   │    │
   │    ↓
   │  syncService.addCreateOperation()
   │     │
   │     ↓
   │  [COLA DE SINCRONIZACIÓN] 📝
   │
   │     ├→ [Detecta conexión ✅]
   │     │
   │     ├→ _firestore.crearCancion()
   │     │     │
   │     │     ↓
   │     │  [FIRESTORE ☁️]
   │     │
   │     ├→ [Elimina de cola] ✅
   │
   ↓
[Cerrar vista]
   │
   ↓
[Lista actualizada]
   │
   ↓
AppBar: "⟳ 0" o desaparece
   │
   ↓
[Sincronización completada] ✅
```

## Flujo de Sincronización Automática

```
┌─────────────────────────────────────────┐
│    SyncService Inicializa               │
│  (_initializeSync)                      │
└─────────────────────────────────────────┘
         │
         ├→ _loadSyncQueue()
         │  (Cargar cola del almacenamiento)
         │
         ├→ Escuchar conectivityStream
         │  (Detectar cambios de conexión)
         │
         └→ Iniciar Timer (cada 30 seg)
             (Intentar sincronización periódica)
                │
                ↓
         ┌──────────────────────────────┐
         │  ¿Hay conexión?              │
         └──────────────────────────────┘
                │
        ┌───────┴───────┐
        │               │
        NO              SÍ
        │               │
        ↓               ↓
     [Esperar]    [_performSync()]
                       │
                       ├→ Procesar cola
                       │
                       ├→ Para cada operación:
                       │  │
                       │  ├→ if (operationType == 'create')
                       │  │    _firestore.crearCancion()
                       │  │
                       │  ├→ if (operationType == 'update')
                       │  │    _firestore.actualizarCancion()
                       │  │
                       │  └→ if (operationType == 'delete')
                       │       _firestore.eliminarCancion()
                       │
                       ├→ if (exitosa)
                       │   [Marcar como sincronizada]
                       │   [Eliminar de cola]
                       │
                       └→ if (error)
                           [Guardar error]
                           [Mantener en cola]
                           [Reintentar en 30 seg]
                       │
                       ↓
                  [Guardar cola]
                  [Notificar cambio]
```

## Estados de una Operación

```
CREACIÓN
   │
   ↓
[Agregar a cola]
   │
   ├─────────────────────────────┐
   │                             │
   ↓                             ↓
SÍ conexión              NO conexión
   │                             │
   ↓                             ↓
[Sincronizar]               [Esperar]
   │                             │
   ├─────┬──────────┤           │
   │     │          │           │
   ↓     ↓          ↓           │
  OK   ERROR     TIMEOUT        │
  │     │          │            │
  ↓     ↓          ↓            │
[✅]  [⚠️]       [↻]           │
 │     │          │            │
 │     └──────────┴────────────┘
 │                 │
 ↓                 ↓
[Eliminar]     [Reintentar]
   │
   ↓
[Completada] ✅
```

## Indicador Visual en AppBar

```
┌────────────────────────────────────────────┐
│  Mis canciones        [👥] [⟳ 3] [🚪]     │
└────────────────────────────────────────────┘
                        ↑
                        │
                Indicador de Sincronización
                
                Partes:
                - ⟳ = Icono de sincronización
                - 3 = Número de operaciones pendientes
                
                Desaparece cuando no hay pendientes
```

## Almacenamiento de Archivos

```
{ApplicationDocuments}/
├── Cancionero/
│   ├── canciones.txt           (Lista de canciones locales)
│   ├── sync_queue.json         (Cola de operaciones)
│   ├── backups/                (Copias de seguridad)
│   │   └── canciones_backup_*.json
│   └── [otros archivos]
```

## Estados de Conectividad

```
┌──────────────────────────────┐
│   CONECTIVIDAD DETECTADA     │
├──────────────────────────────┤
│                              │
│  1. WiFi conectado           │
│     → hasInternetConnection() │
│     → connectivityStream emite│
│                              │
│  2. Datos móviles activos    │
│     → hasInternetConnection()│
│     → connectivityStream emite│
│                              │
│  3. Ethernet conectado       │
│     → hasInternetConnection()│
│     → connectivityStream emite│
│                              │
│  4. Sin conexión             │
│     → hasInternetConnection()│
│     → connectivityStream emite│
│                              │
└──────────────────────────────┘
```

## Ciclo de Vida de SyncService

```
┌─────────────────────────────────────┐
│  SyncService()                      │
│  (Constructor)                      │
└─────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────┐
│  _initializeSync()                  │
│  - Cargar cola                      │
│  - Escuchar conectividad            │
│  - Iniciar timer                    │
└─────────────────────────────────────┘
         │
         ├─→ Running ⚙️
         │
         ├─→ add*Operation()
         │   (Usuario actúa)
         │
         ├─→ _performSync()
         │   (Automático o manual)
         │
         └─→ dispose()
             │
             ↓
         ┌─────────────────────────────────────┐
         │  cleanup                            │
         │  - Cancelar subscripciones          │
         │  - Cancelar timer                   │
         │  - Liberar recursos                 │
         └─────────────────────────────────────┘
```

---

## Resumen de Componentes

| Componente | Archivo | Responsabilidad |
|-----------|---------|-----------------|
| **SyncService** | `sync_service.dart` | Orquesta la sincronización |
| **ConnectivityService** | `connectivity_service.dart` | Detecta conexión a internet |
| **SyncOperation** | `sync_queue.dart` | Modela una operación |
| **ServicioAlmacenamiento** | `servicio_almacenamiento.dart` | Gestiona almacenamiento local |
| **FirestoreService** | `firestore_service.dart` | Comunica con Firebase |
| **ListaCancionesVista** | `lista_canciones_vista.dart` | Interfaz principal |

---

## Métricas de Rendimiento

- **Tiempo de guardado local**: < 100ms
- **Tiempo de sincronización**: Variable (depende de conexión)
- **Reintentos automáticos**: Cada 30 segundos
- **Máximo de operaciones por sincronización**: Sin límite (procesadas una por una)
- **Uso de memoria**: Mínimo (solo la cola en memoria)
- **Tamaño de archivo de cola**: ~200-500 bytes por operación
