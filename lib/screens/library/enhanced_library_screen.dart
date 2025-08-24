import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/book_service.dart';
import '../../models/book_model.dart';
import '../book/book_details_screen.dart';
import '../../widgets/mobile_book_card.dart';

class EnhancedLibraryScreen extends StatefulWidget {
  const EnhancedLibraryScreen({super.key});

  @override
  State<EnhancedLibraryScreen> createState() => _EnhancedLibraryScreenState();
}

class _EnhancedLibraryScreenState extends State<EnhancedLibraryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  
  String _query = '';
  String _category = 'الكل';
  String _sort = 'rating';
  bool _isSearchExpanded = false;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('مكتبتي الشخصية'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => setState(() => _isGridView = !_isGridView),
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? 'عرض قائمة' : 'عرض شبكي',
          ),
          IconButton(
            onPressed: _toggleSearchExpansion,
            icon: const Icon(Icons.search),
            tooltip: 'البحث',
          ),
        ],
      ),
      body: Column(
        children: [
          // قسم البحث القابل للتوسع
          if (_isSearchExpanded) _buildSearchSection(),
          
          // شريط التبويبات
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.blue,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'أقرؤها الآن'),
                Tab(text: 'مكتملة'),
                Tab(text: 'المفضلة'),
                Tab(text: 'أريد قراءتها'),
              ],
            ),
          ),
          
          // المحتوى الرئيسي
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBooksTab('reading'),
                _buildBooksTab('completed'),
                _buildBooksTab('favorite'),
                _buildBooksTab('wishlist'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // شريط البحث
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              decoration: const InputDecoration(
                hintText: 'ابحث في مكتبتي...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // المرشحات السريعة
          Row(
            children: [
              // مرشح الفئة
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'الفئة',
                    border: OutlineInputBorder(),
                  ),
                  items: ['الكل', ...BookService.categories].map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _category = value ?? 'الكل'),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // مرشح الترتيب
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sort,
                  decoration: const InputDecoration(
                    labelText: 'الترتيب',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'rating', child: Text('الأعلى تقييماً')),
                    DropdownMenuItem(value: 'title', child: Text('العنوان')),
                    DropdownMenuItem(value: 'date', child: Text('التاريخ')),
                    DropdownMenuItem(value: 'author', child: Text('المؤلف')),
                  ],
                  onChanged: (value) => setState(() => _sort = value ?? 'rating'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBooksTab(String tabType) {
    return Consumer<BookService>(
      builder: (context, bookService, child) {
        List<BookModel> books = _getFilteredBooks(bookService, tabType);
        
        if (books.isEmpty) {
          return _buildEmptyState(tabType);
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: _isGridView 
              ? _buildGridView(books)
              : _buildListView(books),
        );
      },
    );
  }

  Widget _buildGridView(List<BookModel> books) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return MobileBookCard(
          book: book,
          onTap: () => _navigateToBookDetails(book),
          showProgress: _tabController.index == 0, // إظهار التقدم في تبويب "أقرؤها الآن"
          readingProgress: _tabController.index == 0 ? 0.3 : null, // محاكاة التقدم
        );
      },
    );
  }

  Widget _buildListView(List<BookModel> books) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return MobileBookListTile(
          book: book,
          onTap: () => _navigateToBookDetails(book),
          trailing: _tabController.index == 0 
              ? const Icon(Icons.play_arrow, color: Colors.green)
              : null,
        );
      },
    );
  }

  Widget _buildEmptyState(String tabType) {
    String title, description;
    IconData icon;
    
    switch (tabType) {
      case 'reading':
        title = 'لا توجد كتب تقرؤها حالياً';
        description = 'ابدأ قراءة كتاب جديد لتظهر هنا';
        icon = Icons.menu_book_outlined;
        break;
      case 'completed':
        title = 'لا توجد كتب مكتملة';
        description = 'اكمل قراءة كتاب لتظهر هنا';
        icon = Icons.task_alt;
        break;
      case 'favorite':
        title = 'لا توجد كتب مفضلة';
        description = 'أضف كتبك المفضلة لتظهر هنا';
        icon = Icons.favorite_border;
        break;
      case 'wishlist':
        title = 'قائمة الرغبات فارغة';
        description = 'أضف الكتب التي تريد قراءتها';
        icon = Icons.bookmark_add_outlined;
        break;
      default:
        title = 'لا توجد كتب';
        description = 'أضف كتباً جديدة';
        icon = Icons.library_books_outlined;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/home'),
            icon: const Icon(Icons.explore),
            label: const Text('استكشف الكتب'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  List<BookModel> _getFilteredBooks(BookService bookService, String tabType) {
    List<BookModel> books;
    
    switch (tabType) {
      case 'reading':
        books = bookService.books.take(5).toList();
        break;
      case 'completed':
        books = bookService.books.skip(5).take(3).toList();
        break;
      case 'favorite':
        books = bookService.books.where((b) => b.averageRating >= 4.0).toList();
        break;
      case 'wishlist':
        books = bookService.books.skip(8).take(4).toList();
        break;
      default:
        books = bookService.books;
    }

    if (_query.isNotEmpty) {
      books = books.where((book) {
        return book.title.toLowerCase().contains(_query.toLowerCase()) ||
               book.author.toLowerCase().contains(_query.toLowerCase());
      }).toList();
    }

    if (_category != 'الكل') {
      books = books.where((book) => book.category == _category).toList();
    }

    switch (_sort) {
      case 'title':
        books.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'author':
        books.sort((a, b) => a.author.compareTo(b.author));
        break;
      case 'date':
        books.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'rating':
      default:
        books.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
    }

    return books;
  }

  void _toggleSearchExpansion() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (_isSearchExpanded) {
        _searchFocus.requestFocus();
      } else {
        _searchFocus.unfocus();
        _searchController.clear();
        _query = '';
      }
    });
  }

  void _navigateToBookDetails(BookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailsScreen(book: book),
      ),
    );
  }
}
