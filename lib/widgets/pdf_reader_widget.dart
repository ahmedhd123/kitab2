import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/book_service.dart';
import '../services/auth_firebase_service.dart';
import '../models/book_model.dart';
import '../utils/enhanced_design_tokens.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:url_launcher/url_launcher.dart';

// وضع القارئ لملفات PDF
enum PdfReaderMode { light, sepia, night }

/// قارئ PDF داخلي محسن (لغير الويب حالياً) مع شريط أدوات ومزامنة أسرع
class PdfReaderWidget extends StatefulWidget {
  final BookModel book;
  final String localFilePath; // مسار محلي جاهز
  const PdfReaderWidget({super.key, required this.book, required this.localFilePath});

  @override
  State<PdfReaderWidget> createState() => _PdfReaderWidgetState();
}

class _PdfReaderWidgetState extends State<PdfReaderWidget> {
  int _total = 0;
  int _page = 1;
  double _progress = 0;
  bool _showUI = false; // بدء مخفي
  Timer? _autoHide;
  final Duration _autoHideDelay = const Duration(seconds: 5);
  // مؤشر صفحات عابر
  bool _showPageToast = false;
  Timer? _pageToastTimer;
  DateTime _readingStart = DateTime.now();
  Timer? _remoteSyncTimer; // مزامنة أسرع مع السحابة
  bool _updating = false;
  final ValueNotifier<double> _fontScale = ValueNotifier(1.0); // محاكاة التكبير (مستقبلاً مع مكتبة أخرى)

  // أوضاع القراءة المستقلة
  PdfReaderMode _mode = PdfReaderMode.light;

  // متحكم لعرض PDF للقفز للصفحات
  PDFViewController? _pdfController;

  double _brightness = 0.8; // سطوع افتراضي داخل القارئ
  bool _brightLoaded = false;
  double _tapZoom = 1.0; // تمهيد لدعم التكبير بالنقر المزدوج

  @override
  void initState() {
    super.initState();
    _startRemoteSyncLoop();
    // لا تبدأ المؤقت إلا عند إظهار الواجهة
    _loadReaderSettings();
    // تفعيل وضع ملء الشاشة الغامر
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // إبقاء الشاشة فعّالة أثناء القراءة
    WakelockPlus.enable();
    _initBrightness();
  }

  Future<void> _initBrightness() async {
    try {
      final current = await ScreenBrightness().current;
      setState(() { _brightness = current; _brightLoaded = true; });
    } catch (_) {
      setState(() { _brightLoaded = true; });
    }
  }

  Future<void> _loadReaderSettings() async {
    try {
      final auth = Provider.of<AuthFirebaseService>(context, listen: false);
      final uid = auth.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('readerSettings')
          .doc(widget.book.id)
          .get();
      final m = (doc.data()?['pdfMode'] as String?) ?? 'light';
      setState(() {
        _mode = switch (m) {
          'sepia' => PdfReaderMode.sepia,
          'night' => PdfReaderMode.night,
          _ => PdfReaderMode.light,
        };
      });
    } catch (_) {}
  }

  Future<void> _saveReaderSettings() async {
    try {
      final auth = Provider.of<AuthFirebaseService>(context, listen: false);
      final uid = auth.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('readerSettings')
          .doc(widget.book.id)
          .set({'pdfMode': _mode.name}, SetOptions(merge: true));
    } catch (_) {}
  }

  void _startRemoteSyncLoop() {
    _remoteSyncTimer?.cancel();
    _remoteSyncTimer = Timer.periodic(const Duration(seconds: 25), (_) async {
      if (!mounted) return;
      final auth = Provider.of<AuthFirebaseService>(context, listen: false);
      final uid = auth.currentUser?.uid;
      if (uid == null) return;
      try {
        await Provider.of<BookService>(context, listen: false)
            .syncReadingProgressFromRemote(widget.book.id, uid);
      } catch (_) {}
    });
  }

  void _restartHideTimer() {
    _autoHide?.cancel();
    _autoHide = Timer(_autoHideDelay, () {
      if (mounted) setState(() => _showUI = false);
    });
  }

  void _toggleUI() {
    setState(() => _showUI = !_showUI);
    if (_showUI) _restartHideTimer();
  }

