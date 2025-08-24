import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/book_service.dart';
import '../../models/book_model.dart';
import '../../widgets/book_card.dart';
import '../../widgets/mobile_book_card.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'الكل';
  String _searchQuery = '';
  String _sortBy = 'الأحدث'; // الأحدث، الأعلى تقييماً، الأكثر تحميلاً
  String _authorFilter = '';
  double _minRating = 0.0;
  bool _isLoading = false;
  List<BookModel>? _advancedResults;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مكتبة الكتب'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'الشائعة'),
            Tab(text: 'الجديدة'),
            Tab(text: 'البحث المتقدم'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllBooksTab(),
          _buildPopularBooksTab(),
          _buildNewBooksTab(),
          _buildAdvancedSearchTab(),
        ],
      ),
    );
  }

  Widget _buildAllBooksTab() {
    return Consumer<BookService>(
      builder: (context, bookService, child) {
        final books = bookService.books;
        
        if (books.isEmpty) {
          return _buildEmptyState('لا توجد كتب متاحة', Icons.library_books);
        }

        return _buildBooksGrid(books);
      },
    );
  }

  Widget _buildPopularBooksTab() {
    return Consumer<BookService>(
      builder: (context, bookService, child) {
        final books = bookService.books
            .where((book) => book.averageRating >= 4.0)
            .toList()
          ..sort((a, b) => b.averageRating.compareTo(a.averageRating));
        
        if (books.isEmpty) {
          return _buildEmptyState('لا توجد كتب شائعة', Icons.trending_up);
        }

        return _buildBooksGrid(books);
      },
    );
  }

  Widget _buildNewBooksTab() {
    return Consumer<BookService>(
      builder: (context, bookService, child) {
        final books = bookService.books.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        if (books.isEmpty) {
          return _buildEmptyState('لا توجد كتب جديدة', Icons.new_releases);
        }

        return _buildBooksGrid(books.take(20).toList());
      },
    );
  }

  Widget _buildAdvancedSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // شريط البحث
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'ابحث عن كتاب أو مؤلف...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // خيارات التصفية
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
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
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value ?? 'الكل';
                    });
                  },
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: const InputDecoration(
                    labelText: 'الترتيب',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'الأحدث', child: Text('الأحدث')),
                    DropdownMenuItem(value: 'الأعلى تقييماً', child: Text('الأعلى تقييماً')),
                    DropdownMenuItem(value: 'الأكثر تحميلاً', child: Text('الأكثر تحميلاً')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value ?? 'الأحدث';
                    });
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // مؤلف محدد
          TextField(
            decoration: const InputDecoration(
              hintText: 'اسم المؤلف (اختياري)',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _authorFilter = value;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // تقييم أدنى
          Row(
            children: [
              const Text('التقييم الأدنى: '),
              Expanded(
                child: Slider(
                  value: _minRating,
                  min: 0.0,
                  max: 5.0,
                  divisions: 10,
                  label: _minRating.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      _minRating = value;
                    });
                  },
                ),
              ),
              Text(_minRating.toStringAsFixed(1)),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // زر البحث
          ElevatedButton(
            onPressed: _performAdvancedSearch,
            child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('بحث متقدم'),
          ),
          
          const SizedBox(height: 16),
          
          // النتائج
          Expanded(
            child: _advancedResults == null
                ? const Center(
                    child: Text('استخدم خيارات البحث أعلاه للحصول على نتائج مخصصة'),
                  )
                : _advancedResults!.isEmpty
                    ? _buildEmptyState('لم يتم العثور على نتائج', Icons.search_off)
                    : _buildBooksGrid(_advancedResults!),
          ),
        ],
      ),
    );
  }

  void _performAdvancedSearch() {
    setState(() {
      _isLoading = true;
    });

    // محاكاة تأخير البحث
    Future.delayed(const Duration(seconds: 1), () {
      final bookService = Provider.of<BookService>(context, listen: false);
      List<BookModel> results = bookService.books;

      // تطبيق الفلاتر
      if (_searchQuery.isNotEmpty) {
        results = results.where((book) =>
            book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            book.author.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            book.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
      }

      if (_selectedCategory != 'الكل') {
        results = results.where((book) => book.category == _selectedCategory).toList();
      }

      if (_authorFilter.isNotEmpty) {
        results = results.where((book) =>
            book.author.toLowerCase().contains(_authorFilter.toLowerCase())).toList();
      }

      results = results.where((book) => book.averageRating >= _minRating).toList();

      // ترتيب النتائج
      switch (_sortBy) {
        case 'الأعلى تقييماً':
          results.sort((a, b) => b.averageRating.compareTo(a.averageRating));
          break;
        case 'الأكثر تحميلاً':
          results.sort((a, b) => b.downloadCount.compareTo(a.downloadCount));
          break;
        case 'الأحدث':
        default:
          results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
      }

      if (mounted) {
        setState(() {
          _advancedResults = results;
          _isLoading = false;
        });
      }
    });
  }

  Widget _buildBooksGrid(List<BookModel> books) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          return MobileBookCard(book: books[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
