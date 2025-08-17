import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

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
  String _category = 'الكل';
  String? _fileName;
  Uint8List? _fileBytes;
  String? _fileType;
  bool _isUploading = false;
  double _progress = 0.0;

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
      description: '',
      category: _category,
      coverImageUrl: '',
      fileUrl: '',
      fileType: _fileType ?? 'pdf',
      averageRating: 0.0,
      totalReviews: 0,
      downloadCount: 0,
      uploadedBy: uid,
      createdAt: DateTime.now(),
      updatedAt: null,
      tags: [],
      pageCount: 0,
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

