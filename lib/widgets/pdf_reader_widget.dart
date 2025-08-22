import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../services/book_service.dart';
import '../services/auth_firebase_service.dart';
import '../models/book_model.dart';

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
  bool _showUI = true;
  Timer? _autoHide;
  final Duration _autoHideDelay = const Duration(seconds: 5);
  DateTime _readingStart = DateTime.now();
  Timer? _remoteSyncTimer; // مزامنة أسرع مع السحابة
  bool _updating = false;
  final ValueNotifier<double> _fontScale = ValueNotifier(1.0); // محاكاة التكبير (مستقبلاً مع مكتبة أخرى)

  @override
  void initState() {
    super.initState();
    _startRemoteSyncLoop();
    _restartHideTimer();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Center(child: Text('قارئ PDF المحسن غير مدعوم بعد على الويب'));
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleUI,
      child: Stack(children: [
        Positioned.fill(
          child: PDFView(
            filePath: widget.localFilePath,
            defaultPage: _page - 1,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageSnap: true,
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
              _restartHideTimer();
            },
            onError: (e) => debugPrint('PDF error: $e'),
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
          ValueListenableBuilder<double>(
            valueListenable: _fontScale,
            builder: (_, scale, __) => Row(children: [
              _iconBtn(Icons.remove, () => _fontScale.value = (scale - .1).clamp(.5, 2.0)),
              Text('${(scale * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 12)),
              _iconBtn(Icons.add, () => _fontScale.value = (scale + .1).clamp(.5, 2.0)),
            ]),
          ),
        ]),
      ),
    );
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
              style: const TextStyle(color: Colors.white70, fontFeatures: [FontFeature.tabularFigures()]),
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
                onChangeEnd: (v) {
                  // TODO: عند إضافة Controller: الانتقال إلى الصفحة مباشرة
                  _saveProgress();
                },
              ),
            ),
            const SizedBox(width: 12),
            Text('${(_progress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
