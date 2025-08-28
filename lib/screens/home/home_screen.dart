import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/external_book_model.dart';
import '../../models/reading_list_model.dart';
import '../../services/auth_firebase_service.dart';
import '../../services/book_service.dart';
import '../../services/external_book_search_service.dart';
import '../../services/reading_list_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/mobile_book_card.dart';
import '../../utils/category_utils.dart';

import '../book/books_screen.dart';
import '../book/book_details_screen.dart';
import '../library/library_screen.dart';
import '../profile/profile_screen.dart';
import '../plans/plans_hub_screen.dart';
import '../search/category_books_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void switchTab(int index) {
    setState(() => _selectedIndex = index);
  }

  // تحديث الصفحات لتشمل صفحة الخطط كعلامة تبويب مستقلة
  late final List<Widget> _pages = const [
    HomePage(),
    SearchPage(),
    PlansHubScreen(),
    LibraryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      floatingActionButton: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return FloatingActionButton(
            onPressed: () => themeService.toggle(),
            tooltip: 'تبديل الوضع',
            child: Icon(themeService.isDark ? Icons.dark_mode : Icons.light_mode),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'بحث'),
          BottomNavigationBarItem(icon: Icon(Icons.flag_rounded), label: 'الخطط'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books_rounded), label: 'مكتبتي'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'حسابي'),
        ],
      ),
    );
  }
}

