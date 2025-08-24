import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../../utils/enhanced_design_tokens.dart';
import '../../widgets/social_community_widgets.dart';
import 'book_reader_screen.dart';

class EnhancedBookDetailsScreen extends StatefulWidget {
  final BookModel book;

  const EnhancedBookDetailsScreen({super.key, required this.book});

  @override
  State<EnhancedBookDetailsScreen> createState() => _EnhancedBookDetailsScreenState();
}

class _EnhancedBookDetailsScreenState extends State<EnhancedBookDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        backgroundColor: EnhancedAppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // غلاف الكتاب ومعلومات أساسية
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // غلاف الكتاب
                Container(
                  width: 120,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: EnhancedGradients.getCategoryGradient(widget.book.category),
                    boxShadow: EnhancedShadows.medium,
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    size: 48,
                    color: Colors.white,
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'بقلم: ${widget.book.author}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: EnhancedAppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.book.category,
                          style: const TextStyle(
                            color: EnhancedAppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // التقييم
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < widget.book.averageRating 
                                  ? Icons.star 
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.book.averageRating} (${widget.book.totalReviews} مراجعة)',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // وصف الكتاب
            const Text(
              'وصف الكتاب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              widget.book.description.isNotEmpty 
                  ? widget.book.description 
                  : 'لا يتوفر وصف لهذا الكتاب حالياً.',
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // أزرار العمل
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _startReading(context),
                    icon: const Icon(Icons.play_circle_filled),
                    label: const Text('ابدأ القراءة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EnhancedAppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                OutlinedButton.icon(
                  onPressed: () => _addToLibrary(context),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة للمكتبة'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EnhancedAppColors.primary,
                    side: const BorderSide(color: EnhancedAppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // قسم المراجعات
            const Text(
              'المراجعات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // مراجعات وهمية للعرض
            ..._buildSampleReviews(),
          ],
        ),
      ),
    );
  }

  void _startReading(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookReaderScreen(book: widget.book),
      ),
    );
  }

  void _addToLibrary(BuildContext context) {
    final bookService = Provider.of<BookService>(context, listen: false);
    // TODO: إضافة الكتاب للمكتبة
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم إضافة الكتاب إلى المكتبة'),
        backgroundColor: EnhancedAppColors.success,
      ),
    );
  }

  List<Widget> _buildSampleReviews() {
    // مراجعات وهمية للعرض
    final sampleReviews = [
      {
        'reviewerName': 'أحمد محمد',
        'rating': 4.5,
        'reviewText': 'كتاب رائع يستحق القراءة، أسلوب الكاتب شيق ومميز.',
        'reviewDate': DateTime.now().subtract(const Duration(days: 2)),
        'likesCount': 12,
        'isLiked': false,
        'isVerifiedReviewer': true,
      },
      {
        'reviewerName': 'فاطمة الزهراء',
        'rating': 5.0,
        'reviewText': 'من أفضل الكتب التي قرأتها، يغير منظورك للحياة.',
        'reviewDate': DateTime.now().subtract(const Duration(days: 5)),
        'likesCount': 8,
        'isLiked': true,
        'isVerifiedReviewer': false,
      },
    ];

    return sampleReviews.map((review) => BookReviewCard(
      reviewerName: review['reviewerName'] as String,
      rating: review['rating'] as double,
      reviewText: review['reviewText'] as String,
      reviewDate: review['reviewDate'] as DateTime,
      likesCount: review['likesCount'] as int,
      isLiked: review['isLiked'] as bool,
      isVerifiedReviewer: review['isVerifiedReviewer'] as bool,
      onLike: () {
        // TODO: تطبيق الإعجاب
      },
      onReply: () {
        // TODO: تطبيق الرد
      },
      onShare: () {
        // TODO: تطبيق المشاركة
      },
    )).toList();
  }
}
