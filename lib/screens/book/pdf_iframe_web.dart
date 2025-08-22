// Web implementation: register iframe view factory
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// إزالة استيراد flutter_web_plugins لتفادي الخطأ؛ سنحاول الوصول إلى registrar عبر JS
import 'dart:js' as js;

final Set<String> _pdfRegistered = <String>{};

void registerPdfIframe(String viewType, String url) {
  if (_pdfRegistered.contains(viewType)) return;
  // محاولة استخدام registrar العالمي إن توفر
  try {
    final registrar = js.context['flutter_view_registrar'];
    if (registrar != null) {
      // استدعاء registerViewFactory(dynamic viewType, Function factory)
      // ignore: avoid_dynamic_calls
      registrar.callMethod('registerViewFactory', [viewType, (int id) {
        final iframe = html.IFrameElement()
          ..src = url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        return iframe;
      }]);
      _pdfRegistered.add(viewType);
      return;
    }
  } catch (_) {}
  // لم نتمكن من التسجيل؛ يمكن لاحقاً إضافة مسار احتياطي
  return;
}
