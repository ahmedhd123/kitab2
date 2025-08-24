import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/book_model.dart';
import '../../services/auth_firebase_service.dart';
import '../../services/book_service.dart';
import '../../services/theme_service.dart';

import '../book/books_screen.dart';
import '../book/book_details_screen.dart';
import '../library/library_screen.dart';
import '../profile/profile_screen.dart';
import '../plans/plans_hub_screen.dart';
import '../search/search_screen.dart';

import '../../widgets/enhanced_book_cards.dart';
import '../../widgets/social_community_widgets.dart';
import '../../utils/enhanced_design_tokens.dart';

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void switchTab(int index) {
    setState(() => _selectedIndex = index);
  }

  // الصفحات المحسّنة
  late final List<Widget> _pages = [
    EnhancedHomePage(switchTab: switchTab),
    const SearchScreen(),
    const PlansHubScreen(),
    const LibraryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      
      // شريط التنقل المحسن
      bottomNavigationBar: EnhancedBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: switchTab,
        items: const [
          EnhancedBottomNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'الرئيسية',
          ),
          EnhancedBottomNavItem(
            icon: Icons.search_outlined,
            activeIcon: Icons.search,
            label: 'البحث',
          ),
          EnhancedBottomNavItem(
            icon: Icons.playlist_add_check_outlined,
            activeIcon: Icons.playlist_add_check,
            label: 'الخطط',
          ),
          EnhancedBottomNavItem(
            icon: Icons.library_books_outlined,
            activeIcon: Icons.library_books,
            label: 'مكتبتي',
          ),
          EnhancedBottomNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'الملف الشخصي',
          ),
        ],
      ),
      
      // زر عائم متعدد الإجراءات
      floatingActionButton: EnhancedFloatingActionButton(
        mainIcon: Icons.add,
        actions: [
          FloatingAction(
            icon: Icons.upload_file,
            label: 'رفع كتاب',
            onPressed: () {
              // انتقال لصفحة رفع الكتب
              Navigator.pushNamed(context, '/upload_book');
            },
            backgroundColor: EnhancedAppColors.primary,
          ),
          FloatingAction(
            icon: Icons.rate_review,
            label: 'كتابة مراجعة',
            onPressed: () {
              // انتقال لصفحة كتابة المراجعة
              Navigator.pushNamed(context, '/write_review');
            },
            backgroundColor: EnhancedAppColors.secondary,
          ),
          FloatingAction(
            icon: Icons.forum,
            label: 'بدء نقاش',
            onPressed: () {
              // انتقال لصفحة بدء النقاشات
              Navigator.pushNamed(context, '/start_discussion');
            },
            backgroundColor: EnhancedAppColors.community,
          ),
        ],
      ),
    );
  }
}

/// الصفحة الرئيسية المحسّنة
class EnhancedHomePage extends StatefulWidget {
  final Function(int) switchTab;

  const EnhancedHomePage({super.key, required this.switchTab});

  @override
  State<EnhancedHomePage> createState() => _EnhancedHomePageState();
}

