import 'package:flutter/material.dart';
import '../utils/enhanced_design_tokens.dart';

/// كارت كتاب محسّن بتصميم حديث وتفاعلي
class EnhancedBookCard extends StatefulWidget {
  final String title;
  final String author;
  final String category;
  final String? coverUrl;
  final double rating;
  final int reviewCount;
  final bool isLiked;
  final bool isBookmarked;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;
  final bool showTrendingBadge; // إضافة جديدة
  
  const EnhancedBookCard({
    super.key,
    required this.title,
    required this.author,
    required this.category,
    this.coverUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.onTap,
    this.onLike,
    this.onBookmark,
    this.onShare,
    this.showTrendingBadge = false, // القيمة الافتراضية
  });

  @override
  State<EnhancedBookCard> createState() => _EnhancedBookCardState();
}

class _EnhancedBookCardState extends State<EnhancedBookCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: EnhancedAnimations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Container(
              margin: const EdgeInsets.all(EnhancedSpacing.sm),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(EnhancedRadius.lg),
                gradient: EnhancedGradients.glassmorphism,
                boxShadow: _isPressed 
                    ? EnhancedShadows.soft 
                    : EnhancedShadows.categoryGlow(widget.category),
              ),
              child: Card(
                elevation: 0,
                color: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(EnhancedRadius.lg),
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
                          gradient: EnhancedGradients.getCategoryGradient(widget.category),
                        ),
                        child: Stack(
                          children: [
                            // صورة الغلاف أو أيقونة
                            Center(
                              child: widget.coverUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(EnhancedRadius.sm),
                                      child: Image.network(
                                        widget.coverUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            _buildBookIcon(),
                                      ),
                                    )
                                  : _buildBookIcon(),
                            ),
                            
                            // شارة الفئة
                            Positioned(
                              top: EnhancedSpacing.sm,
                              right: EnhancedSpacing.sm,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: EnhancedSpacing.sm,
                                  vertical: EnhancedSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(EnhancedRadius.sm),
                                ),
                                child: Text(
                                  widget.category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: EnhancedTypography.labelSmall,
                                    fontWeight: EnhancedTypography.medium,
                                  ),
                                ),
                              ),
                            ),
                            
                            // أزرار التفاعل
                            Positioned(
                              top: EnhancedSpacing.sm,
                              left: EnhancedSpacing.sm,
                              child: Column(
                                children: [
                                  _buildActionButton(
                                    icon: widget.isBookmarked 
                                        ? Icons.bookmark 
                                        : Icons.bookmark_outline,
                                    color: widget.isBookmarked 
                                        ? EnhancedAppColors.warning 
                                        : Colors.white,
                                    onTap: widget.onBookmark,
                                  ),
                                  const SizedBox(height: EnhancedSpacing.xs),
                                  _buildActionButton(
                                    icon: Icons.share,
                                    color: Colors.white,
                                    onTap: widget.onShare,
                                  ),
                                ],
                              ),
                            ),
                            
                            // شارة الشائع
                            if (widget.showTrendingBadge)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.local_fire_department,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        'شائع',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
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
                        padding: const EdgeInsets.all(EnhancedSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // عنوان الكتاب
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: EnhancedTypography.titleMedium,
                                fontWeight: EnhancedTypography.semiBold,
                                color: EnhancedAppColors.gray800,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const SizedBox(height: EnhancedSpacing.xs),
                            
                            // اسم المؤلف
                            Text(
                              widget.author,
                              style: const TextStyle(
                                fontSize: EnhancedTypography.bodySmall,
                                fontWeight: EnhancedTypography.regular,
                                color: EnhancedAppColors.gray600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const Spacer(),
                            
                            // التقييم والإعجاب
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // التقييم
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 16,
                                      color: EnhancedAppColors.warning,
                                    ),
                                    const SizedBox(width: EnhancedSpacing.xs),
                                    Text(
                                      widget.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: EnhancedTypography.labelMedium,
                                        fontWeight: EnhancedTypography.medium,
                                        color: EnhancedAppColors.gray700,
                                      ),
                                    ),
                                    Text(
                                      ' (${widget.reviewCount})',
                                      style: const TextStyle(
                                        fontSize: EnhancedTypography.labelSmall,
                                        color: EnhancedAppColors.gray500,
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // زر الإعجاب
                                GestureDetector(
                                  onTap: widget.onLike,
                                  child: Row(
                                    children: [
                                      Icon(
                                        widget.isLiked 
                                            ? Icons.favorite 
                                            : Icons.favorite_outline,
                                        size: 18,
                                        color: widget.isLiked 
                                            ? EnhancedAppColors.like 
                                            : EnhancedAppColors.gray400,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookIcon() {
    return Container(
      padding: const EdgeInsets.all(EnhancedSpacing.lg),
      child: Icon(
        Icons.menu_book_rounded,
        size: 48,
        color: Colors.white.withOpacity(0.9),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(EnhancedSpacing.xs),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(EnhancedRadius.xs),
        ),
        child: Icon(
          icon,
          size: 18,
          color: color,
        ),
      ),
    );
  }
}

/// كارت مجتمع الكتاب - للمناقشات والمراجعات
class CommunityBookCard extends StatelessWidget {
  final String title;
  final String author;
  final String category;
  final String? coverUrl;
  final double rating;
  final int reviewCount;
  final int discussionCount;
  final List<String> recentReviewers;
  final VoidCallback? onTap;
  final VoidCallback? onJoinDiscussion;
  
  const CommunityBookCard({
    super.key,
    required this.title,
    required this.author,
    required this.category,
    this.coverUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.discussionCount = 0,
    this.recentReviewers = const [],
    this.onTap,
    this.onJoinDiscussion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: EnhancedSpacing.lg,
        vertical: EnhancedSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(EnhancedRadius.xl),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            EnhancedAppColors.gray50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: EnhancedShadows.medium,
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(EnhancedRadius.xl),
          child: Padding(
            padding: const EdgeInsets.all(EnhancedSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // غلاف الكتاب المصغر
                Container(
                  width: 80,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(EnhancedRadius.md),
                    gradient: EnhancedGradients.getCategoryGradient(category),
                  ),
                  child: coverUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(EnhancedRadius.md),
                          child: Image.network(
                            coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildMiniBookIcon(),
                          ),
                        )
                      : _buildMiniBookIcon(),
                ),
                
                const SizedBox(width: EnhancedSpacing.lg),
                
                // معلومات الكتاب والمجتمع
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // العنوان والمؤلف
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: EnhancedTypography.titleLarge,
                          fontWeight: EnhancedTypography.bold,
                          color: EnhancedAppColors.gray800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: EnhancedSpacing.xs),
                      
                      Text(
                        'بواسطة $author',
                        style: const TextStyle(
                          fontSize: EnhancedTypography.bodyMedium,
                          color: EnhancedAppColors.gray600,
                        ),
                      ),
                      
                      const SizedBox(height: EnhancedSpacing.sm),
                      
                      // شارة الفئة والتقييم
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: EnhancedSpacing.sm,
                              vertical: EnhancedSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: EnhancedAppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(EnhancedRadius.sm),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: EnhancedTypography.labelSmall,
                                fontWeight: EnhancedTypography.medium,
                                color: EnhancedAppColors.primary,
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: EnhancedSpacing.sm),
                          
                          // التقييم
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 16,
                                color: EnhancedAppColors.warning,
                              ),
                              const SizedBox(width: EnhancedSpacing.xs),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: EnhancedTypography.labelMedium,
                                  fontWeight: EnhancedTypography.medium,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: EnhancedSpacing.md),
                      
                      // إحصائيات المجتمع
                      Row(
                        children: [
                          _buildCommunityStats(
                            icon: Icons.rate_review,
                            count: reviewCount,
                            label: 'مراجعة',
                          ),
                          
                          const SizedBox(width: EnhancedSpacing.lg),
                          
                          _buildCommunityStats(
                            icon: Icons.forum,
                            count: discussionCount,
                            label: 'نقاش',
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: EnhancedSpacing.sm),
                      
                      // المراجعون الحديثون
                      if (recentReviewers.isNotEmpty) ...[
                        Row(
                          children: [
                            Text(
                              'مراجعات حديثة: ',
                              style: TextStyle(
                                fontSize: EnhancedTypography.labelMedium,
                                color: EnhancedAppColors.gray600,
                              ),
                            ),
                            ...recentReviewers.take(3).map(
                              (reviewer) => Container(
                                margin: const EdgeInsets.only(
                                  left: EnhancedSpacing.xs,
                                ),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: EnhancedAppColors.social,
                                  child: Text(
                                    reviewer.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: EnhancedTypography.labelSmall,
                                      color: Colors.white,
                                      fontWeight: EnhancedTypography.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: EnhancedSpacing.sm),
                      ],
                      
                      // زر الانضمام للمناقشة
                      ElevatedButton(
                        onPressed: onJoinDiscussion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EnhancedAppColors.community,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: EnhancedSpacing.lg,
                            vertical: EnhancedSpacing.sm,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(EnhancedRadius.md),
                          ),
                        ),
                        child: const Text(
                          'انضم للمناقشة',
                          style: TextStyle(
                            fontSize: EnhancedTypography.labelMedium,
                            fontWeight: EnhancedTypography.medium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBookIcon() {
    return Center(
      child: Icon(
        Icons.menu_book_rounded,
        size: 32,
        color: Colors.white.withOpacity(0.9),
      ),
    );
  }

  Widget _buildCommunityStats({
    required IconData icon,
    required int count,
    required String label,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: EnhancedAppColors.gray500,
        ),
        const SizedBox(width: EnhancedSpacing.xs),
        Text(
          '$count $label',
          style: const TextStyle(
            fontSize: EnhancedTypography.labelMedium,
            color: EnhancedAppColors.gray600,
          ),
        ),
      ],
    );
  }
}
