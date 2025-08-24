import 'package:flutter/material.dart';
import '../utils/enhanced_design_tokens.dart';

/// ويدجت لعرض مراجعة كتاب بشكل تفاعلي
class BookReviewCard extends StatefulWidget {
  final String reviewerName;
  final String reviewerAvatar;
  final double rating;
  final String reviewText;
  final DateTime reviewDate;
  final int likesCount;
  final bool isLiked;
  final bool isVerifiedReviewer;
  final String? bookTitle; // إضافة جديدة
  final VoidCallback? onLike;
  final VoidCallback? onReply;
  final VoidCallback? onShare;

  const BookReviewCard({
    super.key,
    required this.reviewerName,
    this.reviewerAvatar = '',
    required this.rating,
    required this.reviewText,
    required this.reviewDate,
    required this.likesCount,
    required this.isLiked,
    this.isVerifiedReviewer = false,
    this.bookTitle, // إضافة جديدة
    this.onLike,
    this.onReply,
    this.onShare,
  });

  @override
  State<BookReviewCard> createState() => _BookReviewCardState();
}

class _BookReviewCardState extends State<BookReviewCard> {
  late bool _isLiked;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _likesCount = widget.likesCount;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });
    widget.onLike?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: EnhancedSpacing.md),
      padding: const EdgeInsets.all(EnhancedSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EnhancedRadius.lg),
        boxShadow: EnhancedShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // معلومات المُراجع وعنوان الكتاب
          Row(
            children: [
              // صورة المُراجع
              CircleAvatar(
                radius: 20,
                backgroundColor: EnhancedAppColors.gray300,
                child: Text(
                  widget.reviewerName.isNotEmpty 
                      ? widget.reviewerName[0].toUpperCase() 
                      : '؟',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: EnhancedAppColors.gray700,
                  ),
                ),
              ),
              
              const SizedBox(width: EnhancedSpacing.sm),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.reviewerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: EnhancedAppColors.gray800,
                          ),
                        ),
                        
                        if (widget.isVerifiedReviewer) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 14,
                            color: EnhancedAppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    
                    // عنوان الكتاب (إذا توفر)
                    if (widget.bookTitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'مراجعة لكتاب "${widget.bookTitle}"',
                        style: const TextStyle(
                          fontSize: 12,
                          color: EnhancedAppColors.gray600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // تاريخ المراجعة
              Text(
                _getTimeAgo(widget.reviewDate),
                style: const TextStyle(
                  fontSize: 12,
                  color: EnhancedAppColors.gray500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: EnhancedSpacing.sm),
          
          // تقييم النجوم
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < widget.rating ? Icons.star : Icons.star_border,
                size: 16,
                color: Colors.amber,
              );
            }),
          ),
          
          const SizedBox(height: EnhancedSpacing.sm),
          
          // نص المراجعة
          Text(
            widget.reviewText,
            style: const TextStyle(
              color: EnhancedAppColors.gray700,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: EnhancedSpacing.md),
          
          // أزرار التفاعل
          Row(
            children: [
              // زر الإعجاب
              InkWell(
                onTap: _toggleLike,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: _isLiked ? EnhancedAppColors.error : EnhancedAppColors.gray500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_likesCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isLiked ? EnhancedAppColors.error : EnhancedAppColors.gray500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: EnhancedSpacing.md),
              
              // زر الرد
              InkWell(
                onTap: widget.onReply,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.reply,
                        size: 16,
                        color: EnhancedAppColors.gray500,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'رد',
                        style: TextStyle(
                          fontSize: 12,
                          color: EnhancedAppColors.gray500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // زر المشاركة
              InkWell(
                onTap: widget.onShare,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: const Icon(
                    Icons.share_outlined,
                    size: 16,
                    color: EnhancedAppColors.gray500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes <= 1 ? 'دقيقة' : 'دقائق'}';
    }
  }
}

/// ويدجت لعرض إحصائيات المجتمع
class CommunityStatsWidget extends StatelessWidget {
  final int totalBooks;
  final int totalReviews;
  final int activeReaders;
  final int discussions;

  const CommunityStatsWidget({
    super.key,
    required this.totalBooks,
    required this.totalReviews,
    required this.activeReaders,
    required this.discussions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(EnhancedSpacing.lg),
      padding: const EdgeInsets.all(EnhancedSpacing.xl),
      decoration: BoxDecoration(
        gradient: EnhancedGradients.communityGradient,
        borderRadius: BorderRadius.circular(EnhancedRadius.xl),
        boxShadow: EnhancedShadows.glow,
      ),
      child: Column(
        children: [
          Text(
            'إحصائيات المجتمع',
            style: const TextStyle(
              fontSize: EnhancedTypography.headlineSmall,
              fontWeight: EnhancedTypography.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: EnhancedSpacing.xl),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.library_books,
                  count: totalBooks,
                  label: 'كتاب',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.rate_review,
                  count: totalReviews,
                  label: 'مراجعة',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: EnhancedSpacing.lg),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.people,
                  count: activeReaders,
                  label: 'قارئ نشط',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.forum,
                  count: discussions,
                  label: 'نقاش',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required int count,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(EnhancedSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(EnhancedRadius.md),
          ),
          child: Icon(
            icon,
            size: 32,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: EnhancedSpacing.sm),
        
        Text(
          _formatNumber(count),
          style: const TextStyle(
            fontSize: EnhancedTypography.headlineMedium,
            fontWeight: EnhancedTypography.bold,
            color: Colors.white,
          ),
        ),
        
        Text(
          label,
          style: const TextStyle(
            fontSize: EnhancedTypography.bodyMedium,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}م';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}ك';
    }
    return number.toString();
  }
}

/// ويدجت لعرض توصيات شخصية للكتب
class PersonalizedRecommendations extends StatelessWidget {
  final List<RecommendationItem> recommendations;
  final VoidCallback? onSeeAll;

  const PersonalizedRecommendations({
    super.key,
    required this.recommendations,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(EnhancedSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🎯 مقترح خصيصاً لك',
                style: TextStyle(
                  fontSize: EnhancedTypography.headlineSmall,
                  fontWeight: EnhancedTypography.bold,
                  color: EnhancedAppColors.gray800,
                ),
              ),
              
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text(
                    'عرض الكل',
                    style: TextStyle(
                      fontSize: EnhancedTypography.bodyMedium,
                      color: EnhancedAppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: EnhancedSpacing.lg),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final rec = recommendations[index];
              return _buildRecommendationCard(rec);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(RecommendationItem recommendation) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(left: EnhancedSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EnhancedRadius.lg),
        boxShadow: EnhancedShadows.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // غلاف الكتاب
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(EnhancedRadius.lg),
                ),
                gradient: EnhancedGradients.getCategoryGradient(
                  recommendation.category,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 40,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  
                  // سبب التوصية
                  Positioned(
                    top: EnhancedSpacing.sm,
                    left: EnhancedSpacing.sm,
                    right: EnhancedSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: EnhancedSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(EnhancedRadius.xs),
                      ),
                      child: Text(
                        recommendation.reason,
                        style: const TextStyle(
                          fontSize: EnhancedTypography.labelSmall,
                          color: Colors.white,
                          fontWeight: EnhancedTypography.medium,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // معلومات الكتاب
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(EnhancedSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recommendation.title,
                    style: const TextStyle(
                      fontSize: EnhancedTypography.titleSmall,
                      fontWeight: EnhancedTypography.semiBold,
                      color: EnhancedAppColors.gray800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: EnhancedSpacing.xs),
                  
                  Text(
                    recommendation.author,
                    style: const TextStyle(
                      fontSize: EnhancedTypography.bodySmall,
                      color: EnhancedAppColors.gray600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const Spacer(),
                  
                  // معدل التطابق
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EnhancedSpacing.sm,
                      vertical: EnhancedSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: EnhancedAppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(EnhancedRadius.sm),
                    ),
                    child: Text(
                      '${recommendation.matchPercentage}% تطابق',
                      style: const TextStyle(
                        fontSize: EnhancedTypography.labelSmall,
                        color: EnhancedAppColors.success,
                        fontWeight: EnhancedTypography.medium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// نموذج بيانات للتوصيات
class RecommendationItem {
  final String title;
  final String author;
  final String category;
  final String reason;
  final int matchPercentage;
  final String? coverUrl;

  const RecommendationItem({
    required this.title,
    required this.author,
    required this.category,
    required this.reason,
    required this.matchPercentage,
    this.coverUrl,
  });
}
