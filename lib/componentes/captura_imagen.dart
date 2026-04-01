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
    return GestureDetector(
      onTap: () => _mostrarOpciones(context),
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          image: imageFile != null
              ? DecorationImage(image: FileImage(imageFile!), fit: BoxFit.cover)
              : null,
        ),
        child: Container(
          color: imageFile != null ? Colors.black.withValues(alpha: 0.18) : Colors.transparent,
          padding: const EdgeInsets.all(20),
          child: const Align(
            alignment: Alignment(0, 0.35),
            child: Icon(Icons.camera_alt, size: 108, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarOpciones(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
                bottom: Radius.circular(24),
              ),
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 2, 180, 250),
                  Color.fromARGB(255, 10, 6, 255),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Tomar foto',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Elegir de galeria',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    await _showPickImage(source);
  }

  Future<void> _showPickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      onImageSelected(File(image.path));
    }
  }
}
