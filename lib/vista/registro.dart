import 'dart:convert';
import 'dart:io';

import 'package:cancionero/componentes/captura_imagen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Registro extends StatefulWidget {
  const Registro({super.key});

  @override
  State<Registro> createState() => _RegistroState();
}

class _RegistroState extends State<Registro> {
  final _formKey2 = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController fechaController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;
  File? imageFile;
  DateTime? fechaNacimiento;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 2, 180, 250),
                  Color.fromARGB(121, 10, 6, 255),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: const SizedBox.expand(),
          ),
          ImagePickerWidget(
            imageFile: imageFile,
            onImageSelected: (File image) {
              setState(() {
                imageFile = image;
              });
            },
          ),
          SizedBox(
            height: kToolbarHeight + 25,
            child: AppBar(
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              backgroundColor: Colors.transparent,
            ),
          ),
          Center(
            child: Transform.translate(
              offset: const Offset(0, -40),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 260,
                  bottom: 20,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TextFormField(
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            keyboardType: TextInputType.emailAddress,
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: 'Correo:',
                              labelStyle: TextStyle(fontSize: 20.1),
                              prefixIcon: Icon(Icons.email),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese el correo';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 40),
                          TextFormField(
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            controller: userController,
                            decoration: const InputDecoration(
                              labelText: 'Usuario:',
                              labelStyle: TextStyle(fontSize: 20.1),
                              prefixIcon: Icon(Icons.person),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese el usuario';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 40),
                          TextFormField(
                            controller: fechaController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Fecha de nacimiento',
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onTap: () {
                              seleccionarFecha(context);
                            },
                          ),
                          const SizedBox(height: 40),
                          TextFormField(
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            controller: passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contrasena:',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              labelStyle: const TextStyle(fontSize: 20.1),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingrese la contrasena';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: Theme.of(context).primaryColor,
                            ),
                            onPressed: () {
                              if (_formKey2.currentState?.validate() ?? false) {
                                if (imageFile == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Seleccione una imagen'),
                                    ),
                                  );
                                  return;
                                }
                                if (fechaNacimiento == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Seleccione su fecha de nacimiento',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                _register();
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const Text(
                                  'Registrar',
                                  style: TextStyle(color: Colors.white),
                                ),
                                if (_loading)
                                  Container(
                                    height: 20,
                                    width: 20,
                                    margin: const EdgeInsets.only(left: 20),
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> seleccionarFecha(BuildContext context) async {
    DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (fecha != null) {
      setState(() {
        fechaNacimiento = fecha;
        fechaController.text = '${fecha.day}/${fecha.month}/${fecha.year}';
      });
    }
  }

  void _register() async {
    setState(() {
      _loading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await subirImagenACloudinary(imageFile!);
      }

      String uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'user': userController.text.trim(),
        'user_lower': userController.text.trim().toLowerCase(),
        'email': emailController.text.trim(),
        'fecha_registro': FieldValue.serverTimestamp(),
        'foto': imageUrl,
        'fecha_nacimiento': fechaNacimiento,
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado correctamente')),
      );

      Navigator.of(context).pushReplacementNamed('/dashboard');
    } on FirebaseAuthException catch (e) {
      String message = 'Error al registrar usuario';

      if (e.code == 'email-already-in-use') {
        message = 'Este correo ya esta registrado';
      }

      if (e.code == 'weak-password') {
        message = 'La contrasena es muy debil';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<String?> subirImagenACloudinary(File imageFile) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/df963uwem/image/upload',
    );

    var request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = 'rutacity';
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      final res = await http.Response.fromStream(response);
      final data = json.decode(res.body);
      return data['secure_url'];
    }

    return null;
  }
}
