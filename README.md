# Cancionero 🎵

**Cancionero** es una aplicación móvil escrita en **Flutter** para crear, editar y gestionar canciones en formato de notas musicales simples. Permite ingresar notas por línea, insertar saltos de línea, añadir subtítulos por canción y por línea, y guardar/cargar colecciones de canciones en archivos `.txt` (JSON interno) en el dispositivo.

---

## 🧩 Características principales

- Crear y editar canciones con notas musicales (tokens) organizadas por líneas.
- Insertar saltos de línea repetidos para dejar líneas vacías.
- Indicador y resaltado de la línea actual en la vista de edición. ✅
- Subtítulo global por canción y **subtítulos por línea** (editar en la vista de edición, ver en detalle). 💬
- Exportar/Guardar todas las canciones a un archivo `.txt` en una carpeta elegida por el usuario.
- Importar/Cargar canciones desde un archivo `.txt` seleccionado por el usuario.
- Control de tamaño de letra del subtítulo en la vista de detalle.

---

## 🛠 Tecnologías y dependencias

- Lenguaje: **Dart 3**
- Framework: **Flutter** (Multi-plataforma)
- Dependencias relevantes:
  - `file_picker` — selección de archivos / carpetas por parte del usuario
  - `path_provider` — localización de carpetas del sistema
  - `permission_handler` — gestión de permisos de almacenamiento (Android)

> Nota: `file_picker` y el acceso a archivos pueden tener diferencias de comportamiento entre plataformas (Android, iOS, Windows, macOS, Linux). Testea en los objetivos que vayas a soportar.

---

## 🚀 Cómo ejecutar (desarrollo)

1. Instala Flutter y asegúrate de que `flutter doctor` esté limpio.
2. En la raíz del proyecto, instala dependencias:

```bash
flutter pub get
```

3. Ejecuta en emulador/dispositivo:

```bash
flutter run
```

4. Para generar un APK de release:

```bash
flutter build apk --release
```

5. Para generar un AAB (recomendado para Play Store):

```bash
flutter build appbundle --release
```

---

## 💾 Guardar y cargar canciones

- **Guardar**: desde la lista de canciones pulsa `Guardar`, elige carpeta y nombre de archivo `.txt` — se volcará un JSON con todas las canciones.
- **Cargar canciones**: pulsa `Cargar canciones` y selecciona un archivo `.txt` previamente guardado para importar y reemplazar la colección actual.

> Actualmente la importación reemplaza la lista local. Si prefieres otra estrategia (merge/append, deduplicación), puedo añadirla.

---

## 🧪 Tests

Hay pruebas unitarias básicas en la carpeta `test/`. Ejecuta:

```bash
flutter test
```

---

## 🤝 Contribuir

Pull requests y issues son bienvenidos. Revisa el código, ejecuta tests y sigue el estilo del proyecto.

---

## 📜 Licencia

Incluye una licencia si lo deseas (por ejemplo MIT). A falta de otra especificación, asume uso privado.

---

Si quieres, puedo: agregar una sección de **Estructura del proyecto**, generar un `CHANGELOG.md`, o crear un **release** en GitHub y adjuntar el APK compilado.

