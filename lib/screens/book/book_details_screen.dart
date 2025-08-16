import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../../services/auth_firebase_service.dart';
import '../../services/review_service.dart';
import '../../models/review_model.dart';
import 'simple_book_reader_screen.dart';
import '../auth/simple_login_screen.dart';
import '../../widgets/safe_image.dart';
import '../../utils/design_tokens.dart';

// شاشة تفاصيل الكتاب (نسخة نظيفة بعد التنظيف)
class BookDetailsScreen extends StatefulWidget {
  final BookModel book;
  const BookDetailsScreen({super.key, required this.book});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
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
                  _buildMetaSection(),
                  const SizedBox(height: 24),
                  _buildProgressSection(),
                  const SizedBox(height: 24),
                  _buildDescriptionSection(),
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
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20, right: 20),
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
          )
        ]),
      ),
    );
  }

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
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SimpleBookReaderScreen(book: widget.book))),
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
  void _showReviewDialog() {
    double rating = 5.0;
    final TextEditingController _commentController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('أضف مراجعة'),
        content: StatefulBuilder(builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final idx = i + 1;
                  return IconButton(
                    icon: Icon(idx <= rating ? Icons.star : Icons.star_border, color: Colors.amber),
                    onPressed: () => setState(() => rating = idx.toDouble()),
                  );
                }),
              ),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'اكتب تعليقك...'),
              ),
            ],
          );
        }),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final comment = _commentController.text.trim();
              await _submitReview(rating, comment);
              Navigator.pop(context);
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  // إرسال المراجعة إلى الخدمة (upsert)
  Future<void> _submitReview(double rating, String comment) async {
    final auth = Provider.of<AuthFirebaseService>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SimpleLoginScreen()));
      return;
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
      await Provider.of<ReviewService>(context, listen: false).addReview(review);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة المراجعة')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل في إضافة المراجعة')));
    }
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('المراجعات', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        FutureBuilder(
          future: Provider.of<ReviewService>(context, listen: false).getBookReviews(widget.book.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            final reviews = snapshot.data as List<dynamic>? ?? [];
            if (reviews.isEmpty) return const Text('لا توجد مراجعات بعد');
            return Column(
              children: reviews.map((r) {
                final rev = r as ReviewModel;
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
