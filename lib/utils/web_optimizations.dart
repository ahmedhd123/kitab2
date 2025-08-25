import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

/// تحسينات خاصة بالويب والهواتف المحمولة
class WebOptimizations {
  
  /// تهيئة تحسينات الويب
  static void initialize() {
    if (!kIsWeb) return;
    
    // إخفاء loading screen عند تحميل Flutter
    _hideLoadingScreen();
    
    // تحسين الأداء على الهواتف المحمولة
    _optimizeForMobile();
    
    // إضافة meta tags للهواتف المحمولة
    _addMobileMetaTags();
    
    // تحسين viewport للهواتف المحمولة
    _optimizeViewport();
    
    debugPrint('تم تفعيل تحسينات الويب للهواتف المحمولة');
  }
  
  /// إخفاء شاشة التحميل
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
  
  /// تحسينات خاصة بالهواتف المحمولة
  static void _optimizeForMobile() {
    try {
      // كشف الهواتف المحمولة
      final isMobile = _isMobileDevice();
      if (!isMobile) return;
      
      // تحسين العرض للهواتف المحمولة
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
      
      // منع الـ zoom عند focus على inputs
      _preventInputZoom();
      
    } catch (e) {
      debugPrint('فشل في تحسين الهواتف المحمولة: $e');
    }
  }
  
  /// إضافة meta tags للهواتف المحمولة
  static void _addMobileMetaTags() {
    try {
      final head = html.document.head;
      if (head == null) return;
      
      // التأكد من وجود viewport صحيح
      var viewport = html.document.querySelector('meta[name="viewport"]');
      if (viewport == null) {
        viewport = html.MetaElement()
          ..name = 'viewport'
          ..content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
        head.append(viewport);
      }
      
      // إضافة meta tags إضافية للهواتف المحمولة
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
  
  /// تحسين viewport للهواتف المحمولة
  static void _optimizeViewport() {
    try {
      if (!_isMobileDevice()) return;
      
      // إخفاء شريط العنوان على الهواتف المحمولة
      Future.delayed(const Duration(milliseconds: 100), () {
        html.window.scrollTo(0, 1);
        Future.delayed(const Duration(milliseconds: 50), () {
          html.window.scrollTo(0, 0);
        });
      });
      
      // التعامل مع تغيير الاتجاه
      html.window.addEventListener('orientationchange', (event) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _optimizeForMobile();
        });
      });
      
    } catch (e) {
      debugPrint('فشل في تحسين viewport: $e');
    }
  }
  
  /// منع الـ zoom عند focus على inputs
  static void _preventInputZoom() {
    try {
      final inputs = html.document.querySelectorAll('input, textarea, select');
      for (final input in inputs) {
        if (input is html.InputElement || input is html.TextAreaElement || input is html.SelectElement) {
          input.style.fontSize = '16px';
        }
      }
    } catch (e) {
      debugPrint('فشل في منع input zoom: $e');
    }
  }
  
  /// كشف الهواتف المحمولة
  static bool _isMobileDevice() {
    final userAgent = html.window.navigator.userAgent;
    return RegExp(r'Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini', caseSensitive: false)
        .hasMatch(userAgent);
  }
  
  /// كشف iOS
  static bool _isIOS() {
    final userAgent = html.window.navigator.userAgent;
    return RegExp(r'iPad|iPhone|iPod', caseSensitive: false).hasMatch(userAgent);
  }
  
  /// كشف Android
  static bool _isAndroid() {
    final userAgent = html.window.navigator.userAgent;
    return userAgent.contains('Android');
  }
}
