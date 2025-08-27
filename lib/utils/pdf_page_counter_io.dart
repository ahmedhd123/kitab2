import 'dart:typed_data';
import 'package:pdfx/pdfx.dart';

Future<int> countPdfPages(Uint8List bytes) async {
  try {
    final doc = await PdfDocument.openData(bytes);
    final pages = doc.pagesCount;
    await doc.close();
    return pages;
  } catch (_) {
    return 0;
  }
}
