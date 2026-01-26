# 🚀 Inicio Rápido - Sistema Offline-First

## En 5 Minutos

### 1. Instalar dependencias
```bash
cd tu-proyecto
flutter pub get
```

### 2. Ejecutar la app
```bash
flutter run
```

### 3. Probar offline

**Sin conexión a internet:**
- Apaga WiFi y datos móviles
- Abre la app
- Toca "+" para agregar una canción
- Completa los datos
- Toca "Guardar"
- ✅ La canción se guarda inmediatamente

**Con conexión a internet:**
- Enciende WiFi
- Observa el indicador "⟳ N" en AppBar
- Espera a que desaparezca
- ✅ La canción se sincronizó a Firestore

---

## Documentos Principales

### Para Entender
- 📖 [README_OFFLINE_SYNC.md](README_OFFLINE_SYNC.md) - Visión general

### Para Implementadores
- 🏗️ [CAMBIOS_OFFLINE_SYNC.md](CAMBIOS_OFFLINE_SYNC.md) - Qué cambió
- 🔧 [ARQUITECTURA_OFFLINE.md](ARQUITECTURA_OFFLINE.md) - Cómo funciona
- 📋 [INDICE_ARCHIVOS.md](INDICE_ARCHIVOS.md) - Archivos creados/modificados

### Para Testers
- 🧪 [GUIA_TESTING.md](GUIA_TESTING.md) - 10 tests completos
- 📚 [EJEMPLOS_OFFLINE.md](EJEMPLOS_OFFLINE.md) - 7 escenarios reales
- 📖 [OFFLINE_SYNC_DOCS.md](OFFLINE_SYNC_DOCS.md) - Referencia general

---

## Características Principales

✅ **Crear sin conexión**
- Agregar canciones funciona sin internet
- Se guarda inmediatamente en el dispositivo

✅ **Editar sin conexión**
- Modificar canciones funciona sin internet
- Los cambios se guardan inmediatamente

✅ **Eliminar sin conexión**
- Eliminar canciones funciona sin internet
- Se eliminan del dispositivo inmediatamente

✅ **Sincronización automática**
- Cuando recuperas conexión, todo se sincroniza automáticamente
- No tienes que hacer nada
- Los cambios se envían a Firestore en orden

✅ **Indicador visual**
- Ves "⟳ N" en AppBar mientras hay operaciones pendientes
- Desaparece cuando todo está sincronizado

---

## Flujo Simple

```
SIN INTERNET          CON INTERNET
    ↓                      ↓
Crear canción      Crear canción
    ↓                      ↓
Guarda local       Guarda local
    ↓                      ↓
    ✅ Listo          + Cola de sync
                           ↓
                      Sincroniza a Firebase
                           ↓
                           ✅ Listo
```

---

## Archivos Importantes

| Archivo | Descripción |
|---------|-------------|
| `lib/servicio/sync_service.dart` | Servicio principal de sincronización |
| `lib/servicio/connectivity_service.dart` | Detecta conexión |
| `lib/modelo/sync_queue.dart` | Modelo de operaciones |
| `lib/vista/lista_canciones_vista.dart` | Integración con UI |
| `pubspec.yaml` | Nuevas dependencias |

---

## Primeros Tests

### Test 1: Crear sin conexión (2 min)
1. Apaga WiFi
2. Abre la app
3. Toca "+"
4. Completa datos
5. Toca "Guardar"
6. ✅ La canción aparece

### Test 2: Sincronizar (3 min)
1. Enciende WiFi
2. Observa "⟳ N" en AppBar
3. Espera a que desaparezca
4. Verifica en Firestore
5. ✅ Está sincronizada

---

## Preguntas Frecuentes

**¿Funciona sin usuario autenticado?**
Sí, pero solo se guarda localmente. No se sincroniza a Firestore.

**¿Qué pasa si pierdo la app?**
Los datos se pierden (sin usuario autenticado).
Con usuario autenticado, cuando reinstales, se sincronizan de Firestore.

**¿Cuánto tiempo tarda la sincronización?**
Depende de:
- Cantidad de cambios
- Velocidad de conexión
- Estado del servidor

Típicamente < 10 segundos.

**¿Qué pasa si cierro la app sin sincronizar?**
La cola se guarda en el dispositivo.
Cuando abras la app de nuevo, continuará sincronizando.

**¿Puedo compartir sin conexión?**
No, requiere conexión activa.
Es por diseño (requiere comunicación con otro usuario).

---

## Comandos Útiles

### Ver logs
```bash
flutter logs
```

### Limpiar build
```bash
flutter clean
flutter pub get
flutter run
```

### Ver archivo de cola
```bash
adb shell cat /data/data/com.example.cancionero/files/Cancionero/sync_queue.json
```

---

## Solución Rápida de Problemas

**Indicador no desaparece**
→ Verifica que tienes conexión real
→ Abre logs: `flutter logs`
→ Reinicia la app

**Operaciones no se sincronizan**
→ Verifica que estás autenticado
→ Verifica Firestore rules
→ Verifica conexión de internet

**Crashes offline**
→ Actualiza dependencias: `flutter pub get`
→ Limpia build: `flutter clean`

---

## Documentación Completa

Para detalles técnicos completos, consulta:
- [CAMBIOS_OFFLINE_SYNC.md](CAMBIOS_OFFLINE_SYNC.md) - Cambios técnicos
- [ARQUITECTURA_OFFLINE.md](ARQUITECTURA_OFFLINE.md) - Arquitectura
- [GUIA_TESTING.md](GUIA_TESTING.md) - Tests exhaustivos
- [EJEMPLOS_OFFLINE.md](EJEMPLOS_OFFLINE.md) - Casos de uso

---

## Resumen

✅ La app ahora funciona sin conexión
✅ Los cambios se sincronizan automáticamente
✅ Hay indicador visual de progreso
✅ Todo está documentado
✅ Está listo para producción

¡Disfruta! 🎵
