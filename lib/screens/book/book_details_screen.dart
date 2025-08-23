import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../../services/auth_firebase_service.dart';
import '../../services/review_service.dart';
import '../../models/review_model.dart';
// استبدلنا القارئ المبسّط بالقارئ الكامل
import 'book_reader_screen.dart';
import '../auth/simple_login_screen.dart';
import '../../widgets/safe_image.dart';
import '../../utils/design_tokens.dart';
import '../../firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// شاشة تفاصيل الكتاب (نسخة نظيفة بعد التنظيف)
class BookDetailsScreen extends StatefulWidget {
  final BookModel book;
  const BookDetailsScreen({super.key, required this.book});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  Future<List<ReviewModel>>? _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() {
    _reviewsFuture = Provider.of<ReviewService>(context, listen: false).getBookReviews(widget.book.id);
    // trigger rebuild
    if (mounted) setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        bottomNavigationBar: _buildBottomBar(),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),
                  _buildPrimaryInfoCard(),
                  const SizedBox(height: 24),
                  _buildMetaSection(),
                  const SizedBox(height: 24),
                  _buildProgressSection(),
                  const SizedBox(height: 24),
                  _buildDescriptionSection(),
                  if (widget.book.bookSummary.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSummarySection(),
                  ],
                  if (widget.book.authorBio.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildAuthorBioSection(),
                  ],
                  if (widget.book.tags.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildTagsSection(),
                  ],
                  const SizedBox(height: 24),
                  _buildInfoChips(),
                  const SizedBox(height: 24),
                  _buildReviewsSection(),
                  const SizedBox(height: 32),
                  _buildRelatedSection(),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          widget.book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        actions: [
          Consumer<AuthFirebaseService>(
            builder: (context, auth, _) {
              final isOwner = auth.currentUser?.uid == widget.book.uploadedBy;
              if (!isOwner) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'تعديل/حذف',
                icon: const Icon(Icons.edit_note, color: Colors.white),
                onPressed: _showEditMenu,
              );
            },
          ),
          Consumer<BookService>(
            builder: (context, service, _) {
              final saved = service.isBookSaved(widget.book.id);
              return IconButton(
                tooltip: saved ? 'إزالة من المحفوظات' : 'حفظ',
                icon: Icon(saved ? Icons.bookmark : Icons.bookmark_outline, color: saved ? Colors.amber : Colors.white),
                onPressed: () {
                  if (saved) {
                    service.unsaveBook(widget.book.id);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إزالة الكتاب من المحفوظات')));
                  } else {
                    service.saveBook(widget.book.id);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الكتاب')));
                  }
                },
              );
            },
          ),
          // Diagnostic button: open a small Firestore read/test to show full exception
          IconButton(
            tooltip: 'تشخيص Firestore',
            icon: const Icon(Icons.bug_report, color: Colors.white),
            onPressed: () async {
              await _runFirestoreDiagnostic();
            },
          ),
          // المكتبة والمراجعات
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              final auth = Provider.of<AuthFirebaseService>(context, listen: false);
              final uid = auth.currentUser?.uid;
              if (uid == null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SimpleLoginScreen()));
                return;
              }
              if (value == 'edit') {
                final isOwner = uid == widget.book.uploadedBy;
                if (isOwner) _showEditMenu();
                return;
              }
              if (value == 'review') {
                _showReviewDialog();
                return;
              }
              final statusMap = {
                'reading': 'reading',
                'completed': 'completed',
                'want': 'want_to_read',
              };
              final status = statusMap[value] ?? 'reading';
              try {
                await Provider.of<BookService>(context, listen: false).addToLibrary(uid, widget.book.id, status);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإضافة إلى المكتبة')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل في إضافة الكتاب')));
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'reading', child: Text('أضف إلى: أقرأ الآن')),
              const PopupMenuItem(value: 'completed', child: Text('أضف إلى: مُكتمل')),
              const PopupMenuItem(value: 'want', child: Text('أضف إلى: أريد قراءته')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'edit', child: Text('تعديل الكتاب')),
              const PopupMenuItem(value: 'review', child: Text('أضف مراجعة')),
            ],
          ),
        ],
      );

  // ===== أقسام الواجهة =====
  Widget _buildHeader() {
    final color = _categoryColor(widget.book.category);
    return Hero(
      tag: 'book_cover_${widget.book.id}',
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(.85), color.withOpacity(.55)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: Stack(children: [
          // صورة الغلاف (إن وجدت) - أعلى خلفية الأيقونة
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: SafeImage(
                assetPath: widget.book.coverImageUrl.isNotEmpty ? widget.book.coverImageUrl : null,
                fit: BoxFit.cover,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(bottom: 20, right: 20),
              child: Opacity(
                opacity: .16,
                child: Icon(Icons.menu_book_rounded, size: 140, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15)),
                const SizedBox(height: 6),
                Text(widget.book.author,
                    style: TextStyle(color: Colors.white.withOpacity(.92), fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // تشغيل تشخيص بسيط على Firestore (قراءة مستند اختبار) وعرض النتيجة/الاستثناء في مودال
  Future<void> _runFirestoreDiagnostic() async {
    // نافذة تقدم بسيطة
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
      ),
    );

  // 1) فحص الاتصال بشكل محايد للمنصة: على الموبايل قد لا يتوفر navigator.onLine
  // سنعتمد مباشرة على محاولة الوصول إلى Firestore مع مهلة زمنية بدل الاعتماد على dart:html

    // 2) اختبار قراءة عبر الـ SDK فقط (بدون googlePing / firestorePing) لتجنب الضجيج في الـ Console
    try {
      final fs = FirebaseFirestore.instance;
      final sw = Stopwatch()..start();
      final doc = await fs.collection('diagnostics').doc('ping').get().timeout(const Duration(seconds: 8));
      sw.stop();
      Navigator.of(context).pop();

      final content = doc.exists ? doc.data().toString() : 'المستند غير موجود (diagnostics/ping)';
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('تشخيص Firestore (قراءة)'),
          content: SingleChildScrollView(
            child: Text('نجاح القراءة خلال ${sw.elapsedMilliseconds}ms\n\n$content'),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق'))],
        ),
      );
    } on TimeoutException {
      // 3) محاولة كتابة (قد تعطينا رسالة خطأ أسرع)
      try {
        final fs = FirebaseFirestore.instance;
        final sw = Stopwatch()..start();
        await fs.collection('diagnostics').doc('ping').set({'ts': FieldValue.serverTimestamp()}).timeout(const Duration(seconds: 10));
        sw.stop();
        Navigator.of(context).pop();
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('تشخيص Firestore (كتابة)'),
            content: Text('تمت الكتابة بنجاح خلال ${sw.elapsedMilliseconds}ms'),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق'))],
          ),
        );
      } on TimeoutException {
        Navigator.of(context).pop();
        await showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text('تشخيص Firestore'),
            content: Text('انتهت المهلة أثناء الوصول إلى Firestore (قراءة وكتابة). تحقق من الشبكة أو الإعدادات.'),
          ),
        );
      } catch (e, st) {
        Navigator.of(context).pop();
        final msg = (e is FirebaseException)
            ? 'FirebaseException code=${e.code}\n${e.message ?? ''}'
            : e.toString();
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('تشخيص Firestore (خطأ كتابة)'),
            content: SingleChildScrollView(child: Text('$msg\n\n$st')),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق'))],
          ),
        );
      }
    } catch (e, st) {
      Navigator.of(context).pop();
      final msg = (e is FirebaseException)
          ? 'FirebaseException code=${e.code}\n${e.message ?? ''}'
          : e.toString();
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('تشخيص Firestore (خطأ قراءة)'),
          content: SingleChildScrollView(child: Text('$msg\n\n$st')),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('إغلاق'))],
        ),
      );
    }
  }

  Widget _metaItem(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(.12)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );

    Widget _buildMetaSection() => Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _metaItem(Icons.category_outlined, widget.book.category),
            _metaItem(Icons.language, widget.book.language.toUpperCase()),
            _metaItem(Icons.insert_drive_file_outlined, widget.book.fileType.toUpperCase()),
            _metaItem(Icons.pages_outlined, '${widget.book.pageCount} صفحة'),
          ],
        );

  Widget _buildProgressSection() => Consumer2<BookService, AuthFirebaseService>(
        builder: (context, service, auth, _) {
          final progress = service.getReadingProgress(widget.book.id, auth.currentUser?.uid ?? '');
          if (progress == null) return const SizedBox.shrink();
          final pct = (progress.progressPercentage * 100).toInt();
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).primaryColor.withOpacity(.18)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('تقدم القراءة', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).primaryColor)),
                Text('$pct%', style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).primaryColor)),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: progress.progressPercentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
                ),
              ),
              const SizedBox(height: 8),
              Text('الصفحة ${progress.currentPage} من ${progress.totalPages}', style: TextStyle(fontSize: 12, color: Colors.grey[700]))
            ]),
          );
        },
      );

  Widget _buildDescriptionSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الوصف', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(widget.book.description, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6)),
        ],
      );

  Widget _buildPrimaryInfoCard() {
    final theme = Theme.of(context);
    final release = widget.book.releaseDate != null ? 'تاريخ الإصدار: ${_formatDate(widget.book.releaseDate!)}' : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 170,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: widget.book.coverImageUrl.isNotEmpty
                ? SafeImage(assetPath: widget.book.coverImageUrl, fit: BoxFit.cover)
                : Container(color: Colors.grey.shade200, child: const Icon(Icons.menu_book_rounded, size: 48, color: Colors.grey)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.book.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.15)),
            const SizedBox(height: 6),
            Text('بقلم: ${widget.book.author}', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.w600)),
            if (release != null) ...[
              const SizedBox(height: 8),
              Row(children: [const Icon(Icons.event, size: 16, color: Colors.grey), const SizedBox(width: 4), Text(release, style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey[700]))]),
            ],
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 6, children: [
              _infoPill(Icons.star, '${widget.book.averageRating.toStringAsFixed(1)} / 5'),
              _infoPill(Icons.reviews, '${widget.book.totalReviews} مراجعة'),
              _infoPill(Icons.download, '${widget.book.downloadCount} تنزيل'),
              _infoPill(Icons.language, widget.book.language.toUpperCase()),
            ]),
          ]),
        ),
      ],
    );
  }

  Widget _infoPill(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(.08), borderRadius: BorderRadius.circular(30)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: Theme.of(context).primaryColor),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );

  String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _buildSummarySection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('نبذة عن الكتاب', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(widget.book.bookSummary, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55)),
        ],
      );

  Widget _buildAuthorBioSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('نبذة عن المؤلف', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Text(widget.book.authorBio, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55)),
        ],
      );

  void _showEditMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final titleController = TextEditingController(text: widget.book.title);
        final descController = TextEditingController(text: widget.book.description);
        final summaryController = TextEditingController(text: widget.book.bookSummary);
        final authorBioController = TextEditingController(text: widget.book.authorBio);
        DateTime? releaseDate = widget.book.releaseDate;
        bool saving = false;
        Uint8List? newCoverBytes;
        String? newCoverName;
        return StatefulBuilder(builder: (c, setModal) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(child: Container(width: 50, height: 5, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(4)))),
                  Text('تعديل الكتاب', style: Theme.of(c).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 80,
                        height: 110,
                        child: newCoverBytes != null
                            ? Image.memory(newCoverBytes!, fit: BoxFit.cover)
                            : (widget.book.coverImageUrl.isNotEmpty
                                ? SafeImage(assetPath: widget.book.coverImageUrl, fit: BoxFit.cover)
                                : Container(color: Colors.grey.shade200, child: const Icon(Icons.image, size: 32, color: Colors.grey))),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('الغلاف', style: Theme.of(c).textTheme.labelLarge),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: saving
                              ? null
                              : () async {
                                  try {
                                    final res = await FilePicker.platform.pickFiles(
                                      withData: true,
                                      type: FileType.custom,
                                      allowedExtensions: ['jpg', 'jpeg', 'png']
                                    );
                                    if (res != null && res.files.isNotEmpty) {
                                      final f = res.files.first;
                                      setModal(() {
                                        newCoverBytes = f.bytes;
                                        newCoverName = f.name;
                                      });
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل اختيار الصورة: $e')));
                                    }
                                  }
                                },
                          icon: const Icon(Icons.image_outlined),
                          label: Text(newCoverName ?? 'تغيير الغلاف'),
                        ),
                        if (newCoverBytes != null)
                          TextButton.icon(
                            onPressed: saving
                                ? null
                                : () => setModal(() {
                                      newCoverBytes = null;
                                      newCoverName = null;
                                    }),
                            icon: const Icon(Icons.close),
                            label: const Text('إزالة الجديد'),
                          ),
                      ]),
                    )
                  ]),
                  const SizedBox(height: 16),
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'العنوان')), const SizedBox(height: 12),
                  TextField(controller: descController, maxLines: 3, decoration: const InputDecoration(labelText: 'الوصف')), const SizedBox(height: 12),
                  TextField(controller: summaryController, maxLines: 3, decoration: const InputDecoration(labelText: 'نبذة الكتاب')), const SizedBox(height: 12),
                  TextField(controller: authorBioController, maxLines: 3, decoration: const InputDecoration(labelText: 'نبذة المؤلف')), const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: Text(releaseDate != null ? 'الإصدار: ${_formatDate(releaseDate!)}' : 'لا يوجد تاريخ إصدار')),
                    TextButton.icon(onPressed: () async { final picked = await showDatePicker(context: c, initialDate: releaseDate ?? DateTime.now(), firstDate: DateTime(1800), lastDate: DateTime(2100)); if (picked != null) setModal(() => releaseDate = picked); }, icon: const Icon(Icons.event), label: const Text('اختيار')),
                  ]),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                        label: const Text('حفظ التعديلات'),
                        onPressed: saving ? null : () async {
                          setModal(() => saving = true);
                          try {
                            final svc = Provider.of<BookService>(context, listen: false);
                            final updated = widget.book.copyWith(
                              title: titleController.text.trim(),
                              description: descController.text.trim(),
                              bookSummary: summaryController.text.trim(),
                              authorBio: authorBioController.text.trim(),
                              releaseDate: releaseDate,
                              updatedAt: DateTime.now(),
                            );
                            List<int>? coverBytes;
                            String? coverType;
                            if (newCoverBytes != null && newCoverBytes!.isNotEmpty) {
                              coverBytes = newCoverBytes!.toList();
                              final lower = (newCoverName ?? '').toLowerCase();
                              coverType = lower.endsWith('.png') ? 'image/png' : 'image/jpeg';
                            }
                            await svc.updateBook(
                              updated,
                              coverImageBytes: coverBytes,
                              coverImageContentType: coverType,
                            );
                            if (mounted) {
                              Navigator.pop(c);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الكتاب')));
                            }
                          } catch (_) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل في التحديث')));
                          } finally {
                            if (mounted) setModal(() => saving = false);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                      tooltip: 'حذف الكتاب',
                      onPressed: saving ? null : () async {
                        final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('تأكيد الحذف'), content: const Text('هل تريد حذف الكتاب؟ لا يمكن التراجع.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('حذف'))]));
                        if (confirm == true) {
                          try {
                            final svc = Provider.of<BookService>(context, listen: false);
                            await svc.deleteBook(widget.book.id);
                            if (mounted) {
                              Navigator.pop(c);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الكتاب')));
                            }
                          } catch (_) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل في حذف الكتاب')));
                          }
                        }
                      },
                    ),
                  ]),
                ]),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildTagsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الكلمات المفتاحية', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.book.tags
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(.25)),
                      ),
                      child: Text(t, style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          )
        ],
      );

  Widget _buildInfoChips() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _chip(Icons.star, '${widget.book.averageRating.toStringAsFixed(1)} / 5'),
          _chip(Icons.reviews_outlined, '${widget.book.totalReviews} مراجعة'),
          _chip(Icons.download_done_outlined, '${widget.book.downloadCount} تنزيل'),
          _chip(Icons.person_outline, widget.book.uploadedBy),
        ],
      );

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.withOpacity(.12)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _buildRelatedSection() => Consumer<BookService>(
        builder: (context, service, _) {
          final related = service
              .getBooksByCategory(widget.book.category)
              .where((b) => b.id != widget.book.id)
              .take(6)
              .toList();
          if (related.isEmpty) return const SizedBox.shrink();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('كتب مشابهة', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: related.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final b = related[i];
                  final c = _categoryColor(b.category);
                  return GestureDetector(
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BookDetailsScreen(book: b))),
                    child: Container(
                      width: 120,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [c.withOpacity(.15), c.withOpacity(.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: c.withOpacity(.25)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.menu_book, color: c, size: 32),
                        const SizedBox(height: 8),
                        Text(b.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, height: 1.2)),
                        const Spacer(),
                        Row(children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(b.averageRating.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        ])
                      ]),
                    ),
                  );
                },
              ),
            )
          ]);
        },
      );

  Widget _buildBottomBar() => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Colors.grey.withOpacity(.14))),
        ),
        child: Consumer2<BookService, AuthFirebaseService>(
          builder: (context, service, auth, _) {
            final progress = service.getReadingProgress(widget.book.id, auth.currentUser?.uid ?? '');
            final saved = service.isBookSaved(widget.book.id);
            return Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookReaderScreen(book: widget.book))),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(progress == null ? 'بدء القراءة' : 'متابعة القراءة'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (saved) {
                      service.unsaveBook(widget.book.id);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الإزالة من المحفوظات')));
                    } else {
                      service.saveBook(widget.book.id);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الكتاب')));
                    }
                  },
                  icon: Icon(saved ? Icons.bookmark : Icons.bookmark_outline),
                  label: Text(saved ? 'محفوظ' : 'حفظ'),
                ),
              ),
            ]);
          },
        ),
      );

  // ===== أدوات مساعدة =====
  Color _categoryColor(String c) {
  return AppColors.categoryColors[c] ?? Colors.grey;
  }

  // الدوال القديمة التالية لم تعد مستخدمة بعد إعادة البناء؛ يمكن حذفها مستقبلاً إذا لم نعد إليها:
  // (أزلنا دوال معلومات/إحصائيات/تحميل قديمة غير مستخدمة الآن)

  // عرض حوار إضافة مراجعة
  Future<void> _showReviewDialog() async {
    double rating = 5.0;
    final TextEditingController commentController = TextEditingController();
    bool isSending = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (dialogCtx, dialogSetState) {
          return AlertDialog(
            title: const Text('أضف مراجعة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final idx = i + 1;
                    return IconButton(
                      icon: Icon(idx <= rating ? Icons.star : Icons.star_border, color: Colors.amber),
                      onPressed: isSending ? null : () => dialogSetState(() => rating = idx.toDouble()),
                    );
                  }),
                ),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'اكتب تعليقك...'),
                  enabled: !isSending,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSending ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: isSending
                    ? null
                    : () async {
                        final comment = commentController.text.trim();
                        dialogSetState(() => isSending = true);
                        bool success = false;
                        try {
                          success = await _submitReview(rating, comment);
                        } finally {
                          dialogSetState(() => isSending = false);
                        }

                        if (success) {
                          _loadReviews();
                          if (mounted) {
                            Navigator.of(dialogCtx).pop();
                            // خيار: الرجوع للشاشة السابقة بعد الإضافة
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          }
                        }
                      },
                child: isSending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('إرسال'),
              ),
            ],
          );
        });
      },
    );

    // dispose controller after dialog is closed
    commentController.dispose();
  }

  // إرسال المراجعة إلى الخدمة (upsert)
  Future<bool> _submitReview(double rating, String comment) async {
    // Quick sanity check: if firebase_options.dart contains placeholders, skip network call
    try {
      final opts = DefaultFirebaseOptions.currentPlatform;
  final key = opts.apiKey;
  final project = opts.projectId;
  // common placeholder patterns
  final isPlaceholder = key.isEmpty || project.isEmpty || key.contains('YOUR_') || key.contains('API_KEY') || project.contains('YOUR_PROJECT');
  if (isPlaceholder) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Firebase غير مكوّن محلياً — شغّل flutterfire configure')));
        return false;
      }
    } catch (_) {
      // If firebase_options isn't present or malformed, avoid calling network
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Firebase غير مكوّن — تحقق من ملف firebase_options.dart')));
      return false;
    }
    final auth = Provider.of<AuthFirebaseService>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SimpleLoginScreen()));
      return false;
    }

    final review = ReviewModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: widget.book.id,
      userId: user.uid,
      userName: user.displayName ?? 'مستخدم',
      userPhotoUrl: user.photoURL ?? '',
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    try {
      // Protect the network call with a timeout to avoid indefinite hanging on web when config is wrong
      await Provider.of<ReviewService>(context, listen: false)
          .addReview(review)
          .timeout(const Duration(seconds: 12));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة المراجعة')));
      return true;
    } on TimeoutException catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('انتهت مهلة الشبكة. تحقق من إعدادات Firebase أو اتصال الإنترنت')));
      return false;
    } catch (e) {
      // Prefer concise, actionable messages
      final msg = (e is FirebaseException && e.message != null) ? e.message! : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل في إضافة المراجعة: ${msg.length > 200 ? '${msg.substring(0, 200)}...' : msg}')));
      return false;
    }
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('المراجعات', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        FutureBuilder<List<ReviewModel>>(
          future: _reviewsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final reviews = snapshot.data ?? [];
            if (reviews.isEmpty) return const Text('لا توجد مراجعات بعد');
            return Column(
              children: reviews.map((rev) {
                return ListTile(
                  leading: CircleAvatar(child: Text(rev.userName.isNotEmpty ? rev.userName[0] : '?')),
                  title: Text(rev.userName),
                  subtitle: Text(rev.comment),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(rev.rating.toStringAsFixed(1)),
                  ]),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
