# Ejemplos de Uso - Sistema Offline-First

## Escenario 1: Usuario Sin Conexión Inicial

### Situación
El usuario abre la app sin conexión a internet y quiere agregar canciones.

### Qué sucede
1. El usuario toca el botón "+" para agregar una canción
2. Completa los datos (título, notas, etc.)
3. Toca "Guardar"
4. **Resultado**: La canción se guarda inmediatamente en el dispositivo
5. La lista se actualiza de inmediato mostrando la canción

### En el fondo
- La canción se almacena localmente
- No se intenta sincronizar (no hay conexión)
- El indicador de sincronización NO aparece (sin usuario autenticado)

### Si el usuario estuviera autenticado
- La operación se agregaria a la cola de sincronización
- El indicador mostraría "⟳ 1" en el AppBar
- Cuando vuelva la conexión, se sincronizaría automáticamente

---

## Escenario 2: Agregar Canción, Perder Conexión, Recuperar

### Situación
El usuario está autenticado y con conexión. Agrega una canción y luego pierde conexión.

### Qué sucede
1. Usuario toca "+" y agrega "Feliz Navidad"
2. Toca "Guardar"
3. **Automáticamente**:
   - Se guarda localmente
   - Se intenta subir a Firestore
   - Si tiene conexión, se sincroniza
4. Usuario accidentalmente pierde conexión (apaga WiFi)
5. Usuario agrega otra canción "Jingle Bells"
6. Se guarda localmente pero NO se sincroniza
7. El AppBar muestra "⟳ 1" (una operación pendiente)
8. Usuario recupera la conexión
9. **Automáticamente** se sincroniza en segundos
10. El AppBar ahora muestra "⟳ 0" o desaparece

### En el archivo
`{ApplicationDocuments}/Cancionero/sync_queue.json` tendría:
```json
[
  {
    "id": "timestamp1",
    "operationType": "create",
    "cancionId": "jingle-bells-id",
    "uid": "user123",
    "cancionData": {
      "titulo": "Jingle Bells",
      "notas": "Do Re Mi..."
    },
    "isSynced": false,
    "errorMessage": null
  }
]
```

Una vez sincronizada:
```json
[
  {
    ...
    "isSynced": true,
    "errorMessage": null
  }
]
```

Y después de sincronizar exitosamente, la operación se elimina de la cola.

---

## Escenario 3: Editar Canción Sin Conexión

### Situación
El usuario está autenticado, sin conexión. Abre una canción existente y la edita.

### Qué sucede
1. Usuario abre la canción "Feliz Navidad"
2. Toca "Editar"
3. Cambia las notas de "Do Re Mi" a "Do Re Mi Fa"
4. Toca "Guardar"
5. **Resultado**: 
   - Se actualiza inmediatamente localmente
   - Se intenta sincronizar (pero no hay conexión)
   - Se agrega a la cola como operación `update`
   - El AppBar muestra "⟳ 1"
6. Cuando recupera conexión, se sincroniza automáticamente

### En Firestore
La versión antigua se mantiene hasta que haya conexión y se sincronice.

---

## Escenario 4: Eliminar Canción Sin Conexión

### Situación
El usuario quiere eliminar una canción sin conexión.

### Qué sucede
1. Usuario abre la canción "Jingle Bells"
2. Toca "Eliminar"
3. Confirma la eliminación
4. **Resultado**:
   - Se elimina INMEDIATAMENTE de la pantalla
   - Se elimina del almacenamiento local
   - Se agrega a la cola como operación `delete`
   - El AppBar muestra "⟳ 1"
5. El usuario no ve más la canción
6. Cuando recupera conexión, se sincroniza (se elimina de Firestore)

### Importante
Si el usuario tuviera otro dispositivo con la app:
- Mientras no sincronice, el otro dispositivo seguirá viendo la canción
- Cuando este dispositivo se conecte, la canción se eliminará de Firestore
- El otro dispositivo lo verá reflejado cuando se conecte

---

## Escenario 5: Múltiples Operaciones en Cola

### Situación
El usuario sin conexión agrega 3 canciones y edita 2 existentes.

### Qué sucede
1. Agrega "Feliz Navidad"
   - Se guarda localmente
   - Se agrega a la cola (operación 1/5)
   - AppBar: "⟳ 1"

2. Agrega "Jingle Bells"
   - Se guarda localmente
   - Se agrega a la cola (operación 2/5)
   - AppBar: "⟳ 2"

3. Edita "Feliz Año Nuevo"
   - Se actualiza localmente
   - Se agrega a la cola (operación 3/5)
   - AppBar: "⟳ 3"

4. Agrega "White Christmas"
   - Se guarda localmente
   - Se agrega a la cola (operación 4/5)
   - AppBar: "⟳ 4"

5. Edita "Noche de Paz"
   - Se actualiza localmente
   - Se agrega a la cola (operación 5/5)
   - AppBar: "⟳ 5"

