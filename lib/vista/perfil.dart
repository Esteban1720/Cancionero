import 'dart:convert';
import 'dart:io';

import 'package:cancionero/componentes/imagenes_seguras.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class PerfilVista extends StatefulWidget {
  const PerfilVista({super.key});

  @override
  State<PerfilVista> createState() => _PerfilVistaState();
}

class _PerfilVistaState extends State<PerfilVista> {
  final TextEditingController nombreController = TextEditingController();
  bool cargando = true;
  bool guardando = false;
  File? nuevaImagen;
  String? fotoActual;
  DateTime? fechaNacimiento;

  @override
  void initState() {
    super.initState();
    cargarPerfil();
  }

  @override
  void dispose() {
    nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final edad = calcularEdad(fechaNacimiento);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: seleccionarImagen,
                      child: nuevaImagen != null
                          ? CircleAvatar(
                              radius: 70,
                              backgroundImage: FileImage(nuevaImagen!),
                            )
                          : AvatarSeguro(
                              imageUrl: fotoActual ?? '',
                              radius: 70,
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Toca el avatar para cambiar tu foto',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informacion personal',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          Text('Edad: ${edad ?? 'Sin registrar'}'),
                          const SizedBox(height: 6),
                          Text(
                            'Fecha de nacimiento: ${textoFecha(fechaNacimiento)}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: guardando ? null : guardarPerfil,
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar cambios'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: publicarFotoOVideo,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Publicar foto o video'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Mis publicaciones',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('publicaciones')
                        .where('uid', isEqualTo: user?.uid)
                        .orderBy('fecha_publicacion', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No hay publicaciones'),
                          ),
                        );
                      }

                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final publicacion =
                              doc.data() as Map<String, dynamic>;
                          final tipo = publicacion['tipo'] ?? 'Foto';
                          final archivoUrl = publicacion['archivo_url'] ?? '';

                          return Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  leading: Icon(
                                    tipo == 'Video'
                                        ? Icons.videocam
                                        : Icons.image,
                                  ),
                                  title: Text(publicacion['descripcion'] ?? ''),
                                  subtitle: Text(tipo),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      eliminarPublicacion(doc.id);
                                    },
                                  ),
                                ),
                                if (archivoUrl.isNotEmpty && tipo == 'Foto')
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: ImagenSegura(
                                      imageUrl: archivoUrl,
                                      height: 180,
                                      width: double.infinity,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                if (archivoUrl.isNotEmpty && tipo == 'Video')
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.play_circle,
                                            size: 60,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(archivoUrl),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> cargarPerfil() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        cargando = false;
      });
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();

    final datos = doc.data();

    if (datos != null) {
      nombreController.text = datos['user'] ?? '';
      fotoActual = datos['foto'];

      final fechaGuardada = datos['fecha_nacimiento'];
      if (fechaGuardada is Timestamp) {
        fechaNacimiento = fechaGuardada.toDate();
      } else if (fechaGuardada is DateTime) {
        fechaNacimiento = fechaGuardada;
      }
    }

    setState(() {
      cargando = false;
    });
  }

  Future<void> seleccionarImagen() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        nuevaImagen = File(image.path);
      });
    }
  }

  Future<void> guardarPerfil() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      guardando = true;
    });

    String? foto = fotoActual;

    if (nuevaImagen != null) {
      foto = await subirArchivoACloudinary(nuevaImagen!, 'Foto');
    }

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .update({
          'user': nombreController.text.trim(),
          'user_lower': nombreController.text.trim().toLowerCase(),
          'foto': foto,
        });

    setState(() {
      fotoActual = foto;
      guardando = false;
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
  }

  Future<void> publicarFotoOVideo() async {
    final descripcionController = TextEditingController();
    String tipo = 'Foto';

    final resultado = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Nueva publicacion'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descripcionController,
                    decoration: const InputDecoration(labelText: 'Descripcion'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    items: const [
                      DropdownMenuItem(value: 'Foto', child: Text('Foto')),
                      DropdownMenuItem(value: 'Video', child: Text('Video')),
                    ],
                    onChanged: (value) {
                      setStateDialog(() {
                        tipo = value ?? 'Foto';
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'descripcion': descripcionController.text.trim(),
                      'tipo': tipo,
                    });
                  },
                  child: const Text('Continuar'),
                ),
              ],
            );
          },
        );
      },
    );

    descripcionController.dispose();

    if (resultado == null) {
      return;
    }

    final picker = ImagePicker();
    XFile? archivo;

    if (resultado['tipo'] == 'Video') {
      archivo = await picker.pickVideo(source: ImageSource.gallery);
    } else {
      archivo = await picker.pickImage(source: ImageSource.gallery);
    }

    if (archivo == null) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final docUsuario = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .get();
    final misDatos = docUsuario.data() ?? {};

    final archivoUrl = await subirArchivoACloudinary(
      File(archivo.path),
      resultado['tipo']!,
    );

    await FirebaseFirestore.instance.collection('publicaciones').add({
      'uid': user.uid,
      'nombre': misDatos['user'] ?? 'Usuario',
      'foto_usuario': misDatos['foto'] ?? '',
      'tipo': resultado['tipo'],
      'descripcion': resultado['descripcion'],
      'archivo_url': archivoUrl ?? '',
      'fecha_publicacion': FieldValue.serverTimestamp(),
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Publicacion creada')));
  }

  Future<void> eliminarPublicacion(String publicacionId) async {
    await FirebaseFirestore.instance
        .collection('publicaciones')
        .doc(publicacionId)
        .delete();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Publicacion eliminada')));
  }

  Future<String?> subirArchivoACloudinary(File archivo, String tipo) async {
    final endpoint = tipo == 'Video' ? 'video/upload' : 'image/upload';
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/df963uwem/$endpoint',
    );

    var request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = 'rutacity';
    request.files.add(await http.MultipartFile.fromPath('file', archivo.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      final res = await http.Response.fromStream(response);
      final data = json.decode(res.body);
      return data['secure_url'];
    }

    return null;
  }

  int? calcularEdad(DateTime? fecha) {
    if (fecha == null) {
      return null;
    }

    final hoy = DateTime.now();
    int edad = hoy.year - fecha.year;

    if (hoy.month < fecha.month ||
        (hoy.month == fecha.month && hoy.day < fecha.day)) {
      edad--;
    }

    return edad;
  }

  String textoFecha(DateTime? fecha) {
    if (fecha == null) {
      return 'Sin registrar';
    }

    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}
