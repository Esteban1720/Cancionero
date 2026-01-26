# Guía de Testing - Sistema Offline-First

## Prerequisitos

- Dispositivo Android/iOS con Flutter
- Acceso a WiFi o datos móviles para probar conexión
- Acceso a FireStore (crear una cuenta de prueba)
- Explorador de archivos en el dispositivo (opcional pero útil)

## Test 1: Crear Canción Sin Conexión

### Objetivo
Verificar que se puede crear una canción completamente sin conexión.

### Pasos

1. **Preparar dispositivo**
   - Instala la app
   - Desactiva WiFi
   - Desactiva datos móviles
   - Verifica que no hay conexión:
     ```
     Configuración → Wifi → Desconectado
     Configuración → Datos móviles → Desconectado
     ```

2. **Abrir la app**
   - Abre Cancionero
   - Deberías ver "Sin conexión" o similar

3. **Crear una canción**
   - Toca el botón "+"
   - Completa los campos:
     - **Título**: "Test Offline #1"
     - **Notas**: "Do Re Mi Fa"
   - Toca "Guardar"

4. **Verificar**
   - ✅ La canción aparece inmediatamente en la lista
   - ✅ No hay errores
   - ✅ La vista se cierra automáticamente

5. **Crear más canciones**
   - Repite el proceso 2-3 veces más
   - Crea canciones con datos variados

### Resultado esperado
✅ Todas las canciones están guardadas localmente y visibles en la lista, sin necesidad de conexión.

---

## Test 2: Editar Canción Sin Conexión

### Objetivo
Verificar que se puede editar canciones sin conexión.

### Pasos

1. **Preparar dispositivo**
   - Asegúrate de no tener conexión
   - Tienes al menos una canción creada (del Test 1)

2. **Editar una canción**
   - Abre la lista de canciones
   - Toca una canción para abrirla
   - Toca el botón de editar (lápiz)
   - Cambia el título: "Test Offline #1 - EDITADO"
   - Toca "Guardar"

3. **Verificar**
   - ✅ El cambio se refleja inmediatamente en la lista
   - ✅ No hay errores

4. **Editar más canciones**
   - Repite con 2-3 canciones más
   - Cambia títulos, notas, subtítulos

### Resultado esperado
✅ Todos los cambios se guardan inmediatamente y se reflejan en la lista.

---

## Test 3: Eliminar Canción Sin Conexión

### Objetivo
Verificar que se puede eliminar canciones sin conexión.

### Pasos

1. **Preparar dispositivo**
   - Asegúrate de no tener conexión
   - Tienes varias canciones para probar

2. **Eliminar una canción**
   - Abre una canción
   - Toca el botón de eliminar (papelera)
   - Confirma la eliminación

3. **Verificar**
   - ✅ La canción desaparece inmediatamente de la lista
   - ✅ No hay errores

4. **Eliminar más canciones**
   - Repite el proceso 2 veces más

### Resultado esperado
✅ Las canciones se eliminan inmediatamente del dispositivo.

---

## Test 4: Sincronización Automática

### Objetivo
Verificar que los cambios se sincronizan cuando vuelve la conexión.

### Pasos

1. **Preparar dispositivo**
   - Sin conexión
   - Tienes cambios sin sincronizar (de Tests 1-3)

2. **Verificar antes de conectar**
   - Si estás autenticado, deberías ver el indicador "⟳ N" en AppBar
   - Toma una captura de pantalla

3. **Conectar a Internet**
   - Activa WiFi o datos móviles
   - Verifica que hay conexión

4. **Observar sincronización**
   - En la vista de lista, el AppBar debería mostrar:
     ```
     ⟳ 5 → ⟳ 4 → ⟳ 3 → ⟳ 2 → ⟳ 1 → [desaparece]
     ```
   - Espera a que el indicador desaparezca (máximo 2-3 minutos)

5. **Verificar en Firestore**
   - Abre Firebase Console
   - Ve a Firestore → usuarios → {tu-uid} → canciones
   - Verifica que todas tus canciones estén allí
   - Revisa que los cambios se reflejaron correctamente

6. **Verificar desde otro dispositivo** (opcional)
   - Abre la app en otro dispositivo con tu cuenta
   - Deberías ver todas las canciones sincronizadas

### Resultado esperado
✅ Todas las operaciones se sincronizan correctamente a Firestore.
✅ Los datos están disponibles en otros dispositivos.

---

## Test 5: Reconexión Intermitente

### Objetivo
Verificar que el sistema maneja bien las reconexiones frecuentes.

### Pasos

1. **Preparar dispositivo**
   - Con conexión
   - Tienes una lista de canciones

