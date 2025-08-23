import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../services/book_service.dart';

/// Safer EPUB reader: unzip EPUB, extract plain-text chapters with search and manual highlight saving.
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
  double _fontSize = 16;
  bool _localDark = false; // وضع ليلي محلي مستقل عن الثيم العام
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      print('تحميل EPUB من: ${widget.sourcePath}');
      List<int> bytes;
      if (widget.sourcePath.startsWith('assets/')) {
        // Use rootBundle to load packaged assets so we don't depend on the
        // widget's BuildContext (prevents "deactivated widget's ancestor" errors
        // when the widget is disposed while an async load is in-flight).
        final data = await rootBundle.load(widget.sourcePath);
        bytes = data.buffer.asUint8List();
        print('تم تحميل ${bytes.length} بايت من assets');
      } else if (widget.sourcePath.startsWith('http://') || widget.sourcePath.startsWith('https://')) {
        try {
          final resp = await http.get(
            Uri.parse(widget.sourcePath),
            headers: {
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
              'Access-Control-Allow-Headers': '*',
            },
          );
          if (resp.statusCode != 200) {
            throw 'HTTP ${resp.statusCode}';
          }
          bytes = resp.bodyBytes;
          print('تم تحميل ${bytes.length} بايت من URL');
        } catch (e) {
          print('فشل تحميل الملف من URL: $e');
          // محاولة تحميل عبر iframe أو طريقة بديلة للويب
          if (kIsWeb) {
            throw 'لا يمكن تحميل ملفات EPUB من Firebase Storage مباشرة على الويب. يرجى استخدام التطبيق على جهاز محلي أو رفع الكتب كملفات محلية.';
          }
          rethrow;
        }
      } else {
        bytes = await File(widget.sourcePath).readAsBytes();
        print('تم تحميل ${bytes.length} بايت من ملف محلي');
      }

      print('فك ضغط الأرشيف...');
      final archive = ZipDecoder().decodeBytes(bytes);
      print('عدد ملفات الأرشيف: ${archive.length}');
      
      final htmlFiles = <ArchiveFile>[];
      for (final f in archive) {
        final name = f.name.toLowerCase();
        print('ملف: ${f.name}');
        if (name.endsWith('.html') || name.endsWith('.xhtml') || name.endsWith('.htm')) {
          htmlFiles.add(f);
          print('  -> ملف HTML/XHTML');
        }
      }
      
      print('عدد ملفات HTML المكتشفة: ${htmlFiles.length}');
      htmlFiles.sort((a, b) => a.name.compareTo(b.name));
      
      final list = <_Chapter>[];
      for (final f in htmlFiles) {
        try {
          print('معالجة ملف: ${f.name}');
          final content = utf8.decode(f.content as List<int>);
          print('طول المحتوى: ${content.length} حرف');
          
          // عرض بداية المحتوى للتشخيص
          final preview = content.length > 200 ? content.substring(0, 200) : content;
          print('بداية المحتوى: $preview');
          
          if (content.length < 10) { // تقليل الحد الأدنى
            print('محتوى قصير جداً أو فارغ');
            continue;
          }
          
          final parsed = _parseHtmlToParagraphs(content);
          print('عدد الفقرات المستخرجة: ${parsed.length}');
          
          // إضافة الفصل حتى لو كان فارغاً مؤقتاً للتشخيص
          list.add(_Chapter(title: f.name, paragraphs: parsed));
          print('تمت إضافة فصل: ${f.name} (${parsed.length} فقرات)');
        } catch (e) {
          print('خطأ في معالجة ${f.name}: $e');
        }
      }
      
      print('إجمالي الفصول المُنشأة: ${list.length}');
      if (mounted) setState(() => _chapters = list);
      
      // مزامنة عدد الصفحات (الفصول) كتقدم أولي
      if (widget.userId.isNotEmpty && _chapters.isNotEmpty) {
        final progress = widget.bookService.getReadingProgress(widget.bookId, widget.userId);
        await widget.bookService.updateReadingProgress(
          bookId: widget.bookId,
          userId: widget.userId,
          currentPage: progress?.currentPage ?? 1,
          totalPages: _chapters.length,
        );
      }
    } catch (e) {
      debugPrint('Failed to open EPUB: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // تحويل HTML إلى قائمة فقرات مع دعم الصور والتنسيق المتقدم
  List<_Paragraph> _parseHtmlToParagraphs(String html) {
    print('تحليل HTML بطول ${html.length} حرف');
    
    // إزالة السكربت والستايل
    html = html.replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), '')
               .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '');
    
    print('بعد تنظيف HTML: ${html.length} حرف');
    
    final blocks = <_Paragraph>[];
    
    // استخراج وحفظ الصور أولاً
    final imageRegex = RegExp(r'<img[^>]+src=["\' "'" r']([^"\' "'" r']+)["\' + "'" + r'][^>]*>', caseSensitive: false);
    final imageMatches = imageRegex.allMatches(html);
    final images = <String>[];
    for (final match in imageMatches) {
      final src = match.group(1) ?? '';
      if (src.isNotEmpty) {
        images.add(src);
        print('صورة مكتشفة: $src');
      }
    }
    
    // إلتقاط العناوين
    final headingRegex = RegExp(r'<h([1-6])[^>]*>(.*?)</h\1>', caseSensitive: false, dotAll: true);
    // مؤقت: استبدال العناوين بعلامات فريدة ثم إعادة تقسيم
    int markerId = 0;
    final markers = <String, _Paragraph>{};
    html = html.replaceAllMapped(headingRegex, (m) {
      final level = int.tryParse(m.group(1) ?? '1') ?? 1;
      final inner = _basicInline(m.group(2) ?? '')
          .replaceAll(RegExp(r'\s+'), ' ') // تنظيف
          .trim();
      final marker = '§§HDR$markerId§§';
      markers[marker] = _Paragraph(inner, ParagraphType.heading, headingLevel: level);
      markerId++;
      print('عنوان مكتشف: $inner (مستوى $level)');
      return marker;
    });
    
    // تقسيم على فقرات <p> أو أسطر مزدوجة
    final parts = html.split(RegExp(r'</p>|<p[^>]*>')); // تفكيك بسيط
    print('عدد الأجزاء بعد التقسيم: ${parts.length}');
    
    for (var raw in parts) {
      raw = raw.trim();
      if (raw.isEmpty) continue;
      if (markers.containsKey(raw)) {
        blocks.add(markers[raw]!);
        continue;
      }
      
      // إدراج الصور في النص
      final imageInText = RegExp(r'<img[^>]+>', caseSensitive: false);
      if (imageInText.hasMatch(raw)) {
        // نص يحتوي على صورة - نعتبرها فقرة صورة
        blocks.add(_Paragraph('[صورة]', ParagraphType.image, imageUrl: images.isNotEmpty ? images.first : null));
        // إزالة وسم الصورة من النص
        raw = raw.replaceAll(imageInText, '');
        print('صورة مضافة كفقرة');
      }
      
      // إزالة أي وسوم متبقية
      final text = _basicInline(raw)
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (text.isNotEmpty) {
        blocks.add(_Paragraph(text, ParagraphType.text));
        print('فقرة نص مضافة: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
      }
    }
    
    if (blocks.isEmpty) {
      print('لا توجد فقرات، محاولة استخراج النص الخام...');
      final fallback = _basicInline(html)
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      
      if (fallback.isNotEmpty) {
        // تقسيم النص الطويل إلى فقرات أصغر
        final sentences = fallback.split(RegExp(r'[.!?]\s+'));
        for (int i = 0; i < sentences.length; i += 3) {
          final chunk = sentences.skip(i).take(3).join('. ');
          if (chunk.trim().isNotEmpty) {
            blocks.add(_Paragraph(chunk.trim(), ParagraphType.text));
          }
        }
        print('تم إنشاء ${blocks.length} فقرات احتياطية من النص الخام');
      } else {
        print('حتى النص الاحتياطي فارغ!');
        // كحل أخير، إضافة فقرة واحدة تحتوي على HTML الخام (لأغراض التشخيص)
        if (html.trim().isNotEmpty) {
          blocks.add(_Paragraph('محتوى خام: ${html.substring(0, html.length > 100 ? 100 : html.length)}...', ParagraphType.text));
          print('تمت إضافة فقرة تشخيصية للمحتوى الخام');
        }
      }
    }
    
    print('إجمالي الفقرات المُنشأة: ${blocks.length}');
    return blocks;
  }

  String _basicInline(String html) {
    // استبدال break
    html = html.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    // تحسين الرموز الشائعة
    return html;
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
    
    if (_chapters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.orange.shade600,
              ),
              const SizedBox(height: 16),
              const Text(
                'لا توجد محتويات EPUB لعرضها',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              kIsWeb 
                ? const Text(
                    'ملاحظة: قراءة كتب EPUB من Firebase Storage غير مدعومة حالياً على المتصفح بسبب قيود الأمان.\n\nلقراءة كتب EPUB، يرجى:\n• استخدام التطبيق على الكمبيوتر أو الهاتف\n• أو رفع الكتب كملفات PDF بدلاً من EPUB',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  )
                : const Text(
                    'تأكد من أن الملف صحيح وأنك متصل بالإنترنت',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('العودة'),
              ),
            ],
          ),
        ),
      );
    }

    final current = _chapters[_index];
    final paragraphs = current.paragraphs;

    final theme = Theme.of(context);
    final bg = _localDark ? Colors.black : theme.scaffoldBackgroundColor;
    final fg = _localDark ? Colors.white70 : theme.textTheme.bodyLarge?.color ?? Colors.black87;

    List<Widget> widgets = [];

    for (final p in paragraphs) {
      var txt = p.text;
      if (_filter.isNotEmpty) {
        final regex = RegExp(RegExp.escape(_filter), caseSensitive: false);
        txt = txt.replaceAllMapped(regex, (m) => '«${m[0]}»');
      }
      
      if (p.type == ParagraphType.image) {
        // عرض الصور
        if (p.imageUrl != null && p.imageUrl!.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _loadEpubImage(p.imageUrl!),
              ),
            ),
          );
        }
        continue;
      }
      
      TextStyle style;
      if (p.type == ParagraphType.heading) {
        final scale = (7 - (p.headingLevel ?? 2)).clamp(1, 6); // عكس المستوى لتكبير h1
        style = theme.textTheme.titleLarge!.copyWith(
          fontSize: _fontSize + (6 - scale) * 2,
          fontWeight: FontWeight.w700,
          color: fg,
        );
      } else {
        style = theme.textTheme.bodyLarge!.copyWith(
          fontSize: _fontSize,
          height: 1.55,
          color: fg,
        );
      }
      
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: SelectableText(
            txt,
            style: style,
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: Container(
            color: bg,
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widgets,
              ),
            ),
          ),
        ),
        SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _index > 0
                    ? () async {
                        setState(() => _index--);
                        await _savePageProgress();
                      }
                    : null,
              ),
              Text('${_index + 1} / ${_chapters.length}'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _index < _chapters.length - 1
                    ? () async {
                        setState(() => _index++);
                        await _savePageProgress();
                      }
                    : null,
              ),
            ],
          ),
        ),
        _buildSliderBar(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _localDark ? Colors.grey.shade900 : Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(.2))),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search, size: 18),
              hintText: 'ابحث في النص الحالي',
            ),
            onSubmitted: _onSearch,
          ),
        ),
        const SizedBox(width: 6),
        _iconBtn(Icons.remove, () => setState(() => _fontSize = (_fontSize - 2).clamp(12, 40))),
        Text(_fontSize.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
        _iconBtn(Icons.add, () => setState(() => _fontSize = (_fontSize + 2).clamp(12, 40))),
        const SizedBox(width: 6),
        _iconBtn(_localDark ? Icons.dark_mode : Icons.light_mode, () => setState(() => _localDark = !_localDark)),
        _iconBtn(Icons.bookmark_add, _addHighlight),
      ]),
    );
  }

  // تحميل صور من ملف EPUB
  Widget _loadEpubImage(String imageSrc) {
    try {
      // محاولة قراءة الصورة من ملف EPUB
      if (widget.sourcePath.startsWith('http')) {
        // إذا كان مسار الكتاب URL، لا يمكن استخراج الصور بسهولة
        return Container(
          height: 150,
          width: double.infinity,
          color: Colors.grey.shade200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_download, size: 48, color: Colors.grey.shade600),
              const SizedBox(height: 8),
              Text('الصور غير مدعومة من الروابط الخارجية', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        );
      }

      // للملفات المحلية، يمكن تحسين هذا لاحقاً
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 8),
            Text('صورة: ${imageSrc.split('/').last}', 
                 style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      );
      
    } catch (e) {
      print('خطأ في تحميل الصورة: $e');
    }
    
    // في حالة الفشل، عرض رمز بديل
    return Container(
      height: 100,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 48),
          SizedBox(height: 8),
          Text('صورة غير متاحة'),
        ],
      ),
    );
  }

  Widget _buildSliderBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(children: [
          const Icon(Icons.menu_book, size: 18),
          Expanded(
            child: Slider(
              value: (_index + 1).toDouble(),
              min: 1,
              max: _chapters.isEmpty ? 1 : _chapters.length.toDouble(),
              divisions: _chapters.isEmpty ? 1 : _chapters.length - 1,
              label: 'الفصل ${_index + 1}',
              onChanged: (v) async {
                final newIndex = v.toInt() - 1;
                if (newIndex != _index) {
                  setState(() => _index = newIndex);
                  await _savePageProgress();
                }
              },
            ),
          ),
          Text('${((_index + 1) / (_chapters.isEmpty ? 1 : _chapters.length) * 100).toStringAsFixed(0)}%'),
        ]),
      ),
    );
  }

  Widget _iconBtn(IconData ic, VoidCallback onTap) => IconButton(
        icon: Icon(ic, size: 20),
        visualDensity: VisualDensity.compact,
        onPressed: onTap,
        tooltip: '',
      );

  Future<void> _savePageProgress() async {
    if (widget.userId.isEmpty) return;
    await widget.bookService.updateReadingProgress(
      bookId: widget.bookId,
      userId: widget.userId,
      currentPage: _index + 1,
      totalPages: _chapters.length,
      scrollOffset: _scroll.hasClients ? _scroll.offset : 0.0,
    );
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    // حفظ متقطع كل ~800ms عند التمرير
    if (_pendingSave) return;
    if (widget.userId.isEmpty) return;
    _pendingSave = true;
    Future.delayed(const Duration(milliseconds: 800), () async {
      _pendingSave = false;
      if (!mounted) return;
      await widget.bookService.updateReadingProgress(
        bookId: widget.bookId,
        userId: widget.userId,
        currentPage: _index + 1,
        totalPages: _chapters.length,
        scrollOffset: _scroll.offset,
      );
    });
  }

  bool _pendingSave = false;
}

class _Chapter {
  final String title;
  final List<_Paragraph> paragraphs;
  _Chapter({required this.title, required this.paragraphs});
}

enum ParagraphType { heading, text, image }

class _Paragraph {
  final String text;
  final ParagraphType type;
  final int? headingLevel;
  final String? imageUrl;
  _Paragraph(this.text, this.type, {this.headingLevel, this.imageUrl});
}