// صفحة رئيسية بتصميم عصري وتفاعلي
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final auth = Provider.of<AuthFirebaseService>(context, listen: false);
    final userName = auth.currentUser?.displayName ?? 'قارئ';

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // رأس تفاعلي جميل
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [color.withOpacity(.85), color.withOpacity(.55)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.1), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(radius: 20, backgroundColor: Colors.white.withOpacity(.25), child: const Icon(Icons.menu_book, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('مرحباً، $userName', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                ),
                IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BooksScreen())), icon: const Icon(Icons.explore, color: Colors.white), tooltip: 'استكشف')
              ]),
              const SizedBox(height: 14),
              Text('ماذا تحب أن تقرأ اليوم؟', style: TextStyle(color: Colors.white.withOpacity(.95), fontSize: 14)),
              const SizedBox(height: 12),
              // شريط بحث اختياري سريع (يوجه لعلامة تبويب البحث)
              GestureDetector(
                onTap: () {
                  final parent = context.findAncestorStateOfType<_HomeScreenState>();
                  parent?.switchTab(1); // انتقل إلى تبويب البحث
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(.3)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(children: [
                    Icon(Icons.search_rounded, color: color),
                    const SizedBox(width: 8),
                    const Text('ابحث عن كتاب أو مؤلف...', style: TextStyle(color: Colors.black54)),
                  ]),
                ),
              ),
            ]),
          ),

          // بطاقات إحصائية سريعة
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Consumer2<BookService, AuthFirebaseService>(
              builder: (context, bookService, authService, _) {
                final uid = authService.currentUser?.uid ?? '';
                final booksCount = bookService.books.length;
                final savedCount = bookService.savedBooks.length;
                final readingCount = bookService.getReadingBooks(uid).length;
                return Row(children: [
                  _StatCard(icon: Icons.menu_book_rounded, label: 'الكتب', value: booksCount.toString(), color: color),
                  const SizedBox(width: 10),
                  _StatCard(icon: Icons.bookmark_rounded, label: 'المحفوظات', value: savedCount.toString(), color: Colors.amber.shade700),
                  const SizedBox(width: 10),
                  _StatCard(icon: Icons.play_circle_fill_rounded, label: 'قيد القراءة', value: readingCount.toString(), color: Colors.teal),
                ]);
              },
            ),
          ),

          // تابع القراءة
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Consumer2<BookService, AuthFirebaseService>(
              builder: (context, bookService, authService, _) {
                final uid = authService.currentUser?.uid ?? '';
                final reading = bookService.getReadingBooks(uid);
                if (reading.isEmpty) return const SizedBox.shrink();
                final book = reading.first;
                final progress = bookService.getReadingProgress(book.id, uid);
                final pct = ((progress?.progressPercentage ?? 0) * 100).toInt();
                return _ContinueCard(
                  title: book.title,
                  author: book.author,
                  percent: pct,
                  accent: getCategoryAccent(book.category),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailsScreen(book: book))),
                );
              },
            ),
          ),

          // فئات سريعة (أيقونات صغيرة)
          SizedBox(
            height: 84,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              scrollDirection: Axis.horizontal,
              itemCount: BookService.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = BookService.categories[i];
                final color = getCategoryAccent(c);
                final icon = getCategoryIcon(c);
                return _CategoryIconChip(
                  color: color,
                  icon: icon,
                  label: c,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryExploreScreen(initialCategory: c),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // كتب مميزة
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('مختارات لك', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ),
          SizedBox(
            height: 210,
            child: Consumer<BookService>(
              builder: (context, service, _) {
                final items = service.featuredBooks;
                if (items.isEmpty) {
                  return Center(
                    child: Text('لا توجد كتب مميزة بعد', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final b = items[i];
                    final accent = getCategoryAccent(b.category);
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailsScreen(book: b))),
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [accent.withOpacity(.15), accent.withOpacity(.05)]),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accent.withOpacity(.25)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 10)],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(Icons.auto_stories_rounded, color: accent, size: 28),
                          const SizedBox(height: 10),
                          Text(b.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Row(children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(b.averageRating.toStringAsFixed(1)),
                          ])
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // إجراء سريع لتصفح كل الكتب
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: _QuickCard(
              title: 'تصفح جميع الكتب',
              color: color,
              icon: Icons.library_books_rounded,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BooksScreen())),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final String title;
  final String author;
  final int percent;
  final Color accent;
  final VoidCallback onTap;
  const _ContinueCard({required this.title, required this.author, required this.percent, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent.withOpacity(.14), accent.withOpacity(.08)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(.25)),
      ),
      child: Row(children: [
        Container(
          width: 56,
          height: 72,
          decoration: BoxDecoration(color: accent.withOpacity(.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.menu_book_rounded, color: accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(author, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(minHeight: 6, value: percent / 100, backgroundColor: Colors.grey[300], valueColor: AlwaysStoppedAnimation(accent)),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(onPressed: onTap, icon: const Icon(Icons.play_arrow_rounded), label: const Text('تابع')),
      ]),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// صفحة البحث مع دمج البحث الخارجي
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'الكل';
  String _selectedSource = 'internal'; // internal | external
  bool _loadingExternal = false;
  List<ExternalBookModel> _externalResults = const [];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('اكتشف كتابك المثالي 📚', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(colors: [
                        colorScheme.primary.withOpacity(0.08),
                        colorScheme.primary.withOpacity(0.04),
                      ]),
                      border: Border.all(color: colorScheme.primary.withOpacity(0.2), width: 1.5),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن كتاب، مؤلف، أو موضوع...',
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary, size: 22),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded, color: Colors.grey[400]),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        if (_selectedSource == 'external') _triggerExternalSearch(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('داخل التطبيق'),
                        selected: _selectedSource == 'internal',
                        onSelected: (v) => setState(() => _selectedSource = 'internal'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('خارجي'),
                        selected: _selectedSource == 'external',
                        onSelected: (v) {
                          setState(() => _selectedSource = 'external');
                          if (_searchQuery.isNotEmpty) _triggerExternalSearch(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: BookService.categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = BookService.categories[index];
                        final isSelected = category == _selectedCategory;
                        return FilterChip(
                          label: Text(
                            category,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isSelected ? Colors.white : colorScheme.primary,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) => setState(() => _selectedCategory = category),
                          backgroundColor: colorScheme.primary.withOpacity(0.1),
                          selectedColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? colorScheme.primary : colorScheme.primary.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _selectedSource == 'internal'
                  ? Consumer<BookService>(
                      builder: (context, bookService, child) {
                        final books = bookService.searchBooks(_searchQuery, category: _selectedCategory);

                        if (_searchQuery.isEmpty && _selectedCategory == 'الكل') return _buildEmptySearchState();
                        if (books.isEmpty) return _buildNoResultsState();

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: books.length,
                          itemBuilder: (context, index) {
                            final book = books[index];
                            return MobileBookListTile(
                              book: book,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookDetailsScreen(book: book),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    )
                  : _buildExternalResults(context, colorScheme, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(Icons.search_rounded, size: 60, color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
          ),
          const SizedBox(height: 24),
          Text('ابحث في مكتبة الكتب', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('اكتشف آلاف الكتب في جميع المجالات', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(60)),
            child: Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text('لم نجد ما تبحث عنه', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Text('جرب البحث بكلمات مختلفة أو تصفح الفئات', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildExternalResults(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    if (_searchQuery.isEmpty) return _buildEmptySearchState();
    if (_loadingExternal) return const Center(child: CircularProgressIndicator());
    if (_externalResults.isEmpty) return _buildNoResultsState();
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _externalResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildExternalTile(context, _externalResults[index], colorScheme, textTheme),
    );
  }

  Future<void> _triggerExternalSearch(BuildContext context) async {
    final svc = context.read<ExternalBookSearchService>();
    setState(() => _loadingExternal = true);
    try {
      final results = await svc.search(_searchQuery);
      if (!mounted) return;
      setState(() => _externalResults = results);
    } finally {
      if (mounted) setState(() => _loadingExternal = false);
    }
  }

  Widget _buildExternalTile(BuildContext context, ExternalBookModel book, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onSelectExternalBook(context, book),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.tertiary.withOpacity(0.3), width: 1),
                  ),
                  child: Icon(Icons.auto_stories_rounded, color: colorScheme.tertiary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(book.authors.join('، '), style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: colorScheme.tertiary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text('خارجي • غير متاح للقراءة', style: textTheme.labelSmall?.copyWith(color: colorScheme.tertiary, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSelectExternalBook(BuildContext context, ExternalBookModel book) async {
    final userId = context.read<AuthFirebaseService>().currentUser?.uid;
    if (userId == null) return;
    final listsSvc = context.read<ReadingListService>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final nameC = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('اختر قائمة لإضافة الكتاب'),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: StreamBuilder<List<ReadingListModel>>(
                  stream: listsSvc.watchUserLists(userId),
                  builder: (context, snapshot) {
                    final lists = snapshot.data ?? const <ReadingListModel>[];
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (lists.isEmpty) {
                      return const Center(child: Text('لا توجد قوائم. أنشئ قائمة جديدة أدناه'));
                    }
                    return ListView.separated(
                      itemCount: lists.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (c, i) {
                        final l = lists[i];
                        return ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          tileColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                          title: Text(l.name),
                          subtitle: Text(l.description ?? ''),
                          trailing: const Icon(Icons.add),
                          onTap: () async {
                            await listsSvc.addItem(
                              listId: l.id,
                              userId: userId,
                              source: ReadingListItemSource.external,
                              externalBookId: book.id,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة الكتاب إلى القائمة')));
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Text('أو أنشئ قائمة جديدة'),
              const SizedBox(height: 8),
              TextField(controller: nameC, decoration: const InputDecoration(hintText: 'اسم القائمة')),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final name = nameC.text.trim();
                    if (name.isEmpty) return;
                    final list = await listsSvc.createList(userId: userId, name: name);
                    await listsSvc.addItem(
                      listId: list.id,
                      userId: userId,
                      source: ReadingListItemSource.external,
                      externalBookId: book.id,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء القائمة وإضافة الكتاب')));
                    }
                  },
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('إنشاء وإضافة'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryIconChip extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CategoryIconChip({required this.color, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(.35)),
            ),
            child: Icon(icon, color: color),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 72,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
