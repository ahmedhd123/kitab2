import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';

import '../services/book_service.dart';

/// Safer EPUB reader: unzip EPUB and render plain-text chapters with search and manual highlight saving.
class EpubReaderWidget extends StatefulWidget {
  final String sourcePath;
  final BookService bookService;
  final String userId;
  final String bookId;

  const EpubReaderWidget({super.key, required this.sourcePath, required this.bookService, required this.userId, required this.bookId});

  @override
  State<EpubReaderWidget> createState() => _EpubReaderWidgetState();
}

class _EpubReaderWidgetState extends State<EpubReaderWidget> {
  List<_Chapter> _chapters = [];
  int _index = 0;
  bool _loading = true;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      List<int> bytes;
      if (widget.sourcePath.startsWith('assets/')) {
        final data = await DefaultAssetBundle.of(context).load(widget.sourcePath);
        bytes = data.buffer.asUint8List();
      } else {
        bytes = await File(widget.sourcePath).readAsBytes();
      }

      final archive = ZipDecoder().decodeBytes(bytes);
      final htmlFiles = <ArchiveFile>[];
      for (final f in archive) {
        final name = f.name.toLowerCase();
        if (name.endsWith('.html') || name.endsWith('.xhtml') || name.endsWith('.htm')) htmlFiles.add(f);
      }
      htmlFiles.sort((a, b) => a.name.compareTo(b.name));
      final list = <_Chapter>[];
      for (final f in htmlFiles) {
        try {
          final content = utf8.decode(f.content as List<int>);
          final plain = _stripHtml(content);
          list.add(_Chapter(title: f.name, text: plain));
        } catch (_) {}
      }
      if (mounted) setState(() => _chapters = list);
    } catch (e) {
      debugPrint('Failed to open EPUB: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _onSearch(String q) {
    setState(() => _filter = q.trim());
  }

  Future<void> _addHighlight() async {
    final text = await showDialog<String?>(context: context, builder: (ctx) {
      String value = '';
      return AlertDialog(
        title: const Text('أضف تمييز'),
        content: TextField(
          autofocus: true,
          maxLines: null,
          onChanged: (v) => value = v,
          decoration: const InputDecoration(hintText: 'الصق أو اكتب النص المميز هنا'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, value.trim()), child: const Text('حفظ')),
        ],
      );
    });
    if (text != null && text.isNotEmpty) {
      final progress = widget.bookService.getReadingProgress(widget.bookId, widget.userId);
      final updated = Map<String, dynamic>.from(progress?.highlights ?? {});
      final key = _index.toString();
      final list = List<String>.from(updated[key] ?? []);
      list.add(text);
      updated[key] = list;
      await widget.bookService.updateReadingProgress(
        bookId: widget.bookId,
        userId: widget.userId,
        currentPage: progress?.currentPage ?? 1,
        totalPages: progress?.totalPages ?? _chapters.length,
        highlights: updated,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التمييز')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_chapters.isEmpty) return const Center(child: Text('لا توجد محتويات EPUB لعرضها'));

    final current = _chapters[_index];
    final display = _filter.isEmpty
        ? current.text
        : current.text.replaceAllMapped(RegExp(RegExp.escape(_filter), caseSensitive: false), (m) => '«${m[0]}»');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث في الكتاب'),
                  onSubmitted: _onSearch,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_add),
                onPressed: _addHighlight,
                tooltip: 'أضف تمييز (انسخ النص ثم اضغط لحفظه)',
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(display, textAlign: TextAlign.right),
          ),
        ),
        SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _index > 0 ? () => setState(() => _index--) : null,
              ),
              Text('${_index + 1} / ${_chapters.length}'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _index < _chapters.length - 1 ? () => setState(() => _index++) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chapter {
  final String title;
  final String text;
  _Chapter({required this.title, required this.text});
}
