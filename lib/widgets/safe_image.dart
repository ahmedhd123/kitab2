import 'package:flutter/material.dart';

/// أداة تحميل صورة آمنة مع fallback عند الفشل أو المسار الفارغ
class SafeImage extends StatelessWidget {
  final String? assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  const SafeImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);

    if (assetPath == null || assetPath!.isEmpty) {
      return _fallback(radius);
    }

    return ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        assetPath!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (c, e, st) => _fallback(radius),
      ),
    );
  }

  Widget _fallback(BorderRadius r) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: r,
        color: Colors.grey.shade200,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey.shade500,
        size: (width != null) ? (width! * .4).clamp(24, 48) : 32,
      ),
    );
  }
}
