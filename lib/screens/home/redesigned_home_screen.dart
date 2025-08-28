import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
import 'upload_book_screen.dart';

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
          items: [
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
          // زر "رفع كتاب" يظهر فقط إن كانت للمستخدم صلاحية الرفع (توحيد عبر الخدمة)
          Consumer<AuthFirebaseService>(
            builder: (context, auth, _) {
              final uid = auth.currentUser?.uid;
              if (uid == null) return const SizedBox.shrink();
              return FutureBuilder<bool>(
                future: auth.canCurrentUserUploadBooks(),
                builder: (context, snap) {
                  final can = snap.data == true;
                  if (!can) return const SizedBox.shrink();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFabMenuItem(
                        icon: Icons.upload_file,
                        label: 'رفع كتاب',
                        color: EnhancedAppColors.accentDark,
                        onTap: () => _navigateToAddBook(),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              );
            },
          ),
          _buildFabMenuItem(
            icon: Icons.forum,
            label: 'بدء نقاش',
            color: EnhancedAppColors.accent,
            onTap: () => _navigateToStartDiscussion(),
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

  Future<void> _navigateToAddBook() async {
    final auth = context.read<AuthFirebaseService>();
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')));
      return;
    }
    try {
      final can = await auth.canCurrentUserUploadBooks();
      if (!mounted) return;
      if (can) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadBookScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ليس لديك صلاحية رفع الكتب. اطلب الإذن من المشرف.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر التحقق من الصلاحية: $e')),
      );
    }
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
              
              // تابع القراءة مع تحسينات
              _buildEnhancedContinueReading(),
              
              const SizedBox(height: EnhancedSpacing.xl),
              
              // التوصيات الذكية
              _buildSmartRecommendations(),
              
              const SizedBox(height: EnhancedSpacing.xl),
              
              // اتجاهات القراءة (Trending)
              _buildTrendingBooks(),
              
              const SizedBox(height: EnhancedSpacing.xl),
              
              // تحديات القراءة
              _buildReadingChallenges(),
              
              const SizedBox(height: EnhancedSpacing.xl),
              
              // المراجعات المميزة (نُقلت لأسفل بعد تحديات القراءة)
              _buildFeaturedReviews(),
              
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
        child: Consumer2<AuthFirebaseService, BookService>(
          builder: (context, authService, bookService, _) {
            final userName = authService.currentUser?.displayName ?? 'عزيزي القارئ';
            final welcomeTime = _getWelcomeTimeMessage();
            final booksCount = bookService.books.length;
            // أرقام توضيحية بسيطة – يمكن ربطها لاحقاً بمصادر حقيقية
            final activeReaders = 892;
            final discussions = 156;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    
                    // ترحيب محسن مع الوقت + إحصائيات المجتمع داخل الهيدر
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
                          const SizedBox(height: 8),
                          // إحصائيات المجتمع المدمجة في الهيدر
                          Row(
                            children: [
                              _miniStat(icon: Icons.menu_book, value: '$booksCount', label: 'كتاب'),
                              const SizedBox(width: 10),
                              _miniStat(icon: Icons.group, value: '$activeReaders', label: 'قارئ نشط'),
                              const SizedBox(width: 10),
                              _miniStat(icon: Icons.forum, value: '$discussions', label: 'نقاش'),
                            ],
                          ),
                          const SizedBox(height: 6),
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

  Widget _miniStat({required IconData icon, required String value, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 12)),
        ],
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
                hintText: 'ابحث عن كتاب، مؤلف، أو موضوع... ',
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
          // اقتراحات البحث السريع من مصدر مركزي (فئات BookService)
          Consumer<BookService>(
            builder: (context, bookService, _) {
              final suggestions = BookService.categories.take(8).toList();
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: suggestions.map((suggestion) => Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: ActionChip(
                      label: Text(
                        suggestion,
                        style: const TextStyle(fontSize: 12, color: EnhancedAppColors.primary),
                      ),
                      backgroundColor: EnhancedAppColors.primary.withOpacity(0.1),
                      onPressed: () {
                        _searchController.text = suggestion;
                        widget.switchTab(1);
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  )).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedContinueReading() {
    return Consumer2<BookService, AuthFirebaseService>(
      builder: (context, bookService, authService, _) {
        final uid = authService.currentUser?.uid ?? '';
        final readingBooks = bookService.getReadingBooks(uid);
        
        if (readingBooks.isEmpty) {
          // إخفاء قسم "ابدأ رحلة القراءة" تماماً
          return const SizedBox.shrink();
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
            // غلاف الكتاب المحسنة
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
        final trendingBooks = bookService.getTrendingBooks(limit: 5);
        
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
    return Consumer3<ReadingChallengeService, BookService, AuthFirebaseService>(
      builder: (context, challengeService, bookService, authService, child) {
        final currentChallenge = challengeService.currentYearChallenge;
        final uid = authService.currentUser?.uid ?? '';
        final completedFromBooks = uid.isEmpty ? 0 : bookService.getCompletedBooks(uid).length;

        if (currentChallenge == null) {
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

        final targetBooks = currentChallenge.targetBooks ?? 0;
        final completedBooks = completedFromBooks;
        final progress = targetBooks > 0
            ? (completedBooks / targetBooks).clamp(0.0, 1.0)
            : currentChallenge.challengeProgress;
        final progressPercent = (progress * 100).round();

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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  EnhancedAppColors.secondary,
                  EnhancedAppColors.accent,
                ],
              ),
              borderRadius: BorderRadius.all(Radius.circular(20)),
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
                        daysRemaining > 0 ? '$daysRemaining أيام متبقية' : 'انتهى التحدي',
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
    String? subtitle,
    VoidCallback? onSeeAll,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EnhancedSpacing.lg),
      child: Column(
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
                        color: EnhancedAppColors.gray900,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: EnhancedAppColors.gray600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                if (onSeeAll != null)
                  TextButton(
                    onPressed: onSeeAll,
                    child: const Text('عرض الكل'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: EnhancedSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EnhancedSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: EnhancedShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: EnhancedAppColors.gray400),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: EnhancedAppColors.gray600)),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToBookDetails(BookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailsScreen(book: book),
      ),
    );
  }

  void _navigateToRecommendations() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('التوصيات قيد التطوير')),
    );
  }

  void _navigateToTrendingBooks() {
    widget.switchTab(1);
  }

  void _navigateToReviews() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('المراجعات قيد التطوير')),
    );
  }

  void _navigateToChallenges() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChallengesScreen()),
    );
  }

  // إضافة دالة التنقل لإنشاء التحدي داخل صفحة الرئيسية
  void _navigateToCreateChallenge() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateChallengeScreen()),
    );
  }

  // تحديث دالة التنقل داخل الصفحة الداخلية أيضاً
  Future<void> _navigateToAddBook() async {
    final auth = context.read<AuthFirebaseService>();
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')));
      return;
    }
    try {
      final can = await auth.canCurrentUserUploadBooks();
      if (!mounted) return;
      if (can) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadBookScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ليس لديك صلاحية رفع الكتب. اطلب الإذن من المشرف.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر التحقق من الصلاحية: $e')),
      );
    }
  }

  void _toggleLike(Map<String, Object> review) {
    setState(() {
      final liked = (review['isLiked'] as bool?) ?? false;
      final likes = (review['likesCount'] as int?) ?? 0;
      review['isLiked'] = !liked;
      review['likesCount'] = likes + (liked ? -1 : 1);
    });
  }

  void _replyToReview(Map<String, Object> review) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('الرد على مراجعة: ${review['reviewerName']}')),
    );
  }

  void _shareReview(Map<String, Object> review) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('مشاركة مراجعة: ${review['bookTitle']}')),
    );
  }

  void _showAdvancedSearch() {
    widget.switchTab(1);
  }

  Future<void> _scanBarcode() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ماسح الباركود قيد التطوير')),
    );
  }

  void _navigateToNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('الإشعارات قريباً')),
    );
  }

  String _getWelcomeTimeMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'مساء الخير';
    return 'أهلًا وسهلًا';
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

