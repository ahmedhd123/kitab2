import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../../services/auth_service.dart';
import '../../services/auth_firebase_service.dart';
import '../../services/theme_service.dart';

class BookReaderScreen extends StatefulWidget {
  final BookModel? book;
  
  const BookReaderScreen({super.key, this.book});

  @override
  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  bool _isLoading = true;
  String? _localFilePath;
  int _currentPage = 1;
  int _totalPages = 0;
  double _progress = 0.0;
  late DateTime _readingStartTime;
  // تمت إزالة دعم Syncfusion مؤقتاً بسبب تعارض الإصدارات مع intl
  // PdfViewerController _pdfController = PdfViewerController(); // معطل حالياً

  @override
  void initState() {
    super.initState();
    _readingStartTime = DateTime.now();
    if (widget.book != null) {
      _downloadAndOpenBook();
      // بعد الإطار الأول لضمان توافر Providers
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadRemoteReadingProgress();
      });
    }
  }

  Future<void> _loadRemoteReadingProgress() async {
    final book = widget.book;
    if (book == null || !mounted) return;

    // محاولة الحصول على المستخدم من Firebase أولاً ثم من الخدمة البسيطة
    String? userId;
    try {
      final firebaseAuth = Provider.of<AuthFirebaseService>(context, listen: false);
      userId = firebaseAuth.currentUser?.uid;
    } catch (_) {
      // قد لا يكون مسجلاً
    }
    if (userId == null) {
      try {
        final legacyAuth = Provider.of<AuthService>(context, listen: false);
        userId = legacyAuth.currentUser?.uid;
      } catch (_) {}
    }
    if (userId == null) return; // لا يوجد مستخدم

    try {
      final bookService = Provider.of<BookService>(context, listen: false);
      final remote = await bookService.syncReadingProgressFromRemote(book.id, userId);
      if (remote != null && mounted) {
        setState(() {
          _currentPage = remote.currentPage.clamp(1, remote.totalPages).toInt();
          _totalPages = remote.totalPages; // قد تُحدث لاحقاً عند onRender
          _progress = remote.progressPercentage;
        });
      }
    } catch (e) {
      // تجاهل الخطأ بصمت الآن؛ يمكن لاحقاً إضافة Snackbar
    }
  }

  Future<void> _downloadAndOpenBook() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (kIsWeb) {
        // على الويب: سنعرض رسالة أن التحميل المحلي غير مطلوب حالياً
        setState(() {
          _localFilePath = widget.book!.fileUrl; // سيُستخدم رمزياً
          _isLoading = false;
        });
        return;
      }

      // نسخة من ملف PDF الموجود في assets إلى مجلد مؤقت
      final assetPath = widget.book!.fileUrl; // مثال: assets/books/sample.pdf
      if (!assetPath.toLowerCase().endsWith('.pdf')) {
        throw 'فقط ملفات PDF مدعومة حالياً في النسخة التجريبية';
      }

      // قراءة البايتات من الأصول
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final fileName = assetPath.split('/').last;
      final localFile = File('${directory.path}/$fileName');
      await localFile.writeAsBytes(bytes, flush: true);

      setState(() {
        _localFilePath = localFile.path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الكتاب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateProgress() {
    if (_totalPages > 0) {
      final newProgress = _currentPage / _totalPages;
      if (newProgress != _progress) {
        setState(() {
          _progress = newProgress;
        });

        // حفظ التقدم في القراءة
        // تفضيل Firebase Auth إن وُجد وإلا fallback إلى AuthService
        String? userId;
        try {
          final firebaseAuth = Provider.of<AuthFirebaseService>(context, listen: false);
          userId = firebaseAuth.currentUser?.uid;
        } catch (_) {}
        if (userId == null) {
          final legacy = Provider.of<AuthService>(context, listen: false);
          userId = legacy.currentUser?.uid;
        }
        final bookService = Provider.of<BookService>(context, listen: false);
        
        if (userId != null && widget.book != null) {
          // measure elapsed reading time since last checkpoint
          final readingTime = DateTime.now().difference(_readingStartTime);
          _readingStartTime = DateTime.now();

          bookService.updateReadingProgress(
            bookId: widget.book!.id,
            userId: userId,
            currentPage: _currentPage,
            totalPages: _totalPages,
            additionalReadingTime: readingTime,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    // save final progress before disposing
    try {
      if (widget.book != null) {
        final bookService = Provider.of<BookService>(context, listen: false);
        String? userId;
        try {
          final firebaseAuth = Provider.of<AuthFirebaseService>(context, listen: false);
          userId = firebaseAuth.currentUser?.uid;
        } catch (_) {}
        if (userId != null) {
          final readingTime = DateTime.now().difference(_readingStartTime);
          bookService.updateReadingProgress(
            bookId: widget.book!.id,
            userId: userId,
            currentPage: _currentPage,
            totalPages: _totalPages,
            additionalReadingTime: readingTime,
          );
        }
      }
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('قارئ الكتب')),
        body: const Center(
          child: Text('لم يتم تحديد كتاب للقراءة'),
        ),
      );
    }

  final bookService = Provider.of<BookService>(context);
  final auth = Provider.of<AuthFirebaseService>(context, listen: false);
  final conflict = auth.currentUser != null ? bookService.getConflict(widget.book!.id, auth.currentUser!.uid) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.book!.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // sync indicator
          Builder(builder: (ctx) {
            final svc = Provider.of<BookService>(ctx);
            final auth = Provider.of<AuthFirebaseService>(ctx, listen: false);
            final status = auth.currentUser != null ? svc.getSyncStatus(widget.book!.id, auth.currentUser!.uid) : 'idle';
            final color = status == 'syncing' ? Colors.orangeAccent : (status == 'success' ? Colors.greenAccent : (status == 'failed' ? Colors.redAccent : Colors.white));
            return IconButton(
              tooltip: 'Sync status: $status',
              icon: Icon(Icons.sync, color: color),
              onPressed: () {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('حالة المزامنة: $status')));
              },
            );
          }),
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () {
              // TODO: إضافة علامة مرجعية
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showReaderSettings();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _localFilePath == null
              ? const Center(child: Text('فشل في تحميل الكتاب'))
              : Column(children: [
                  if (conflict != null)
                    MaterialBanner(
                      content: const Text('تم العثور على تعارض بين تقدم القراءة المحلي والسحابي.'),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            // choose remote
                            try {
                              final remote = conflict['remote']!;
                              await bookService.syncReadingProgressFromRemote(widget.book!.id, auth.currentUser!.uid);
                              // apply remote
                              setState(() {
                                _currentPage = remote.currentPage;
                                _totalPages = remote.totalPages;
                                _progress = remote.progressPercentage;
                              });
                            } catch (_) {}
                          },
                          child: const Text('اعتمد النسخة السحابية'),
                        ),
                        TextButton(
                          onPressed: () async {
                            // choose local (re-upload)
                            try {
                              final local = conflict['local']!;
                              await bookService.updateReadingProgress(
                                bookId: local.bookId,
                                userId: local.userId,
                                currentPage: local.currentPage,
                                totalPages: local.totalPages,
                                additionalReadingTime: local.readingTime,
                                bookmarks: local.bookmarks,
                                highlights: local.highlights,
                              );
                              bookService.clearConflict(widget.book!.id, auth.currentUser!.uid);
                            } catch (_) {}
                          },
                          child: const Text('اعتمد النسخة المحلية'),
                        ),
                        TextButton(
                          onPressed: () async {
                            // automatic merge: already stored in syncReadingProgressFromRemote previously, so just clear
                            bookService.clearConflict(widget.book!.id, auth.currentUser!.uid);
                          },
                          child: const Text('دمج تلقائي'),
                        ),
                      ],
                    ),
                  Expanded(child: _buildReader()),
                ]),
      bottomNavigationBar: _localFilePath != null ? _buildBottomControls() : null,
    );
  }

  Widget _buildReader() {
    if (widget.book!.fileType.toLowerCase() == 'pdf') {
      return _buildPDFReader();
    } else if (widget.book!.fileType.toLowerCase() == 'epub') {
      return _buildEPUBReader();
    } else {
      return const Center(
        child: Text('نوع الملف غير مدعوم'),
      );
    }
  }

  Widget _buildPDFReader() {
    if (kIsWeb) {
      // Placeholder للويب حتى نعيد دمج syncfusion أو بديل متوافق
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'عرض PDF في الويب قيد التعليق مؤقتاً',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'تم تعطيل الحزمة بسبب تعارض الإصدارات (intl). سنعيد التفعيل لاحقاً.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    // المنصات الأخرى: الاستمرار باستخدام flutter_pdfview
    return PDFView(
      filePath: _localFilePath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      defaultPage: _currentPage - 1,
      fitPolicy: FitPolicy.WIDTH,
      onRender: (pages) {
        setState(() {
          _totalPages = pages ?? 0;
        });
      },
      onPageChanged: (page, total) {
        setState(() {
          _currentPage = (page ?? 0) + 1;
        });
        _updateProgress();
      },
      onError: (error) {
        debugPrint('خطأ في PDF: $error');
      },
    );
  }

  Widget _buildEPUBReader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'قارئ EPUB',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'ميزة قراءة EPUB قيد التطوير',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // TODO: تنفيذ قارئ EPUB
            },
            child: const Text('فتح الكتاب'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // الصفحة السابقة
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage > 1 ? _previousPage : null,
          ),
          
          // معلومات الصفحة
          Text(
            '$_currentPage من $_totalPages',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          
          // الصفحة التالية
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage < _totalPages ? _nextPage : null,
          ),
        ],
      ),
    );
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _updateProgress();
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
      _updateProgress();
    }
  }

  void _showReaderSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'إعدادات القراءة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            
                   ListTile(
                     leading: const Icon(Icons.brightness_6),
                     title: const Text('وضع القراءة الليلي'),
                     trailing: Consumer<ThemeService>(
                       builder: (context, themeService, child) => Switch(
                         value: themeService.isDark,
                         onChanged: (value) => themeService.toggle(),
                       ),
                     ),
                   ),
            
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('حجم النص'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      // TODO: تقليل حجم النص
                    },
                  ),
                  const Text('16'),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      // TODO: زيادة حجم النص
                    },
                  ),
                ],
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('مشاركة الكتاب'),
              onTap: () {
                Navigator.pop(context);
                _shareBook();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareBook() {
    // TODO: تنفيذ مشاركة الكتاب
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ميزة المشاركة قيد التطوير'),
      ),
    );
  }
}
