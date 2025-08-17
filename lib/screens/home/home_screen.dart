import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_firebase_service.dart';
import '../../services/theme_service.dart';
import '../../services/book_service.dart';
import '../book/books_screen.dart';
import '../book/book_details_screen.dart';
import '../library/library_screen.dart';
import 'upload_book_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    const HomePage(),
    const SearchPage(),
  const LibraryScreen(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      floatingActionButton: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return FloatingActionButton(
            onPressed: () => themeService.toggle(),
            child: Icon(themeService.isDark ? Icons.dark_mode : Icons.light_mode),
            tooltip: 'تبديل الوضع',
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'بحث'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books_rounded), label: 'مكتبتي'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'حسابي'),
        ],
      ),
    );
  }
}

// صفحة الرئيسية المعاد بناؤها
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthFirebaseService, BookService>(
      builder: (context, authService, bookService, child) {
        final primary = Theme.of(context).colorScheme.primary;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [primary, primary.withOpacity(.75)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(.25),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحباً، ${authService.currentUser?.email?.split('@')[0] ?? 'القارئ'}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      const Text('ابدأ رحلتك المعرفية اليوم', style: TextStyle(fontSize: 15, color: Colors.white70)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _miniStat('الكتب', bookService.books.length.toString(), Icons.menu_book)),
                          const SizedBox(width: 10),
                          Expanded(child: _miniStat('محفوظة', bookService.savedBooks.length.toString(), Icons.bookmark)),
                          const SizedBox(width: 10),
                          Expanded(child: _miniStat('قيد القراءة', bookService.getReadingBooks(authService.currentUser?.uid ?? '').length.toString(), Icons.timelapse)),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BooksScreen())),
                        icon: const Icon(Icons.library_books),
                        label: const Text('تصفح الكتب'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UploadBookScreen())),
                          icon: const Icon(Icons.upload_file),
                          label: const Text('رفع كتاب'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 28),

                _sectionHeader(context, 'الكتب المميزة', onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BooksScreen()))),
                SizedBox(
                  height: 210,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: bookService.featuredBooks.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (c, i) {
                      final b = bookService.featuredBooks[i];
                      return SizedBox(
                        width: 150,
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 0,
                          color: Theme.of(context).cardColor,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailsScreen(book: b))),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context).colorScheme.primary.withOpacity(.85),
                                            Theme.of(context).colorScheme.primary.withOpacity(.55),
                                          ],
                                          begin: Alignment.topRight,
                                          end: Alignment.bottomLeft,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 44),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(b.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.2)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, size: 14, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text(b.averageRating.toStringAsFixed(1), style: Theme.of(context).textTheme.labelSmall),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),

                _sectionHeader(context, 'الأكثر تحميلاً', onViewAll: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BooksScreen()))),
                const SizedBox(height: 12),
                ...bookService.getMostDownloadedBooks(limit: 3).map((b) => _downloadedTile(context, b)).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _miniStat(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  static Widget _sectionHeader(BuildContext context, String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        if (onViewAll != null) TextButton(onPressed: onViewAll, child: const Text('عرض الكل')),
      ],
    );
  }

  static Widget _downloadedTile(BuildContext context, book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(.75),
                Theme.of(context).colorScheme.primary.withOpacity(.45),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: const Icon(Icons.menu_book, color: Colors.white),
        ),
        title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            const Icon(Icons.download_rounded, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${book.downloadCount}', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 12),
            const Icon(Icons.star, size: 14, color: Colors.amber),
            const SizedBox(width: 4),
            Text(book.averageRating.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
          ],
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailsScreen(book: book))),
      ),
    );
  }
}