  void _showPageToastBrief() {
    _pageToastTimer?.cancel();
    setState(() => _showPageToast = true);
    _pageToastTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showPageToast = false);
    });
  }

  Future<void> _saveProgress({bool force = false}) async {
    if (_total == 0) return;
    if (_updating && !force) return;
    _updating = true;
    final auth = Provider.of<AuthFirebaseService>(context, listen: false);
    final uid = auth.currentUser?.uid;
    if (uid != null) {
      final svc = Provider.of<BookService>(context, listen: false);
      final readingTime = DateTime.now().difference(_readingStart);
      _readingStart = DateTime.now();
      await svc.updateReadingProgress(
        bookId: widget.book.id,
        userId: uid,
        currentPage: _page,
        totalPages: _total,
        additionalReadingTime: readingTime,
      );
    }
    _updating = false;
  }

  @override
  void dispose() {
    _autoHide?.cancel();
    _remoteSyncTimer?.cancel();
    _saveProgress(force: true); // حفظ أخير
    // دفع فوري للحالة المتراكمة
    try {
      final auth = Provider.of<AuthFirebaseService>(context, listen: false);
      final uid = auth.currentUser?.uid;
      if (uid != null) {
        Provider.of<BookService>(context, listen: false).flushProgress(uid, widget.book.id);
      }
    } catch (_) {}
    // إعادة واجهة النظام لوضعها الطبيعي
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // إلغاء إبقاء الشاشة مفعّلة
    WakelockPlus.disable();
    super.dispose();
  }

  Color get _bgColor => switch (_mode) {
        PdfReaderMode.night => Colors.black,
        PdfReaderMode.sepia => EnhancedAppColors.paperYellow,
        _ => Colors.white,
      };

  Color get _fgColor => switch (_mode) {
        PdfReaderMode.night => Colors.white70,
        PdfReaderMode.sepia => EnhancedAppColors.paperInk,
        _ => EnhancedAppColors.gray900,
      };

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Center(child: Text('قارئ PDF المحسن غير مدعوم بعد على الويب'));
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleUI,
      onDoubleTap: () {
        setState(() {
          _tapZoom = (_tapZoom == 1.0) ? 1.4 : 1.0; // تكبير/تصغير بسيط مبدئي
        });
      },
      child: Stack(children: [
        // مناطق نقر للتنقل السريع يمين/يسار
        Positioned.fill(
          child: Row(children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () async {
                  try { final p = (_page - 2).clamp(0, _total - 1); await _pdfController?.setPage(p); } catch (_) {}
                },
              ),
            ),
            Expanded(flex: 6, child: Container(color: Colors.transparent)),
            Expanded(
              flex: 2,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () async {
                  try { final p = (_page).clamp(0, _total - 1); await _pdfController?.setPage(p); } catch (_) {}
                },
              ),
            ),
          ]),
        ),
        // خلفية حسب وضع القراءة
        Positioned.fill(child: Container(color: _bgColor)),
        Positioned.fill(
          child: Transform.scale(
            scale: _tapZoom,
            child: PDFView(
              filePath: widget.localFilePath,
              defaultPage: _page - 1,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: true,
              pageSnap: true,
              fitPolicy: FitPolicy.WIDTH, // ملاءمة المحتوى لعرض الشاشة
              onViewCreated: (c) => _pdfController = c,
              onRender: (pages) {
                setState(() => _total = pages ?? 0);
                _saveProgress();
              },
              onPageChanged: (p, t) {
                setState(() {
                  _page = (p ?? 0) + 1;
                  _total = t ?? _total;
                  _progress = _total == 0 ? 0 : _page / _total;
                });
                _saveProgress();
                if (_showUI) _restartHideTimer();
                _showPageToastBrief();
              },
              onError: (e) => debugPrint('PDF error: $e'),
            ),
          ),
        ),
        // مؤشر صفحات خفيف الظهور أثناء الواجهة المخفية
        if (_showPageToast && !_showUI)
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _showPageToast ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_page.toString().padLeft(2, '0')} / ${_total.toString().padLeft(2, '0')} • ${(_progress * 100).toStringAsFixed(0)}%'
                        .trim(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        if (_showUI) ...[
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar(context)),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar(context)),
        ],
      ]),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(.65), Colors.black.withOpacity(.15)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: 'إغلاق',
          ),
          Expanded(
            child: Text(
              widget.book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          // التحكم بالحجم (مبدئي)
          ValueListenableBuilder<double>(
            valueListenable: _fontScale,
            builder: (_, scale, __) => Row(children: [
              _iconBtn(Icons.remove, () => _fontScale.value = (scale - .1).clamp(.5, 2.0)),
              Text('${(scale * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 12)),
              _iconBtn(Icons.add, () => _fontScale.value = (scale + .1).clamp(.5, 2.0)),
            ]),
          ),
          const SizedBox(width: 6),
          // تبديل وضع القراءة: قائمة منبثقة لاختيار (فاتح/سبيا/ليلي)
          PopupMenuButton<PdfReaderMode>(
            tooltip: 'وضع القراءة',
            icon: const Icon(Icons.color_lens, color: Colors.white),
            onSelected: (m) async {
              setState(() => _mode = m);
              await _saveReaderSettings();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: PdfReaderMode.light, child: _modeItem('فاتح', Icons.wb_sunny)),
              PopupMenuItem(value: PdfReaderMode.sepia, child: _modeItem('سبيا', Icons.style)),
              PopupMenuItem(value: PdfReaderMode.night, child: _modeItem('ليلي', Icons.nightlight_round)),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _modeItem(String text, IconData icon) {
    return Row(children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(text)]);
  }

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(.55),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(.08))),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Text(
              '${_page.toString().padLeft(2, '0')}/${_total.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Slider(
                value: _page.toDouble().clamp(1, (_total == 0 ? 1 : _total).toDouble()),
                min: 1,
                max: _total == 0 ? 1 : _total.toDouble(),
                divisions: _total > 1 ? _total - 1 : 1,
                label: 'صفحة $_page',
                onChanged: (v) {
                  setState(() => _page = v.toInt());
                },
                onChangeEnd: (v) async {
                  final target = v.toInt().clamp(1, _total) - 1;
                  try {
                    await _pdfController?.setPage(target);
                  } catch (_) {}
                  _saveProgress();
                },
              ),
            ),
            const SizedBox(width: 12),
            Text('${(_progress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          // شريط سطوع الشاشة
          if (_brightLoaded)
            Row(children: [
              const Icon(Icons.brightness_6, color: Colors.white70, size: 18),
              Expanded(
                child: Slider(
                  value: _brightness.clamp(0.0, 1.0),
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: 'سطوع ${( (_brightness) * 100).toInt()}%'.toString(),
                  onChanged: (v) async {
                    setState(() => _brightness = v);
                    try { await ScreenBrightness().setScreenBrightness(v); } catch (_) {}
                  },
                ),
              ),
            ]),
        ]),
      ),
    );
  }

  Widget _iconBtn(IconData ic, VoidCallback onTap) => IconButton(
        onPressed: onTap,
        icon: Icon(ic, color: Colors.white, size: 18),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      );
}