2. **Apagar y encender WiFi rápidamente**
   - Apaga WiFi
   - Espera 5 segundos
   - Agrega una canción (sin conexión)
   - Enciende WiFi
   - Verifica que se sincroniza
   - Apaga WiFi
   - Espera 5 segundos
   - Edita una canción
   - Enciende WiFi
   - Verifica que se sincroniza
   - Repite 3-4 veces

3. **Verificar**
   - ✅ El indicador parpadea/cambia constantemente
   - ✅ No hay errors
   - ✅ Todas las operaciones se sincronizan finalmente

### Resultado esperado
✅ El sistema maneja reconexiones sin problemas.

---

## Test 6: Múltiples Operaciones en Cola

### Objetivo
Verificar que se procesan correctamente múltiples operaciones en cola.

### Pasos

1. **Preparar dispositivo**
   - Sin conexión
   - Abre explorador de archivos (opcional pero recomendado)

2. **Realizar múltiples operaciones rápidamente**
   ```
   1. Crear "Canción 1"
   2. Crear "Canción 2"
   3. Editar "Canción existente"
   4. Crear "Canción 3"
   5. Eliminar "Canción X"
   6. Crear "Canción 4"
   7. Editar "Canción 1"
   ```
   - Hazlo en 30-60 segundos

3. **Verificar cola** (opcional)
   - Abre explorador de archivos
   - Ve a: /data/data/com.example.cancionero/files/Cancionero/
   - Abre sync_queue.json
   - Deberías ver 7 operaciones en la cola
   - Cada una con su operationType y datos

4. **Conectar a Internet**
   - Enciende WiFi
   - Observa cómo el indicador disminuye
   - Las operaciones se procesan en orden

5. **Verificar en Firestore**
   - Verifica que se crearon todas las canciones
   - Verifica que se actualizaron correctamente
   - Verifica que se eliminaron correctamente

### Resultado esperado
✅ Se crean 4 canciones nuevas, 2 se actualizan, 1 se elimina.
✅ El archivo sync_queue.json se vacía después de sincronizar.

---

## Test 7: Error en Sincronización

### Objetivo
Verificar que el sistema maneja errores de sincronización.

### Pasos

1. **Preparar dispositivo**
   - Con conexión
   - Tienes una canción en el dispositivo

2. **Simular error de Firestore** (avanzado)
   - Desactiva las reglas de Firestore temporalmente
   - O crea un escenario donde fallará

3. **Intentar crear una canción**
   - Crea una canción con conexión activa
   - El sistema intentará sincronizar
   - Pero fallará por las reglas deshabilitadas

4. **Verificar comportamiento**
   - ✅ La canción se guarda localmente
   - ✅ El indicador muestra que hay operaciones pendientes
   - ✅ No hay error visible al usuario

5. **Restaurar Firestore**
   - Reactiva las reglas normales
   - Espera a que el sistema reintente automáticamente

6. **Verificar sincronización**
   - El indicador debe desaparecer
   - La canción debe estar en Firestore

### Resultado esperado
✅ Los errores se manejan gracefully.
✅ El sistema reinténta automáticamente.

---

## Test 8: Cambio de Usuario

### Objetivo
Verificar que funciona correctamente al cambiar de usuario.

### Pasos

1. **Crear Canción sin usuario**
   - Cierra sesión
   - Crea una canción sin autenticación
   - La canción está en almacenamiento local

2. **Iniciar sesión**
   - Abre sesión con una cuenta
   - Las canciones locales se ven

3. **Crear nueva canción**
   - Crea una canción
   - Debería sincronizarse a Firestore
   - El indicador muestra progreso

4. **Cambiar a otro usuario**
   - Abre sesión con otra cuenta
   - Las canciones anteriores de ese usuario aparecen
   - Las canciones del usuario anterior no aparecen

5. **Verificar sincronización**
   - Ambos usuarios tienen sus canciones sincronizadas
   - No hay conflictos

### Resultado esperado
✅ El cambio de usuario funciona correctamente.
✅ Cada usuario tiene sus propias canciones.

---

## Test 9: Búsqueda y Filtrado

### Objetivo
Verificar que la búsqueda funciona con canciones sin sincronizar.

### Pasos

1. **Preparar**
   - Sin conexión
   - Crea varias canciones:
     - "Feliz Navidad"
     - "Jingle Bells"
     - "White Christmas"
     - "Noche de Paz"

2. **Buscar canciones**
   - Busca "Feliz"
   - Deberías encontrar "Feliz Navidad"
   - Busca "Jingle"
   - Deberías encontrar "Jingle Bells"
   - Busca "Christmas"
   - Deberías encontrar "White Christmas"

