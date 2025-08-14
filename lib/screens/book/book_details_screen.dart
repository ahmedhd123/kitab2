import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../../services/simple_auth_service.dart';
import 'simple_book_reader_screen.dart';

class BookDetailsScreen extends StatefulWidget {
  final BookModel book;

  const BookDetailsScreen({
    super.key,
    required this.book,
  });

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Consumer<BookService>(
            builder: (context, bookService, child) {
              final isSaved = bookService.isBookSaved(widget.book.id);
              return IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? Colors.amber : Colors.white,
                ),
                onPressed: () {
                  if (isSaved) {
                    bookService.unsaveBook(widget.book.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إزالة الكتاب من المحفوظات')),
                    );
                  } else {
                    bookService.saveBook(widget.book.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حفظ الكتاب')),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات الكتاب الأساسية
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // غلاف الكتاب
                Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _getBookColor(widget.book.category).withOpacity(0.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.book.coverImageUrl.isNotEmpty
                        ? Image.network(
                            widget.book.coverImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.menu_book,
                                  size: 40,
                                  color: _getBookColor(widget.book.category),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(
                              Icons.menu_book,
                              size: 40,
                              color: _getBookColor(widget.book.category),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // معلومات الكتاب
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.book.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'بقلم: ${widget.book.author}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getBookColor(widget.book.category).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.book.category,
                          style: TextStyle(
                            color: _getBookColor(widget.book.category),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.book.averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${widget.book.totalReviews})',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.download,
                                color: Colors.grey[600],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.book.downloadCount}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // تقدم القراءة (إذا كان المستخدم قد بدأ القراءة)
            Consumer2<BookService, SimpleAuthService>(
              builder: (context, bookService, authService, child) {
                final progress = bookService.getReadingProgress(
                  widget.book.id,
                  authService.currentUser ?? '',
                );
                
                if (progress != null) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'تقدم القراءة',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            Text(
                              '${(progress.progressPercentage * 100).toInt()}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress.progressPercentage,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'الصفحة ${progress.currentPage} من ${progress.totalPages}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Container();
              },
            ),

            // أزرار الإجراءات
            Consumer2<BookService, SimpleAuthService>(
              builder: (context, bookService, authService, child) {
                final progress = bookService.getReadingProgress(
                  widget.book.id,
                  authService.currentUser ?? '',
                );
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SimpleBookReaderScreen(book: widget.book),
                              ),
                            );
                          },
                          icon: Icon(
                            progress != null ? Icons.play_arrow : Icons.play_arrow,
                          ),
                          label: Text(
                            progress != null ? 'متابعة القراءة' : 'بدء القراءة',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final isSaved = bookService.isBookSaved(widget.book.id);
                            if (isSaved) {
                              bookService.unsaveBook(widget.book.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم إزالة الكتاب من المحفوظات')),
                              );
                            } else {
                              bookService.saveBook(widget.book.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم حفظ الكتاب')),
                              );
                            }
                          },
                          icon: Icon(
                            bookService.isBookSaved(widget.book.id)
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                          ),
                          label: Text(
                            bookService.isBookSaved(widget.book.id) ? 'محفوظ' : 'حفظ',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // وصف الكتاب
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'وصف الكتاب',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.book.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // معلومات تفصيلية
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معلومات الكتاب',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('المؤلف', widget.book.author),
                    _buildInfoRow('الفئة', widget.book.category),
                    _buildInfoRow('اللغة', widget.book.language == 'ar' ? 'العربية' : 'الإنجليزية'),
                    _buildInfoRow('عدد الصفحات', '${widget.book.pageCount} صفحة'),
                    _buildInfoRow('نوع الملف', widget.book.fileType.toUpperCase()),
                    _buildInfoRow('عدد التحميلات', '${widget.book.downloadCount}'),
                    _buildInfoRow('التقييم', '${widget.book.averageRating.toStringAsFixed(1)} من 5'),
                    _buildInfoRow('تاريخ الإضافة', _formatDate(widget.book.createdAt)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // الكلمات المفتاحية
            if (widget.book.tags.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الكلمات المفتاحية',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.book.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // إحصائيات سريعة
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'التقييم',
                    widget.book.averageRating.toStringAsFixed(1),
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'المراجعات',
                    '${widget.book.totalReviews}',
                    Icons.rate_review,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'التحميلات',
                    '${widget.book.downloadCount}',
                    Icons.download,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // كتب أخرى من نفس الفئة
            Consumer<BookService>(
              builder: (context, bookService, child) {
                final relatedBooks = bookService
                    .getBooksByCategory(widget.book.category)
                    .where((book) => book.id != widget.book.id)
                    .take(3)
                    .toList();

                if (relatedBooks.isEmpty) return Container();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'كتب أخرى في ${widget.book.category}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...relatedBooks.map((book) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 70,
                            decoration: BoxDecoration(
                              color: _getBookColor(book.category).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.menu_book,
                              color: _getBookColor(book.category),
                            ),
                          ),
                          title: Text(
                            book.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(book.author),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(book.averageRating.toStringAsFixed(1)),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookDetailsScreen(book: book),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ],
        ),
      ),

      // زر التحميل العائم
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _downloadBook();
        },
        icon: const Icon(Icons.download),
        label: const Text('تحميل'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getBookColor(String category) {
    const colors = {
      'الأدب': Colors.orange,
      'العلوم': Colors.blue,
      'التاريخ': Colors.purple,
      'الفلسفة': Colors.red,
      'التكنولوجيا': Colors.teal,
      'الدين': Colors.green,
      'الطبخ': Colors.brown,
      'الرياضة': Colors.indigo,
    };
    return colors[category] ?? Colors.grey;
  }

  String _formatDate(DateTime date) {
    const monthNames = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  void _downloadBook() {
    // إضافة إلى عداد التحميلات
    Provider.of<BookService>(context, listen: false).incrementDownloadCount(widget.book.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download, color: Colors.white),
            const SizedBox(width: 8),
            Text('تم بدء تحميل ${widget.book.title}'),
          ],
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'إلغاء',
          onPressed: () {
            // TODO: إلغاء التحميل
          },
        ),
      ),
    );

    // TODO: تطبيق تحميل الكتاب فعلياً
  }
}
