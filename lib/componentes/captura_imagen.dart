import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

typedef OnImageSelected = Function(File imageFile);

class ImagePickerWidget extends StatelessWidget {
  final File? imageFile;
  final OnImageSelected onImageSelected;
  const ImagePickerWidget({
    super.key,
    required this.imageFile,
    required this.onImageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.transparent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        image: imageFile != null
            ? DecorationImage(image: FileImage(imageFile!), fit: BoxFit.cover)
            : null,
      ),
      child: IconButton(
        iconSize: 100,
        icon: Icon(Icons.camera_alt),
        onPressed: () {
          _showPickerOptions(context);
        },
      ),
    );
  }

  void _showPickerOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text("Camara"),
              onTap: () {
                Navigator.pop(context);
                _showPickImage(context, ImageSource.camera);
              },
            ), // ListTile
            ListTile(
              leading: Icon(Icons.image),
              title: Text("Galeria"),
              onTap: () {
                Navigator.pop(context);
                _showPickImage(context, ImageSource.gallery);
              },
            ), // ListTile
          ], // <Widget>[]
        ); // SimpleDialog
      },
    );
  }

  void _showPickImage(BuildContext context, source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      onImageSelected(File(image.path));
    }
  }
}