6. Usuario recupera conexión
   - El sistema sincroniza automáticamente en orden:
     1. Crear "Feliz Navidad"
     2. Crear "Jingle Bells"
     3. Actualizar "Feliz Año Nuevo"
     4. Crear "White Christmas"
     5. Actualizar "Noche de Paz"
   - AppBar cambia de "⟳ 5" → "⟳ 4" → "⟳ 3" → "⟳ 2" → "⟳ 1" → desaparece

---

## Escenario 6: Error en la Sincronización

### Situación
Algo falla al intentar sincronizar (error de servidor, permiso denegado, etc.)

### Qué sucede
1. Usuario agrega una canción
2. Hay conexión pero la sincronización falla (error temporal)
3. **El sistema**:
   - Registra el error en la operación
   - Mantiene la canción en la cola
   - Reintenta cada 30 segundos automáticamente
   - La canción sigue visible localmente (sin cambios)
4. Cuando el problema se resuelve:
   - El siguiente reintento (en máximo 30 segundos) sincroniza exitosamente
   - El AppBar se actualiza

### En el archivo
```json
[
  {
    "id": "timestamp",
    "operationType": "create",
    "cancionId": "song-id",
    "uid": "user123",
    "cancionData": {...},
    "isSynced": false,
    "errorMessage": "Usuario no tiene permisos para crear canciones"
  }
]
```

---

## Escenario 7: Compartir Canciones Requiere Conexión

### Situación
El usuario intenta compartir una canción mientras no tiene internet.

### Qué sucede
1. Usuario abre una canción
2. Toca el menú ⋮ → "Compartir..."
3. **Resultado**: Se muestra un error o no está disponible
   - Esta operación NO se puede hacer offline
   - Requiere conexión activa
   - Es por diseño (requiere comunicación con otro usuario)

---

## Monitoreo de la Cola

### Ver el estado de la cola
La cola se almacena en:
```
{ApplicationDocuments}/Cancionero/sync_queue.json
```

### Contenido tipico

**Sin operaciones pendientes:**
```json
[]
```

**Con operaciones pendientes:**
```json
[
  {
    "id": "1705948200000",
    "operationType": "create",
    "cancionId": "song-1705948200000",
    "uid": "user-abc123",
    "cancionData": {
      "titulo": "Mi Canción",
      "notas": "Do Re Mi",
      "subtitulo": null,
      "subtitulos": [],
      "fontSize": 22.0
    },
    "createdAt": "2026-01-26T10:30:00.000Z",
    "updatedAt": "2026-01-26T10:30:00.000Z",
    "isSynced": false,
    "errorMessage": null
  },
  {
    "id": "1705948300000",
    "operationType": "update",
    "cancionId": "existing-song-id",
    "uid": "user-abc123",
    "cancionData": {
      "titulo": "Mi Canción Actualizada",
      "notas": "Do Re Mi Fa",
      ...
    },
    "createdAt": "2026-01-26T10:30:10.000Z",
    "updatedAt": "2026-01-26T10:30:10.000Z",
    "isSynced": false,
    "errorMessage": null
  }
]
```

### Limpieza automática
El archivo se limpia automáticamente cuando las operaciones se sincronizan exitosamente.

---

## Resumen de Comportamiento

| Acción | Sin Conexión | Con Conexión |
|--------|-------------|--------------|
| Crear canción | ✅ Instantáneo | ✅ Instantáneo + Sincroniza |
| Editar canción | ✅ Instantáneo | ✅ Instantáneo + Sincroniza |
| Eliminar canción | ✅ Instantáneo | ✅ Instantáneo + Sincroniza |
| Ver canciones | ✅ Locales | ✅ Locales + Nube |
| Compartir | ❌ No disponible | ✅ Disponible |
| Ver compartidas | ❌ No disponible | ✅ Disponible |
| Amigos | ❌ No disponible | ✅ Disponible |

---

## Tips de Testing

### Test 1: Crear y Perder Conexión
1. Abre la app con conexión
2. Agrega una canción
3. Desactiva internet inmediatamente
4. Agrega otra canción
5. Verifica que ambas estén en la lista
6. Reactiva internet
7. Verifica que el AppBar indique sincronización
8. Espera a que se sincronice

### Test 2: Múltiples Cambios Rápidos
1. Sin conexión, agrega 5 canciones rápidamente
2. El AppBar debe mostrar "⟳ 5"
3. Reactiva internet
4. Observa cómo el número disminuye ("⟳ 4" → "⟳ 3"...)
5. Verifica en Firestore que todas las canciones se crearon

### Test 3: Edición y Eliminación
1. Sin conexión, edita 2 canciones y elimina 1
2. El AppBar muestra "⟳ 3"
3. Reactiva internet
4. Verifica en Firestore que los cambios se aplicaron correctamente

### Test 4: Verificar Archivo de Cola
1. Instala un explorador de archivos en tu dispositivo
2. Sin conexión, agrega canciones
3. Accede a: `{ApplicationDocuments}/Cancionero/sync_queue.json`
4. Verifica el contenido JSON
5. Reactiva internet
6. Espera a que se sincronice
7. Verifica que el archivo se limpie (o esté vacío)