class _EnhancedHomePageState extends State<EnhancedHomePage>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  // بيانات وهمية للتوصيات - يمكن استبدالها بالبيانات الحقيقية
  final List<RecommendationItem> _recommendations = [
    RecommendationItem(
      title: 'مئة عام من العزلة',
      author: 'غابرييل غارثيا ماركيث',
      category: 'الأدب',
      reason: 'يُعجب قراء الأدب اللاتيني',
      matchPercentage: 92,
    ),
    RecommendationItem(
      title: 'الخيميائي',
      author: 'باولو كويلو',
      category: 'الفلسفة',
      reason: 'بناءً على مراجعاتك السابقة',
      matchPercentage: 88,
    ),
    RecommendationItem(
      title: 'كيف تؤثر في الآخرين',
      author: 'ديل كارنيغي',
      category: 'التنمية الذاتية',
      reason: 'الأكثر شعبية هذا الشهر',
      matchPercentage: 85,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomScrollView(
      slivers: [
        // شريط التطبيق المحسن
        SliverAppBar(
          expandedHeight: 200,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: EnhancedGradients.primaryGradient,
              ),
              child: _buildHeaderContent(),
            ),
          ),
          backgroundColor: EnhancedAppColors.primary,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () {
                // صفحة الإشعارات
                Navigator.pushNamed(context, '/notifications');
              },
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'الإشعارات',
            ),
            Consumer<ThemeService>(
              builder: (context, themeService, child) {
                return IconButton(
                  onPressed: () => themeService.toggle(),
                  icon: Icon(
                    themeService.isDark ? Icons.light_mode : Icons.dark_mode,
                  ),
                  tooltip: 'تبديل الوضع',
                );
              },
            ),
          ],
        ),
        
        // المحتوى الرئيسي
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: EnhancedSpacing.lg),
              
              // إحصائيات المجتمع
              Consumer2<BookService, AuthFirebaseService>(
                builder: (context, bookService, authService, _) {
                  return CommunityStatsWidget(
                    totalBooks: bookService.books.length,
                    totalReviews: 1250, // من قاعدة البيانات
                    activeReaders: 892,  // من قاعدة البيانات
                    discussions: 156,   // من قاعدة البيانات
                  );
                },
              ),
              
              // شريط البحث التفاعلي
              EnhancedSearchBar(
                hintText: 'ابحث عن كتاب، مؤلف أو موضوع...',
                suggestions: const [
                  'الأدب العربي',
                  'روايات تاريخية',
                  'كتب التنمية الذاتية',
                  'الفلسفة الحديثة',
                ],
                showSuggestions: true,
                onSubmitted: (query) {
                  widget.switchTab(1); // انتقال لتبويب البحث
                },
                onFilter: () {
                  // عرض مرشحات البحث
                  _showSearchFilters();
                },
              ),
              
              // تابع القراءة
              _buildContinueReading(),
              
              // التوصيات الشخصية
              PersonalizedRecommendations(
                recommendations: _recommendations,
                onSeeAll: () {
                  Navigator.pushNamed(context, '/recommendations');
                },
              ),
              
              const SizedBox(height: EnhancedSpacing.lg),
              
              // الكتب الشائعة
              _buildPopularBooks(),
              
              const SizedBox(height: EnhancedSpacing.lg),
              
              // مراجعات المجتمع الحديثة
              _buildRecentReviews(),
              
              const SizedBox(height: EnhancedSpacing.huge),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(EnhancedSpacing.lg),
        child: Consumer<AuthFirebaseService>(
          builder: (context, authService, _) {
            final userName = authService.currentUser?.displayName ?? 'المستخدم';
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    // صورة المستخدم
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '؟',
                        style: const TextStyle(
                          fontSize: EnhancedTypography.headlineSmall,
                          fontWeight: EnhancedTypography.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: EnhancedSpacing.lg),
                    
                    // ترحيب المستخدم
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'أهلاً بك، $userName 👋',
                            style: const TextStyle(
                              fontSize: EnhancedTypography.headlineMedium,
                              fontWeight: EnhancedTypography.bold,
                              color: Colors.white,
                            ),
                          ),
                          
                          const SizedBox(height: EnhancedSpacing.xs),
                          
                          Text(
                            'اكتشف عالمك الجديد من الكتب',
                            style: TextStyle(
                              fontSize: EnhancedTypography.bodyMedium,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContinueReading() {
    return Consumer2<BookService, AuthFirebaseService>(
      builder: (context, bookService, authService, _) {
        final uid = authService.currentUser?.uid ?? '';
        final readingBooks = bookService.getReadingBooks(uid);
        
        if (readingBooks.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(EnhancedSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📖 تابع القراءة',
                    style: TextStyle(
                      fontSize: EnhancedTypography.headlineSmall,
                      fontWeight: EnhancedTypography.bold,
                      color: EnhancedAppColors.gray800,
                    ),
                  ),
                  
                  TextButton(
                    onPressed: () => widget.switchTab(3), // انتقال للمكتبة
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
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: EnhancedSpacing.lg),
                itemCount: readingBooks.length,
                itemBuilder: (context, index) {
                  final book = readingBooks[index];
                  final progress = bookService.getReadingProgress(book.id, uid);
                  
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(left: EnhancedSpacing.md),
                    child: _buildContinueReadingCard(book, progress?.progressPercentage ?? 0),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContinueReadingCard(BookModel book, double progress) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EnhancedRadius.lg),
        boxShadow: EnhancedShadows.soft,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookDetailsScreen(book: book),
            ),
          );
        },
        borderRadius: BorderRadius.circular(EnhancedRadius.lg),
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
                  gradient: EnhancedGradients.getCategoryGradient(book.category),
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
                    
                    // شريط التقدم
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
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
                      book.title,
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
                      book.author,
                      style: const TextStyle(
                        fontSize: EnhancedTypography.bodySmall,
                        color: EnhancedAppColors.gray600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    Text(
                      '${(progress * 100).toInt()}% مكتمل',
                      style: const TextStyle(
                        fontSize: EnhancedTypography.labelSmall,
                        color: EnhancedAppColors.success,
                        fontWeight: EnhancedTypography.medium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularBooks() {
    return Consumer<BookService>(
      builder: (context, bookService, _) {
        final popularBooks = bookService.books.take(10).toList();
        
        if (popularBooks.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(EnhancedSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🔥 الأكثر شعبية',
                    style: TextStyle(
                      fontSize: EnhancedTypography.headlineSmall,
                      fontWeight: EnhancedTypography.bold,
                      color: EnhancedAppColors.gray800,
                    ),
                  ),
                  
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BooksScreen(),
                        ),
                      );
                    },
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
              height: 300,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: EnhancedSpacing.lg),
                itemCount: popularBooks.length,
                itemBuilder: (context, index) {
                  final book = popularBooks[index];
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(left: EnhancedSpacing.md),
                    child: EnhancedBookCard(
                      title: book.title,
                      author: book.author,
                      category: book.category,
                      rating: book.averageRating,
                      reviewCount: book.totalReviews,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookDetailsScreen(book: book),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentReviews() {
    // بيانات وهمية للمراجعات - يمكن استبدالها بالبيانات الحقيقية
    final recentReviews = [
      {
        'reviewerName': 'أحمد محمد',
        'reviewerAvatar': '',
        'rating': 4.5,
        'reviewText': 'كتاب رائع يستحق القراءة، أسلوب الكاتب شيق ومميز.',
        'reviewDate': DateTime.now().subtract(const Duration(hours: 2)),
        'likesCount': 12,
        'isLiked': false,
        'isVerifiedReviewer': true,
      },
      {
        'reviewerName': 'فاطمة الزهراء',
        'reviewerAvatar': '',
        'rating': 5.0,
        'reviewText': 'من أفضل الكتب التي قرأتها، يغير منظورك للحياة.',
        'reviewDate': DateTime.now().subtract(const Duration(days: 1)),
        'likesCount': 8,
        'isLiked': true,
        'isVerifiedReviewer': false,
      },
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(EnhancedSpacing.lg),
          child: Text(
            '💬 مراجعات المجتمع الحديثة',
            style: TextStyle(
              fontSize: EnhancedTypography.headlineSmall,
              fontWeight: EnhancedTypography.bold,
              color: EnhancedAppColors.gray800,
            ),
          ),
        ),
        
        ...recentReviews.map((review) => BookReviewCard(
          reviewerName: review['reviewerName'] as String,
          reviewerAvatar: review['reviewerAvatar'] as String,
          rating: review['rating'] as double,
          reviewText: review['reviewText'] as String,
          reviewDate: review['reviewDate'] as DateTime,
          likesCount: review['likesCount'] as int,
          isLiked: review['isLiked'] as bool,
          isVerifiedReviewer: review['isVerifiedReviewer'] as bool,
          onLike: () {
            // تبديل حالة الإعجاب
          },
          onReply: () {
            // الرد على المراجعة
          },
          onShare: () {
            // مشاركة المراجعة
          },
        )),
      ],
    );
  }

  void _showSearchFilters() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EnhancedRadius.xl),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(EnhancedSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مرشحات البحث',
                style: TextStyle(
                  fontSize: EnhancedTypography.headlineSmall,
                  fontWeight: EnhancedTypography.bold,
                  color: EnhancedAppColors.gray800,
                ),
              ),
              
              const SizedBox(height: EnhancedSpacing.lg),
              
              // مرشحات الفئات
              const Text(
                'الفئات',
                style: TextStyle(
                  fontSize: EnhancedTypography.titleMedium,
                  fontWeight: EnhancedTypography.semiBold,
                  color: EnhancedAppColors.gray700,
                ),
              ),
              
              const SizedBox(height: EnhancedSpacing.sm),
              
              Wrap(
                spacing: EnhancedSpacing.sm,
                runSpacing: EnhancedSpacing.sm,
                children: BookService.categories.map((category) {
                  return FilterChip(
                    label: Text(category),
                    onSelected: (selected) {
                      // تطبيق الفلتر
                    },
                  );
                }).toList(),
              ),
              
              const SizedBox(height: EnhancedSpacing.lg),
              
              // أزرار العمل
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  
                  const SizedBox(width: EnhancedSpacing.md),
                  
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.switchTab(1); // انتقال للبحث
                      },
                      child: const Text('تطبيق'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
