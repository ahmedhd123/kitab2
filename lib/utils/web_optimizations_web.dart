import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// تحسينات خاصة بالويب والهواتف المحمولة (تنفيذ الويب)
class WebOptimizations {
  static void initialize() {
    if (!kIsWeb) return;
    _hideLoadingScreen();
    _optimizeForMobile();
    _addMobileMetaTags();
    _optimizeViewport();
    debugPrint('تم تفعيل تحسينات الويب للهواتف المحمولة');
  }

  static void _hideLoadingScreen() {
    try {
      final loading = html.document.querySelector('#loading');
      if (loading != null) {
        loading.style.opacity = '0';
        loading.style.transition = 'opacity 0.3s ease-out';
        Future.delayed(const Duration(milliseconds: 300), () {
          loading.remove();
        });
      }
    } catch (e) {
      debugPrint('فشل في إخفاء شاشة التحميل: $e');
    }
  }

  static void _optimizeForMobile() {
    try {
      final isMobile = _isMobileDevice();
      if (!isMobile) return;
      html.document.documentElement?.style.setProperty('height', '100vh');
      html.document.documentElement?.style.setProperty('height', '-webkit-fill-available');
      html.document.documentElement?.style.setProperty('overflow', 'hidden');
      html.document.documentElement?.style.setProperty('position', 'fixed');
      html.document.body?.style.setProperty('height', '100vh');
      html.document.body?.style.setProperty('height', '-webkit-fill-available');
      html.document.body?.style.setProperty('overflow', 'hidden');
      html.document.body?.style.setProperty('position', 'fixed');
      html.document.body?.style.setProperty('top', '0');
      html.document.body?.style.setProperty('left', '0');
      html.document.body?.style.setProperty('width', '100vw');
      _preventInputZoom();
    } catch (e) {
      debugPrint('فشل في تحسين الهواتف المحمولة: $e');
    }
  }

  static void _addMobileMetaTags() {
    try {
      final head = html.document.head;
      if (head == null) return;
      var viewport = html.document.querySelector('meta[name="viewport"]');
      if (viewport == null) {
        final meta = html.MetaElement()
          ..name = 'viewport'
          ..content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
        head.append(meta);
      }
      final mobileTags = [
        {'name': 'format-detection', 'content': 'telephone=no'},
        {'name': 'msapplication-tap-highlight', 'content': 'no'},
        {'name': 'mobile-web-app-capable', 'content': 'yes'},
        {'name': 'apple-mobile-web-app-capable', 'content': 'yes'},
        {'name': 'apple-mobile-web-app-status-bar-style', 'content': 'black-translucent'},
      ];
      for (final tag in mobileTags) {
        if (html.document.querySelector('meta[name="${tag['name']}"]') == null) {
          final meta = html.MetaElement()
            ..name = tag['name']!
            ..content = tag['content']!;
          head.append(meta);
        }
      }
    } catch (e) {
      debugPrint('فشل في إضافة meta tags: $e');
    }
  }

  static void _optimizeViewport() {
    try {
      if (!_isMobileDevice()) return;
      Future.delayed(const Duration(milliseconds: 100), () {
        html.window.scrollTo(0, 1);
        Future.delayed(const Duration(milliseconds: 50), () {
          html.window.scrollTo(0, 0);
        });
      });
      html.window.addEventListener('orientationchange', (event) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _optimizeForMobile();
        });
      });
    } catch (e) {
      debugPrint('فشل في تحسين viewport: $e');
    }
  }

  static void _preventInputZoom() {
    try {
      final inputs = html.document.querySelectorAll('input, textarea, select');
      for (final input in inputs) {
        (input as dynamic).style.fontSize = '16px';
      }
    } catch (e) {
      debugPrint('فشل في منع input zoom: $e');
    }
  }

  static bool _isMobileDevice() {
    final userAgent = html.window.navigator.userAgent;
    return RegExp(r'Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini', caseSensitive: false)
        .hasMatch(userAgent);
  }

  static bool _isIOS() {
    final userAgent = html.window.navigator.userAgent;
    return RegExp(r'iPad|iPhone|iPod', caseSensitive: false).hasMatch(userAgent);
  }

  static bool _isAndroid() {
    final userAgent = html.window.navigator.userAgent;
    return userAgent.contains('Android');
  }
}
