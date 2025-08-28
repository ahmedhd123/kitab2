import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/services.dart';
// ignore: avoid_web_libraries_in_flutter
// استبدلنا فتح التبويب المخصص بعرض مدمج PDF.js
// نستخدم platformViewRegistry لتسجيل iframe للويب
// ignore: avoid_web_libraries_in_flutter
// تم الاستغناء عن الاستخدام المباشر لـ dart:html في هذا الملف
import 'pdf_iframe_stub.dart' if (dart.library.html) 'pdf_iframe_web.dart';
import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../../services/auth_service.dart';
import '../../services/auth_firebase_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/epub_reader_widget.dart';
import '../../widgets/pdf_reader_widget.dart';

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
  bool _immersiveUI = false; // واجهة غامرة: إخفاء AppBar والعناصر الجانبية

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
    // تفعيل نمط الواجهة الغامرة للنظام
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
      setState(() => _isLoading = true);

      if (kIsWeb) {
        _localFilePath = widget.book!.fileUrl;
        _isLoading = false;
        if (mounted) setState(() {});
        return;
      }

      final src = widget.book!.fileUrl.trim();
      final fileType = widget.book!.fileType.toLowerCase();

      // لا تحاول تنزيل EPUB هنا (سيتم معالجته داخل EpubReaderWidget)
      if (fileType == 'epub') {
        _isLoading = false;
        if (mounted) setState(() {});
        return;
      }

      // اعتبره PDF إن كان النوع PDF حتى لو كان الرابط لا ينتهي بـ .pdf
      List<int> bytes = <int>[];

      // دعم روابط Firebase Storage بصيغة gs://
      try {
        if (src.startsWith('gs://')) {
          // تجلب رابط التحميل المباشر
          // ملاحظة: يتطلب firebase_storage في pubspec (موجود بالفعل)
          // التجميع الشرطي لتفادي أخطاء الويب غير ضروري هنا لأن هذا الفرع على الأجهزة فقط
          // ignore: avoid_dynamic_calls
          final storage = firebase_storage.FirebaseStorage.instance;
          final downloadUrl = await storage.refFromURL(src).getDownloadURL();
          final resp = await http.get(Uri.parse(downloadUrl));
          if (resp.statusCode != 200) throw 'HTTP ${resp.statusCode}';
          bytes = resp.bodyBytes;
        }
      } catch (_) {
        // سنجرب المسارات الأخرى أدناه
      }

      if (bytes.isEmpty) {
        if (src.startsWith('assets/')) {
          final data = await rootBundle.load(src);
          bytes = data.buffer.asUint8List();
        } else if (src.startsWith('http://') || src.startsWith('https://')) {
          // اتبع التحويلات وتجاوز مشاكل بعض الرؤوس
          final resp = await http.get(Uri.parse(src));
          if (resp.statusCode != 200) throw 'HTTP ${resp.statusCode}';
          bytes = resp.bodyBytes;
        } else {
          final f = File(src);
          if (!(await f.exists())) throw 'الملف غير موجود';
          bytes = await f.readAsBytes();
        }
      }

      // احفظ لملف محلي مع امتداد .pdf لضمان عمل flutter_pdfview
      final docsDir = await getApplicationDocumentsDirectory();
      final srcName = src.split('?').first.split('/').last;
      final baseName = srcName.isEmpty ? 'book' : srcName;
      final outName = baseName.toLowerCase().endsWith('.pdf') ? baseName : '$baseName.pdf';
      final localFile = File('${docsDir.path}/$outName');
      await localFile.writeAsBytes(bytes, flush: true);
      _localFilePath = localFile.path;

      _isLoading = false;
      if (mounted) setState(() {});
    } catch (e) {
      _isLoading = false;
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تحميل الملف: $e'),
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
    // إعادة واجهة النظام
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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

  void _toggleImmersive() {
    setState(() => _immersiveUI = !_immersiveUI);
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleImmersive, // النقر يبدّل إظهار/إخفاء الواجهة
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _immersiveUI
            ? null
            : AppBar(
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
            : Column(children: [
                if (conflict != null && !_immersiveUI)
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
        bottomNavigationBar: _shouldShowPdfControls() && !_immersiveUI ? _buildBottomControls() : null,
      ),
    );
  }

  bool _shouldShowPdfControls() {
    final ext = widget.book!.fileType.toLowerCase();
    return !kIsWeb && ext == 'pdf' && _localFilePath != null;
  }

  Widget _buildReader() {
    final ext = widget.book!.fileType.toLowerCase();
    if (ext == 'pdf') return _buildPDFReader();
    if (ext == 'epub') return _buildEPUBReader();
    // fallback PDF renderer (requires local path)
    if (_localFilePath == null) {
      return const Center(child: Text('تعذر تحميل الملف'));
    }
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

  Widget _buildPDFReader() {
    if (kIsWeb) {
      final pdfUrl = _localFilePath ?? widget.book!.fileUrl;
      final viewerUrl = Uri.encodeFull('https://mozilla.github.io/pdf.js/web/viewer.html?file=$pdfUrl');
      return Container(
        color: Colors.black,
        child: HtmlElementView(
          viewType: _registerPdfIFrame(viewerUrl),
        ),
      );
    }
    if (_localFilePath == null) {
      return const Center(child: Text('تعذر تحميل ملف PDF'));
    }
    return PdfReaderWidget(book: widget.book!, localFilePath: _localFilePath!);
  }

  // تسجيل IFrameView لعرض PDF عبر PDF.js (ويب فقط)
  String _registerPdfIFrame(String url) {
    final viewType = 'pdfjs_viewer_${widget.book?.id ?? 'temp'}';
    if (!kIsWeb) return viewType;
    registerPdfIframe(viewType, url);
    return viewType;
  }

  Widget _buildEPUBReader() {
    final auth = Provider.of<AuthFirebaseService>(context, listen: false);
    final userId = auth.currentUser?.uid ?? 'guest';
    
    print('إنشاء EPUB Reader:');
    print('- مسار الملف: ${widget.book!.fileUrl}');
    print('- نوع الملف: ${widget.book!.fileType}');
    print('- معرف المستخدم: $userId');
    print('- معرف الكتاب: ${widget.book!.id}');
    
    return EpubReaderWidget(
      sourcePath: widget.book!.fileUrl,
      bookService: Provider.of<BookService>(context, listen: false),
      userId: userId,
      bookId: widget.book!.id,
    );
  }

  Widget _buildBottomControls() {
    return Semantics(
      container: true,
      label: 'شريط التحكم في صفحات الكتاب',
      child: Container(
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
            Semantics(
              button: true,
              enabled: _currentPage > 1,
              label: 'الانتقال إلى الصفحة السابقة',
              child: IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage > 1 ? _previousPage : null,
              ),
            ),
            
            // معلومات الصفحة
            Text(
              '$_currentPage من $_totalPages',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            // الصفحة التالية
            Semantics(
              button: true,
              enabled: _currentPage < _totalPages,
              label: 'الانتقال إلى الصفحة التالية',
              child: IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage < _totalPages ? _nextPage : null,
              ),
            ),
          ],
        ),
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
