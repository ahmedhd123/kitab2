import 'package:flutter/material.dart';

/// أداة تحميل صورة آمنة مع محاولات بديلة للمسار عند الفشل (مفيد للويب)
class SafeImage extends StatefulWidget {
  final String? assetPath; // يمكن أن تكون مسار أصول أو رابط شبكة
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
  State<SafeImage> createState() => _SafeImageState();
}

class _SafeImageState extends State<SafeImage> {
  late String? _currentPath;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.assetPath;
  }

  String? _alternate(String? p) {
    if (p == null || p.isEmpty) return p;
    if (p.startsWith('assets/')) return p.substring('assets/'.length);
    return 'assets/$p';
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);

    if (_currentPath == null || _currentPath!.isEmpty) {
      return _fallback(radius);
    }

    final isNetwork = _currentPath!.startsWith('http://') || _currentPath!.startsWith('https://');

    Widget imageWidget;
    if (isNetwork) {
      imageWidget = Image.network(
        _currentPath!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (c, e, st) => _fallback(radius),
      );
    } else {
      imageWidget = Image.asset(
        _currentPath!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (c, e, st) {
          if (_attempt == 0) {
            _attempt = 1;
            final alt = _alternate(_currentPath);
            if (alt != null && alt != _currentPath) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _currentPath = alt);
              });
              return widget.placeholder ?? SizedBox(width: widget.width, height: widget.height, child: const Center(child: CircularProgressIndicator()));
            }
          }
          return _fallback(radius);
        },
      );
    }

    return ClipRRect(borderRadius: radius, child: imageWidget);
  }

  Widget _fallback(BorderRadius r) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: r,
        color: Colors.grey.shade200,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey.shade500,
        size: (widget.width != null) ? (widget.width! * .4).clamp(24, 48) : 32,
      ),
    );
  }
}
