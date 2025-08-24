import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart'; // لحساب عدد صفحات PDF بدقة

import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../../services/auth_firebase_service.dart';

class UploadBookScreen extends StatefulWidget {
  const UploadBookScreen({super.key});

  @override
  State<UploadBookScreen> createState() => _UploadBookScreenState();
}

class _UploadBookScreenState extends State<UploadBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _authorBioCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  DateTime? _releaseDate;
  String _category = 'الكل';
  String? _fileName;
  Uint8List? _fileBytes;
  String? _fileType;
  Uint8List? _coverBytes;
  String? _coverName;
  bool _isUploading = false;
  double _progress = 0.0;
  int _estimatedPages = 0;

  void _estimatePageCount() {
    if (_fileBytes == null || _fileType == null) return;
    // تقدير بسيط: حجم الملف بالكيلوبايت / ثابت تقريبي
    final kb = _fileBytes!.lengthInBytes / 1024;
    if (_fileType == 'pdf') {
      // متوسط 50KB لكل صفحة (تقريبي)
      _estimatedPages = (kb / 50).clamp(1, 2000).round();
    } else if (_fileType == 'epub') {
      // EPUB مضغوط؛ نفترض 35KB لكل صفحة نصية تقريبية
      _estimatedPages = (kb / 35).clamp(1, 3000).round();
    }
    setState(() {});
  }

  // محاولة الحصول على عدد الصفحات الحقيقي لملف PDF (إن أمكن)
  Future<void> _refinePdfPageCount() async {
    if (_fileBytes == null || _fileType != 'pdf') return;
    try {
      final doc = await PdfDocument.openData(_fileBytes!);
      final realPages = doc.pagesCount;
      if (realPages > 0 && realPages != _estimatedPages) {
        setState(() => _estimatedPages = realPages);
      }
      await doc.close();
    } catch (e) {
      // تجاهل الخطأ ونبقى على التقدير التقريبي
    }
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(
      withData: true,
      allowedExtensions: ['pdf', 'epub'],
      type: FileType.custom,
    );
    if (res == null) return;
    final file = res.files.first;
    setState(() {
      _fileName = file.name;
      _fileBytes = file.bytes;
      _fileType = file.extension?.toLowerCase();
    });
    _estimatePageCount(); // تقدير أولي سريع
    // تحسين العدد الحقيقي في الخلفية لملف PDF
    _refinePdfPageCount();
  }

  Future<void> _pickCover() async {
    final res = await FilePicker.platform.pickFiles(
      withData: true,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      type: FileType.custom,
    );
    if (res == null) return;
    final file = res.files.first;
    setState(() { _coverBytes = file.bytes; _coverName = file.name; });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fileBytes == null || _fileName == null || _fileType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر ملف PDF أو EPUB قبل المتابعة')));
      return;
    }

    final auth = Provider.of<AuthFirebaseService>(context, listen: false);
    final uid = auth.currentUser?.uid ?? 'anonymous';

    final bookId = DateTime.now().millisecondsSinceEpoch.toString();
    final book = BookModel(
      id: bookId,
      title: _titleCtrl.text.trim(),
      author: _authorCtrl.text.trim(),
  authorBio: _authorBioCtrl.text.trim(),
  description: _descCtrl.text.trim(),
      category: _category,
      coverImageUrl: '',
  bookSummary: _summaryCtrl.text.trim(),
      fileUrl: '',
      fileType: _fileType ?? 'pdf',
      averageRating: 0.0,
      totalReviews: 0,
      downloadCount: 0,
      uploadedBy: uid,
      createdAt: DateTime.now(),
      updatedAt: null,
  releaseDate: _releaseDate,
      tags: [],
  pageCount: _estimatedPages,
      language: 'ar',
    );

    setState(() => _isUploading = true);
    try {
      final bookService = Provider.of<BookService>(context, listen: false);
  final contentType = (_fileType == 'pdf') ? 'application/pdf' : 'application/epub+zip';
      final fileUrl = await bookService.uploadAndAddBook(
        book: book,
        fileName: _fileName!,
        bytes: _fileBytes!.toList(),
        contentType: contentType,
        onProgress: (p) => setState(() => _progress = p),
      );

      // رفع صورة الغلاف إن وُجدت بعد رفع الملف (تحديث الكتاب)
      if (fileUrl != null && _coverBytes != null) {
        await bookService.updateBook(
          book.copyWith(fileUrl: fileUrl),
          coverImageBytes: _coverBytes!.toList(),
          coverImageContentType: 'image/${_coverName!.toLowerCase().endsWith('png') ? 'png' : 'jpeg'}',
        );
      }

      if (fileUrl != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفع الكتاب بنجاح')));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل في رفع الكتاب')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
  _authorBioCtrl.dispose();
  _descCtrl.dispose();
  _summaryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رفع كتاب')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'العنوان'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل عنوان الكتاب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _authorCtrl,
                  decoration: const InputDecoration(labelText: 'المؤلف'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل اسم المؤلف' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _authorBioCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'نبذة عن المؤلف'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _summaryCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'نبذة عن الكتاب'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'الوصف التفصيلي (اختياري)'),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: DateTime(1900),
                          lastDate: DateTime(now.year + 5),
                        );
                        if (picked != null) setState(() => _releaseDate = picked);
                      },
                      icon: const Icon(Icons.date_range),
                      label: Text(_releaseDate == null ? 'تاريخ الإصدار' : _releaseDate!.toString().split(' ').first),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickCover,
                      icon: const Icon(Icons.image),
                      label: Text(_coverName ?? 'صورة الغلاف'),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    isExpanded: true,
                    items: BookService.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _category = v ?? 'الكل'),
                    decoration: const InputDecoration(labelText: 'الفئة'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: Text(_fileName ?? 'اختر ملف (PDF/EPUB)'),
                    ),
                  ),
                ]),
                if (_estimatedPages > 0) ...[
                  const SizedBox(height: 8),
                  Text('تقدير الصفحات: $_estimatedPages صفحة', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 18),
                if (_isUploading) ...[
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: 12),
                  Text('${(_progress * 100).toStringAsFixed(0)}%'),
                  const SizedBox(height: 12),
                ],
                ElevatedButton(
                  onPressed: _isUploading ? null : _submit,
                  child: _isUploading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('ارفع الكتاب'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

