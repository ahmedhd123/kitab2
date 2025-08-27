// استخدام تصدير شرطي لتوفير تنفيذ خاص بالويب فقط
// وعلى المنصات الأخرى (مثل Android/iOS) يتم استخدام بديل خامد لا يقوم بأي إجراء.
export 'web_optimizations_stub.dart'
  if (dart.library.html) 'web_optimizations_web.dart';
