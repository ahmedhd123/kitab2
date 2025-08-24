import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/book_model.dart';
import '../../models/external_book_model.dart';
import '../../models/reading_list_model.dart';
import '../../services/auth_firebase_service.dart';
import '../../services/book_service.dart';
import '../../services/external_book_search_service.dart';
import '../../services/reading_list_service.dart';
import '../../services/theme_service.dart';
import '../../services/review_service.dart';
import '../../services/reading_challenge_service.dart';
import '../../services/enhanced_plan_service.dart';
import '../../models/review_model.dart';

import '../book/books_screen.dart';
import '../book/book_details_screen.dart';
import '../library/enhanced_library_screen.dart';
import '../plans/enhanced_plans_screen.dart';
import '../profile/profile_screen.dart';
import '../plans/plans_hub_screen.dart';
import '../search/search_screen.dart';
import '../challenges/create_challenge_screen.dart';
import '../challenges/challenges_screen.dart';

import '../../widgets/enhanced_book_cards.dart';
import '../../widgets/social_community_widgets.dart';
import '../../widgets/mobile_book_card.dart';
import '../../utils/enhanced_design_tokens.dart';

/// الصفحة الرئيسية المُعاد تصميمها بالكامل
class RedesignedHomeScreen extends StatefulWidget {
  const RedesignedHomeScreen({super.key});

  @override
  State<RedesignedHomeScreen> createState() => _RedesignedHomeScreenState();
}