3. **Verificar**
   - ✅ La búsqueda funciona sin conexión
   - ✅ Encuentra canciones no sincronizadas

### Resultado esperado
✅ La búsqueda funciona correctamente en canciones locales.

---

## Test 10: Tamaño de Archivo de Cola

### Objetivo
Verificar que el archivo de cola no crece descontroladamente.

### Pasos

1. **Monitorear tamaño de archivo**
   - Abre explorador de archivos
   - Ve a /data/data/com.example.cancionero/files/Cancionero/
   - Nota el tamaño de sync_queue.json (inicial: vacío o pequeño)

2. **Crear muchas operaciones**
   - Sin conexión, crea 20 canciones
   - Nota el tamaño del archivo

3. **Conectar a Internet**
   - Enciende WiFi
   - Espera a que se sincronice

4. **Verificar tamaño final**
   - El archivo debería estar vacío o muy pequeño
   - No debería ser un archivo grande

### Resultado esperado
✅ El archivo de cola se limpia después de sincronizar.
✅ No hay acumulación de datos.

---

## Checklist de Validación

Marca cada prueba conforme la completes:

### Tests básicos
- [ ] Test 1: Crear sin conexión
- [ ] Test 2: Editar sin conexión
- [ ] Test 3: Eliminar sin conexión
- [ ] Test 4: Sincronización automática

### Tests avanzados
- [ ] Test 5: Reconexión intermitente
- [ ] Test 6: Múltiples operaciones
- [ ] Test 7: Error de sincronización
- [ ] Test 8: Cambio de usuario
- [ ] Test 9: Búsqueda
- [ ] Test 10: Tamaño de archivo

### Verificaciones finales
- [ ] No hay crashes
- [ ] No hay memory leaks
- [ ] El indicador de sincronización funciona
- [ ] Los datos se sincronizan correctamente a Firestore
- [ ] Las operaciones se procesan en orden

---

## Comandos Útiles

### Ver logs en tiempo real
```bash
flutter logs
```

### Ver archivo de cola en dispositivo
```bash
adb shell cat /data/data/com.example.cancionero/files/Cancionero/sync_queue.json
```

### Reiniciar la app
```bash
adb shell am force-stop com.example.cancionero
```

### Ver estado de conectividad
```bash
adb shell
getprop ro.net.change
```

---

## Solución de Problemas

### Problema: El indicador nunca desaparece
**Solución:**
- Verifica que hay conexión a internet real
- Abre los logs: `flutter logs`
- Busca mensajes de error
- Verifica las reglas de Firestore
- Intenta sincronizar manualmente

### Problema: Operaciones no se sincronizan
**Solución:**
- Verifica la conexión a internet
- Abre Firebase Console
- Verifica las reglas de Firestore
- Verifica los permisos del usuario
- Intenta cerrar y abrir la app

### Problema: Archivo sync_queue.json corrupto
**Solución:**
- Elimina el archivo manualmente:
  ```bash
  adb shell rm /data/data/com.example.cancionero/files/Cancionero/sync_queue.json
  ```
- Reinicia la app
- El archivo se recreará correctamente

### Problema: Aplicación crash offline
**Solución:**
- Revisa los logs: `flutter logs`
- Busca excepciones NullPointerException
- Verifica que el almacenamiento local está inicializado
- Intenta desinstalar y reinstalar

---

## Notas de Testing

- **Tiempo de sincronización**: Generalmente < 10 segundos
- **Reintentos**: Cada 30 segundos si hay operaciones pendientes
- **Conexión**: Usa WiFi para pruebas más confiables
- **Firestore**: Los cambios pueden tomar 1-2 segundos en verse en Firebase Console
- **Caché**: Limpia la caché de la app si hay comportamiento extraño

---

## Requisitos de Éxito

Para que el proyecto sea considerado exitoso:

✅ **Funcionalidad offline**
- Crear canciones sin conexión
- Editar canciones sin conexión
- Eliminar canciones sin conexión
- Buscar canciones sin conexión

✅ **Sincronización**
- Detecta automáticamente conexión a internet
- Sincroniza cambios cuando hay conexión
- Procesa operaciones en orden
- Reinténta operaciones fallidas

✅ **Indicador visual**
- Muestra número de operaciones pendientes
- Desaparece cuando todo está sincronizado
- Es claramente visible

✅ **Almacenamiento**
- Guarda cola en archivo JSON
- Carga cola al iniciar
- Limpia cola después de sincronizar

✅ **Sin errores**
- No hay crashes
- No hay memory leaks
- No hay errores en logs
