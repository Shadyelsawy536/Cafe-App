import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// One place that decides how every product/add-on image loads, caches, and
/// fails gracefully. If image hosting ever changes, this is the only file
/// that needs to change — every screen picks it up automatically.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
        ),
        errorWidget: (_, __, ___) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.local_cafe, color: Colors.grey),
        ),
      ),
    );
  }
}