// صفحة البحث
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // شريط البحث
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن كتاب أو مؤلف...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // فلاتر الفئات
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: BookService.categories.length,
                    itemBuilder: (context, index) {
                      final category = BookService.categories[index];
                      final isSelected = category == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          checkmarkColor: Theme.of(context).primaryColor,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // نتائج البحث
          Expanded(
            child: Consumer<BookService>(
              builder: (context, bookService, child) {
                final books = bookService.searchBooks(_searchQuery, category: _selectedCategory);
                
                if (_searchQuery.isEmpty && _selectedCategory == 'الكل') {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 100,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'ابحث عن الكتب والمؤلفين',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (books.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 100,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'لا توجد نتائج للبحث',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
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
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(book.author),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getBookColor(book.category).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    book.category,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _getBookColor(book.category),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  book.averageRating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookDetailsScreen(book: book),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
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
}

// صفحة المكتبة
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مكتبتي'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'قيد القراءة'),
            Tab(text: 'مكتملة'),
            Tab(text: 'محفوظة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReadingBooks(),
          _buildCompletedBooks(),
          _buildSavedBooks(),
        ],
      ),
    );
  }

  Widget _buildReadingBooks() {
    return Consumer2<BookService, AuthFirebaseService>(
      builder: (context, bookService, authService, child) {
        final uid = authService.currentUser?.uid ?? '';
        final readingBooks = bookService.getReadingBooks(uid);
        
        if (readingBooks.isEmpty) {
          return _buildEmptyState(
            'لا توجد كتب قيد القراءة',
            'ابدأ بقراءة كتاب جديد الآن',
            Icons.menu_book,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: readingBooks.length,
          itemBuilder: (context, index) {
            final book = readingBooks[index];
            final progress = bookService.getReadingProgress(book.id, uid);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
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
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.author),
                    const SizedBox(height: 8),
                    if (progress != null) ...[
                      LinearProgressIndicator(
                        value: progress.progressPercentage,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getBookColor(book.category),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الصفحة ${progress.currentPage} من ${progress.totalPages} (${(progress.progressPercentage * 100).toInt()}%)',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailsScreen(book: book),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getBookColor(book.category),
                    minimumSize: const Size(60, 30),
                  ),
                  child: const Text(
                    'متابعة',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompletedBooks() {
    return Consumer2<BookService, AuthFirebaseService>(
      builder: (context, bookService, authService, child) {
        final uid = authService.currentUser?.uid ?? '';
        final completedBooks = bookService.getCompletedBooks(uid);
        
        if (completedBooks.isEmpty) {
          return _buildEmptyState(
            'لم تكمل أي كتاب بعد',
            'أكمل قراءة كتابك الأول',
            Icons.check_circle,
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: completedBooks.length,
          itemBuilder: (context, index) {
            final book = completedBooks[index];
            
            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailsScreen(book: book),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _getBookColor(book.category).withOpacity(0.2),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Icon(
                                Icons.menu_book,
                                size: 48,
                                color: _getBookColor(book.category),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              book.author,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  book.averageRating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 12),
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
          },
        );
      },
    );
  }

  Widget _buildSavedBooks() {
    return Consumer<BookService>(
      builder: (context, bookService, child) {
        final savedBooks = bookService.getSavedBooks();
        
        if (savedBooks.isEmpty) {
          return _buildEmptyState(
            'لا توجد كتب محفوظة',
            'احفظ الكتب لقراءتها لاحقاً',
            Icons.bookmark,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: savedBooks.length,
          itemBuilder: (context, index) {
            final book = savedBooks[index];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
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
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.author),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getBookColor(book.category).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            book.category,
                            style: TextStyle(
                              fontSize: 10,
                              color: _getBookColor(book.category),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          book.averageRating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.bookmark_remove, color: Colors.red),
                      onPressed: () {
                        bookService.unsaveBook(book.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم إزالة الكتاب من المحفوظات')),
                        );
                      },
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailsScreen(book: book),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BooksScreen(),
                ),
              );
            },
            child: const Text('تصفح الكتب'),
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
}

// صفحة الملف الشخصي
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
  body: Consumer<AuthFirebaseService>(
        builder: (context, authService, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person,
                  size: 100,
                  color: Colors.purple,
                ),
                const SizedBox(height: 20),
                Text(
                  'الملف الشخصي',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text('البريد الإلكتروني: ${authService.currentUser?.email ?? 'غير محدد'}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () async {
                    await authService.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
