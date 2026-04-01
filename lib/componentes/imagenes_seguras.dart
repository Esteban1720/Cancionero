import 'package:flutter/material.dart';

class AvatarSeguro extends StatelessWidget {
  final String imageUrl;
  final double radius;

  const AvatarSeguro({super.key, required this.imageUrl, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blue.shade100,
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.person, size: radius);
                },
              )
            : Icon(Icons.person, size: radius),
      ),
    );
  }
}

class ImagenSegura extends StatelessWidget {
  final String imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final FilterQuality filterQuality;

  const ImagenSegura({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.filterQuality = FilterQuality.high,
  });

  @override
  Widget build(BuildContext context) {
    final contenido = imageUrl.isNotEmpty
        ? Image.network(
            imageUrl,
            height: height,
            width: width,
            fit: fit,
            filterQuality: filterQuality,
            errorBuilder: (context, error, stackTrace) {
              return contenedorError();
            },
          )
        : contenedorError();

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: contenido);
    }

    return contenido;
  }

  Widget contenedorError() {
    return Container(
      height: height,
      width: width,
      color: Colors.black12,
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 40),
    );
  }
}
