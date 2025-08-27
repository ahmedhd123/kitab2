import 'dart:typed_data';

// على الويب نتجنب pdfx لتفادي متطلبات pdf.js ضمن index.html
// نعيد 0 ليدل على استخدام التقدير التقريبي الموجود مسبقاً
Future<int> countPdfPages(Uint8List bytes) async {
  return 0;
}
