import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProductImage({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    final trimmedImage = image.trim();

    if (trimmedImage.isEmpty) {
      child = _buildFallback();
    } else if (_isRemoteImage(trimmedImage)) {
      child = Image.network(
        trimmedImage,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, widget, progress) {
          if (progress == null) {
            return widget;
          }

          return _buildLoading();
        },
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    } else {
      child = Image.asset(
        trimmedImage,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }

    return child;
  }

  bool _isRemoteImage(String value) {
    final normalized = value.toLowerCase();
    return normalized.startsWith('http://') || normalized.startsWith('https://');
  }

  Widget _buildLoading() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}