class _RedesignedHomeScreenState extends State<RedesignedHomeScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fabAnimationController;
  bool _showFabMenu = false;

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadUserData();
  }

  void _loadUserData() {
    // تحميل بيانات المستخدم عند بدء التطبيق
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthFirebaseService>(context, listen: false);
      if (authService.currentUser != null) {
        final challengeService = Provider.of<ReadingChallengeService>(context, listen: false);
        final planService = Provider.of<EnhancedPlanService>(context, listen: false);
        
        // تحميل التحديات والخطط
        challengeService.loadUserChallenges(authService.currentUser!.uid);
        planService.loadUserPlans(authService.currentUser!.uid);
      }
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void switchTab(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // الصفحات المحسّنة
  late final List<Widget> _pages = [
    RedesignedHomePage(switchTab: switchTab),
    const SearchScreen(),
    const EnhancedPlansScreen(),
    const EnhancedLibraryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
        },
        children: _pages,
      ),
      
      // شريط التنقل السفلي المحسن
      bottomNavigationBar: _buildEnhancedBottomNav(),
      
      // زر عائم متعدد الإجراءات
      floatingActionButton: _buildMultiActionFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildEnhancedBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: switchTab,
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedItemColor: EnhancedAppColors.primary,
          unselectedItemColor: EnhancedAppColors.gray500,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'البحث',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.flag_outlined),
              activeIcon: Icon(Icons.flag),
              label: 'الخطط',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books_outlined),
              activeIcon: Icon(Icons.library_books),
              label: 'مكتبتي',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'الملف الشخصي',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiActionFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // القائمة العائمة للإجراءات
        if (_showFabMenu) ...[
          _buildFabMenuItem(
            icon: Icons.emoji_events,
            label: 'إنشاء تحدي',
            color: EnhancedAppColors.primary,
            onTap: () => _navigateToCreateChallenge(),
          ),
          const SizedBox(height: 12),
          _buildFabMenuItem(
            icon: Icons.schedule,
            label: 'إنشاء خطة',
            color: EnhancedAppColors.secondary,
            onTap: () => _navigateToCreatePlan(),
          ),
          const SizedBox(height: 12),
          _buildFabMenuItem(
            icon: Icons.forum,
            label: 'بدء نقاش',
            color: EnhancedAppColors.accent,
            onTap: () => _navigateToStartDiscussion(),
          ),
          const SizedBox(height: 12),
          _buildFabMenuItem(
            icon: Icons.rate_review,
            label: 'كتابة مراجعة',
            color: const Color(0xFF9C27B0),
            onTap: () => _navigateToWriteReview(),
          ),
          const SizedBox(height: 12),
          _buildFabMenuItem(
            icon: Icons.upload_file,
            label: 'رفع كتاب',
            color: const Color(0xFF795548),
            onTap: () => _navigateToUploadBook(),
          ),
          const SizedBox(height: 16),
        ],
        
        // الزر الرئيسي
        FloatingActionButton(
          onPressed: () {
            setState(() => _showFabMenu = !_showFabMenu);
            if (_showFabMenu) {
              _fabAnimationController.forward();
            } else {
              _fabAnimationController.reverse();
            }
          },
          backgroundColor: EnhancedAppColors.primary,
          child: AnimatedRotation(
            turns: _showFabMenu ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _showFabMenu ? Icons.close : Icons.add,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFabMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          onPressed: () {
            setState(() => _showFabMenu = false);
            _fabAnimationController.reverse();
            onTap();
          },
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  void _navigateTo(String route) {
    // TODO: تطبيق التنقل الفعلي حسب المسارات المطلوبة
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('التنقل إلى: $route'),
        backgroundColor: EnhancedAppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // دوال التنقل الجديدة لزر +
  void _navigateToCreateChallenge() {
    setState(() => _showFabMenu = false);
    _fabAnimationController.reverse();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateChallengeScreen(),
      ),
    );
  }

  void _navigateToCreatePlan() {
    setState(() => _showFabMenu = false);
    _fabAnimationController.reverse();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EnhancedPlansScreen(),
      ),
    );
  }

  void _navigateToStartDiscussion() {
    setState(() => _showFabMenu = false);
    _fabAnimationController.reverse();
    
    _showFeatureComingSoon('بدء نقاش');
  }

  void _navigateToWriteReview() {
    setState(() => _showFabMenu = false);
    _fabAnimationController.reverse();
    
    _showFeatureComingSoon('كتابة مراجعة');
  }

  void _navigateToUploadBook() {
    setState(() => _showFabMenu = false);
    _fabAnimationController.reverse();
    
    _showFeatureComingSoon('رفع كتاب');
  }

  void _showFeatureComingSoon(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName قريباً...'),
        backgroundColor: EnhancedAppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// محتوى الصفحة الرئيسية المُعاد تصميمه
class RedesignedHomePage extends StatefulWidget {
  final Function(int) switchTab;

  const RedesignedHomePage({super.key, required this.switchTab});

  @override
  State<RedesignedHomePage> createState() => _RedesignedHomePageState();
}

class _RedesignedHomePageState extends State<RedesignedHomePage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fabAnimationController;
  bool _showFabMenu = false;
  
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // شريط التطبيق المحسن
        _buildEnhancedAppBar(),
        
        // المحتوى الرئيسي
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: EnhancedSpacing.lg),
              
              // شريط البحث التفاعلي المحسن
              _buildEnhancedSearchBar(),
              
              const SizedBox(height: EnhancedSpacing.xl),
              
              // إحصائيات المجتمع المرئية
              _buildVisualCommunityStats(),
              
              const SizedBox(height: EnhancedSpacing.xl),
              
              // تابع القراءة مع تحسينات
              _buildEnhancedContinueReading(),
              
              const SizedBox(height: EnhancedSpacing.xl),
              
              // التوصيات الذكية
              _buildSmartRecommendations(),
              
              const SizedBox(height: EnhancedSpacing.xl),
              
              // اتجاهات القراءة (Trending)
              _buildTrendingBooks(),
              
              const SizedBox(height: EnhancedSpacing.xl),
              
              // المراجعات المميزة
              _buildFeaturedReviews(),
              
              const SizedBox(height: EnhancedSpacing.xl),
              
              // تحديات القراءة
              _buildReadingChallenges(),
              
              const SizedBox(height: 100), // مساحة للـ FAB
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: EnhancedAppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: EnhancedGradients.primaryGradient,
          ),
          child: _buildHeaderContent(),
        ),
      ),
      actions: [
        // زر الإشعارات
        Stack(
          children: [
            IconButton(
              onPressed: () => _navigateToNotifications(),
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              tooltip: 'الإشعارات',
            ),
            // نقطة الإشعارات الجديدة
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: EnhancedAppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        
        // تبديل الوضع
        Consumer<ThemeService>(
          builder: (context, themeService, child) {
            return IconButton(
              onPressed: () => themeService.toggle(),
              icon: Icon(
                themeService.isDark ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
              ),
              tooltip: 'تبديل الوضع',
            );
          },
        ),
        
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeaderContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(EnhancedSpacing.lg),
        child: Consumer<AuthFirebaseService>(
          builder: (context, authService, _) {
            final userName = authService.currentUser?.displayName ?? 'عزيزي القارئ';
            final welcomeTime = _getWelcomeTimeMessage();
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    // صورة المستخدم المحسنة
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '؟',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: EnhancedSpacing.lg),
                    
                    // ترحيب محسن مع الوقت
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            welcomeTime,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          
                          Text(
                            'اكتشف عالمك الجديد من المعرفة 📚',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
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

  Widget _buildEnhancedSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: EnhancedSpacing.lg),
      child: Column(
        children: [
          // شريط البحث الرئيسي
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: EnhancedShadows.soft,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن كتاب، مؤلف، أو موضوع...',
                hintStyle: const TextStyle(color: EnhancedAppColors.gray500),
                prefixIcon: const Icon(Icons.search, color: EnhancedAppColors.gray500),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _showAdvancedSearch(),
                      icon: const Icon(Icons.tune, color: EnhancedAppColors.gray500),
                      tooltip: 'البحث المتقدم',
                    ),
                    IconButton(
                      onPressed: () => _scanBarcode(),
                      icon: const Icon(Icons.qr_code_scanner, color: EnhancedAppColors.gray500),
                      tooltip: 'مسح الباركود',
                    ),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onSubmitted: (query) {
                if (query.isNotEmpty) {
                  widget.switchTab(1); // انتقال لتبويب البحث
                }
              },
            ),
          ),
          
          const SizedBox(height: 12),
          
          // اقتراحات البحث السريع
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'الأدب العربي',
                'روايات تاريخية',
                'كتب التنمية',
                'الفلسفة',
                'العلوم',
                'السيرة الذاتية',
              ].map((suggestion) => Container(
                margin: const EdgeInsets.only(left: 8),
                child: ActionChip(
                  label: Text(
                    suggestion,
                    style: const TextStyle(
                      fontSize: 12,
                      color: EnhancedAppColors.primary,
                    ),
                  ),
                  backgroundColor: EnhancedAppColors.primary.withOpacity(0.1),
                  onPressed: () {
                    _searchController.text = suggestion;
                    widget.switchTab(1);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualCommunityStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: EnhancedSpacing.lg),
      padding: const EdgeInsets.all(EnhancedSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF9A56),
            Color(0xFF10B981),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: EnhancedShadows.medium,
      ),
      child: Column(
        children: [
          const Text(
            'إحصائيات المجتمع',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          Consumer2<BookService, AuthFirebaseService>(
            builder: (context, bookService, authService, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    icon: Icons.trending_up,
                    value: '1.1k',
                    label: 'مراجعة',
                  ),
                  _buildStatItem(
                    icon: Icons.menu_book,
                    value: '${bookService.books.length}',
                    label: 'كتاب',
                  ),
                  _buildStatItem(
                    icon: Icons.group,
                    value: '892',
                    label: 'قارئ نشط',
                  ),
                  _buildStatItem(
                    icon: Icons.forum,
                    value: '156',
                    label: 'نقاش',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedContinueReading() {
    return Consumer2<BookService, AuthFirebaseService>(
      builder: (context, bookService, authService, _) {
        final uid = authService.currentUser?.uid ?? '';
        final readingBooks = bookService.getReadingBooks(uid);
        
        if (readingBooks.isEmpty) {
          return _buildEmptyState(
            icon: Icons.menu_book_outlined,
            title: 'ابدأ رحلة القراءة',
            subtitle: 'اختر كتابك الأول وابدأ المغامرة',
            actionText: 'اكتشف الكتب',
            onAction: () => widget.switchTab(1),
          );
        }
        
        return _buildSectionWithHeader(
          title: '📖 تابع القراءة',
          subtitle: 'أكمل رحلتك مع ${readingBooks.length} كتاب',
          onSeeAll: () => widget.switchTab(3),
          child: SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: EnhancedSpacing.lg),
              itemCount: readingBooks.length,
              itemBuilder: (context, index) {
                final book = readingBooks[index];
                final progress = bookService.getReadingProgress(book.id, uid);
                
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(left: EnhancedSpacing.md),
                  child: _buildEnhancedReadingCard(book, progress?.progressPercentage ?? 0),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedReadingCard(BookModel book, double progress) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: EnhancedShadows.soft,
      ),
      child: InkWell(
        onTap: () => _navigateToBookDetails(book),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // غلاف الكتاب المحسن
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: EnhancedGradients.getCategoryGradient(book.category),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 50,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    
                    // مؤشر التقدم الدائري
                    Positioned(
                      top: 12,
                      right: 12,
                      child: CircularProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                    
                    // نسبة التقدم
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: EnhancedAppColors.gray800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      book.author,
                      style: const TextStyle(
                        fontSize: 12,
                        color: EnhancedAppColors.gray600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: EnhancedAppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(progress * 100).toInt()}% مكتمل',
                            style: const TextStyle(
                              fontSize: 10,
                              color: EnhancedAppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        
                        Icon(
                          Icons.play_circle_filled,
                          color: EnhancedAppColors.primary,
                          size: 20,
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
    );
  }

  Widget _buildSmartRecommendations() {
    final recommendations = [
      RecommendationItem(
        title: 'مئة عام من العزلة',
        author: 'غابرييل غارثيا ماركيث',
        category: 'الأدب',
        reason: 'يُعجب قراء الأدب اللاتيني',
        matchPercentage: 95,
      ),
      RecommendationItem(
        title: 'الخيميائي',
        author: 'باولو كويلو',
        category: 'الفلسفة',
        reason: 'بناءً على مراجعاتك السابقة',
        matchPercentage: 92,
      ),
      RecommendationItem(
        title: 'كيف تؤثر في الآخرين',
        author: 'ديل كارنيغي',
        category: 'التنمية الذاتية',
        reason: 'الأكثر شعبية هذا الشهر',
        matchPercentage: 88,
      ),
    ];

    return _buildSectionWithHeader(
      title: '🎯 توصيات مخصصة لك',
      subtitle: 'كتب منتقاة خصيصاً حسب اهتماماتك',
      onSeeAll: () => _navigateToRecommendations(),
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: EnhancedSpacing.lg),
          itemCount: recommendations.length,
          itemBuilder: (context, index) {
            final rec = recommendations[index];
            return Container(
              width: 300,
              margin: const EdgeInsets.only(left: EnhancedSpacing.md),
              child: _buildRecommendationCard(rec),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(RecommendationItem recommendation) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EnhancedGradients.getCategoryGradient(recommendation.category).colors.first,
            EnhancedGradients.getCategoryGradient(recommendation.category).colors.last,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: EnhancedShadows.medium,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // نسبة التطابق
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${recommendation.matchPercentage}% تطابق',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // عنوان الكتاب
                Text(
                  recommendation.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // المؤلف
                Text(
                  recommendation.author,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                
                const Spacer(),
                
                // سبب التوصية
                Text(
                  recommendation.reason,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // زر العمل
                ElevatedButton(
                  onPressed: () {
                    // TODO: تطبيق عرض تفاصيل الكتاب المُوصى به
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: EnhancedAppColors.primary,
                    minimumSize: const Size(double.infinity, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('عرض التفاصيل'),
                ),
              ],
            ),
          ),
          
          // أيقونة الكتاب
          Positioned(
            top: 20,
            right: 20,
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white.withOpacity(0.3),
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingBooks() {
    return Consumer<BookService>(
      builder: (context, bookService, _) {
        final trendingBooks = bookService.books.take(5).toList();
        
        if (trendingBooks.isEmpty) {
          return _buildEmptyState(
            icon: Icons.trending_up,
            title: 'لا توجد كتب شائعة حالياً',
            subtitle: 'كن أول من يضيف كتاباً',
            actionText: 'إضافة كتاب',
            onAction: () => _navigateToAddBook(),
          );
        }
        
        return _buildSectionWithHeader(
          title: '🔥 الأكثر شعبية',
          subtitle: 'الكتب الأكثر قراءة ومناقشة',
          onSeeAll: () => _navigateToTrendingBooks(),
          child: SizedBox(
            height: 320,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: EnhancedSpacing.lg),
              itemCount: trendingBooks.length,
              itemBuilder: (context, index) {
                final book = trendingBooks[index];
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(left: EnhancedSpacing.md),
                  child: MobileBookCard(
                    book: book,
                    onTap: () => _navigateToBookDetails(book),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturedReviews() {
    final featuredReviews = [
      {
        'reviewerName': 'أحمد محمد',
        'reviewerAvatar': '',
        'rating': 4.5,
        'reviewText': 'كتاب رائع يستحق القراءة بكل تأكيد! أسلوب الكاتب شيق ومميز، والأحداث متسلسلة بطريقة منطقية.',
        'reviewDate': DateTime.now().subtract(const Duration(hours: 2)),
        'likesCount': 24,
        'isLiked': false,
        'isVerifiedReviewer': true,
        'bookTitle': 'الأسود يليق بك',
      },
      {
        'reviewerName': 'فاطمة الزهراء',
        'reviewerAvatar': '',
        'rating': 5.0,
        'reviewText': 'من أفضل الكتب التي قرأتها هذا العام! يغير منظورك للحياة والعلاقات الإنسانية.',
        'reviewDate': DateTime.now().subtract(const Duration(days: 1)),
        'likesCount': 18,
        'isLiked': true,
        'isVerifiedReviewer': false,
        'bookTitle': 'فن اللامبالاة',
      },
    ];
    
    return _buildSectionWithHeader(
      title: '⭐ مراجعات مميزة',
      subtitle: 'آراء القراء حول أفضل الكتب',
      onSeeAll: () => _navigateToReviews(),
      child: Column(
        children: featuredReviews.map((review) => Container(
          margin: const EdgeInsets.only(
            left: EnhancedSpacing.lg,
            right: EnhancedSpacing.lg,
            bottom: EnhancedSpacing.md,
          ),
          child: BookReviewCard(
            reviewerName: review['reviewerName'] as String,
            reviewerAvatar: review['reviewerAvatar'] as String,
            rating: review['rating'] as double,
            reviewText: review['reviewText'] as String,
            reviewDate: review['reviewDate'] as DateTime,
            likesCount: review['likesCount'] as int,
            isLiked: review['isLiked'] as bool,
            isVerifiedReviewer: review['isVerifiedReviewer'] as bool,
            bookTitle: review['bookTitle'] as String,
            onLike: () {
              // تبديل حالة الإعجاب
              _toggleLike(review);
            },
            onReply: () => _replyToReview(review),
            onShare: () => _shareReview(review),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildReadingChallenges() {
    return Consumer<ReadingChallengeService>(
      builder: (context, challengeService, child) {
        final currentChallenge = challengeService.currentYearChallenge;
        
        if (currentChallenge == null) {
          // لا يوجد تحدي نشط - عرض دعوة لإنشاء تحدي
          return _buildSectionWithHeader(
            title: '🏆 تحديات القراءة',
            subtitle: 'تحدى نفسك وحقق أهدافك',
            onSeeAll: () => _navigateToChallenges(),
            child: Container(
              height: 150,
              margin: const EdgeInsets.symmetric(horizontal: EnhancedSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    EnhancedAppColors.primary.withOpacity(0.7),
                    EnhancedAppColors.secondary.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: EnhancedShadows.medium,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'لم تبدأ أي تحدي بعد!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'ابدأ تحدي القراءة وحدد هدفاً لعدد الكتب التي تريد قراءتها',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    ElevatedButton.icon(
                      onPressed: _navigateToCreateChallenge,
                      icon: const Icon(Icons.emoji_events, size: 20),
                      label: const Text('إنشاء تحدي جديد'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: EnhancedAppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        // عرض التحدي النشط
        final progress = currentChallenge.challengeProgress;
        final completedBooks = currentChallenge.completedBooks ?? 0;
        final targetBooks = currentChallenge.targetBooks ?? 0;
        final progressPercent = (progress * 100).round();
        
        // حساب الأيام المتبقية
        final now = DateTime.now();
        final endDate = currentChallenge.endAt ?? DateTime(now.year, 12, 31);
        final daysRemaining = endDate.difference(now).inDays;
        
        return _buildSectionWithHeader(
          title: '🏆 تحديات القراءة',
          subtitle: 'تحدى نفسك وحقق أهدافك',
          onSeeAll: () => _navigateToChallenges(),
          child: Container(
            height: 150,
            margin: const EdgeInsets.symmetric(horizontal: EnhancedSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  EnhancedAppColors.secondary,
                  EnhancedAppColors.accent,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: EnhancedShadows.medium,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          currentChallenge.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$completedBooks/$targetBooks كتب',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    targetBooks > completedBooks 
                        ? 'اقرأ ${targetBooks - completedBooks} كتب أخرى لتحقيق هدفك!'
                        : '🎉 تهانينا! لقد حققت هدفك!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // شريط التقدم
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$progressPercent% مكتمل',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        daysRemaining > 0 
                            ? '$daysRemaining أيام متبقية'
                            : 'انتهى التحدي',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionWithHeader({
    required String title,
    required String subtitle,
    required Widget child,
    VoidCallback? onSeeAll,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: EnhancedSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: EnhancedAppColors.gray800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: EnhancedAppColors.gray600,
                    ),
                  ),
                ],
              ),
              
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text(
                    'عرض الكل',
                    style: TextStyle(
                      fontSize: 14,
                      color: EnhancedAppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Container(
      margin: const EdgeInsets.all(EnhancedSpacing.lg),
      padding: const EdgeInsets.all(EnhancedSpacing.xl),
      decoration: BoxDecoration(
        color: EnhancedAppColors.gray50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EnhancedAppColors.gray200),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: EnhancedAppColors.gray400,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: EnhancedAppColors.gray700,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: EnhancedAppColors.gray600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: EnhancedAppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  String _getWelcomeTimeMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير ☀️';
    if (hour < 18) return 'مساء الخير 🌤️';
    return 'مساء الخير 🌙';
  }

  void _navigateToNotifications() {
    // TODO: تطبيق التنقل لصفحة الإشعارات
    _showFeatureComingSoon('الإشعارات');
  }

  void _navigateToRecommendations() {
    // TODO: تطبيق التنقل لصفحة التوصيات
    _showFeatureComingSoon('التوصيات');
  }

  void _navigateToBookDetails(BookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailsScreen(book: book),
      ),
    );
  }

  void _navigateToTrendingBooks() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BooksScreen(),
      ),
    );
  }

  void _navigateToAddBook() {
    // TODO: تطبيق التنقل لصفحة إضافة كتاب
    _showFeatureComingSoon('إضافة كتاب');
  }

  void _navigateToReviews() {
    // جلب المراجعات الحقيقية من ReviewService
    final reviewService = Provider.of<ReviewService>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('المراجعات المميزة'),
            backgroundColor: EnhancedAppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: Consumer<ReviewService>(
            builder: (context, service, child) {
              return FutureBuilder(
                future: Future.value(<ReviewModel>[]), // إذا كان متوفر
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text('خطأ في تحميل المراجعات: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }
                  
                  // استخدام البيانات الوهمية في الوقت الحالي
                  return const Center(
                    child: Text('المراجعات قريباً...'),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToChallenges() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChallengesScreen(),
      ),
    );
  }

  void _showAdvancedSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAdvancedSearchSheet(),
    );
  }

  void _scanBarcode() {
    // TODO: تطبيق مسح الباركود
    _showFeatureComingSoon('مسح الباركود');
  }

  void _toggleLike(Map<String, dynamic> review) {
    // TODO: تطبيق تبديل الإعجاب
    _showFeatureComingSoon('الإعجاب بالمراجعة');
  }

  void _replyToReview(Map<String, dynamic> review) {
    // TODO: تطبيق الرد على المراجعة
    _showFeatureComingSoon('الرد على المراجعة');
  }

  void _shareReview(Map<String, dynamic> review) {
    // TODO: تطبيق مشاركة المراجعة
    _showFeatureComingSoon('مشاركة المراجعة');
  }

  void _showFeatureComingSoon(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName قريباً...'),
        backgroundColor: EnhancedAppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // دوال التنقل الجديدة لزر +
  void _navigateToCreateChallenge() {
    setState(() => _showFabMenu = false);
    _fabAnimationController.reverse();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateChallengeScreen(),
      ),
    );
  }

  void _navigateToCreatePlan() {
    setState(() => _showFabMenu = false);
    _fabAnimationController.reverse();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EnhancedPlansScreen(),
      ),
    );
  }

  void _navigateToStartDiscussion() {
    setState(() => _showFabMenu = false);
    _fabAnimationController.reverse();
    
    _showFeatureComingSoon('بدء نقاش');
  }

  void _navigateToWriteReview() {
    setState(() => _showFabMenu = false);
    _fabAnimationController.reverse();
    
    _showFeatureComingSoon('كتابة مراجعة');
  }

  void _navigateToUploadBook() {
    setState(() => _showFabMenu = false);
    _fabAnimationController.reverse();
    
    _showFeatureComingSoon('رفع كتاب');
  }

  Widget _buildAdvancedSearchSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // مقبض السحب
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: EnhancedAppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          const Text(
            'البحث المتقدم',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: EnhancedAppColors.gray800,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // مرشحات البحث
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الفئات
                  const Text(
                    'الفئات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: EnhancedAppColors.gray700,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: BookService.categories.map((category) {
                      return FilterChip(
                        label: Text(category),
                        selected: false, // TODO: ربط بحالة التطبيق
                        onSelected: (selected) {
                          // TODO: تطبيق الفلتر
                        },
                        selectedColor: EnhancedAppColors.primary.withOpacity(0.2),
                        checkmarkColor: EnhancedAppColors.primary,
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // التقييم
                  const Text(
                    'التقييم',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: EnhancedAppColors.gray700,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // مرشحات التقييم
                  ...List.generate(5, (index) {
                    final stars = 5 - index;
                    return CheckboxListTile(
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(stars, (i) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          )),
                          ...List.generate(5 - stars, (i) => const Icon(
                            Icons.star_border,
                            color: Colors.grey,
                            size: 16,
                          )),
                          const SizedBox(width: 8),
                          Text('$stars نجوم وأكثر'),
                        ],
                      ),
                      value: false, // TODO: ربط بحالة التطبيق
                      onChanged: (value) {
                        // TODO: تطبيق الفلتر
                      },
                      activeColor: EnhancedAppColors.primary,
                    );
                  }),
                ],
              ),
            ),
          ),
          
          // أزرار العمل
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.switchTab(1); // انتقال للبحث
                  },
                  child: const Text('البحث'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// كلاس للتوصيات
class RecommendationItem {
  final String title;
  final String author;
  final String category;
  final String reason;
  final int matchPercentage;

  RecommendationItem({
    required this.title,
    required this.author,
    required this.category,
    required this.reason,
    required this.matchPercentage,
  });
}

