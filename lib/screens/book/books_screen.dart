import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/book_service.dart';
import '../../models/book_model.dart';
import 'book_details_screen.dart';

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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // شريط التطبيق المرن
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'مكتبة الكتب',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 20,
                        top: 60,
                        child: Icon(
                          Icons.library_books,
                          size: 100,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 60,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Consumer<BookService>(
                              builder: (context, bookService, child) {
                                return Text(
                                  '${bookService.books.length} كتاب متاح',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                            const Text(
                              'اكتشف عالماً من المعرفة',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'الكل'),
                  Tab(text: 'المميزة'),
                  Tab(text: 'الأعلى تقييماً'),
                  Tab(text: 'الأكثر تحميلاً'),
                ],
              ),
            ),

            // شريط البحث والفلترة
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // شريط البحث
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن كتاب أو مؤلف...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.tune),
                              onPressed: _showFilterDialog,
                            ),
                          ],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
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
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAllBooksTab(),
            _buildFeaturedBooksTab(),
            _buildTopRatedBooksTab(),
            _buildMostDownloadedBooksTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBookDialog,
        child: const Icon(Icons.add),
        tooltip: 'إضافة كتاب جديد',
      ),
    );
  }

  Widget _buildAllBooksTab() {
    return Consumer<BookService>(
      builder: (context, bookService, child) {
        final books = bookService.searchBooks(_searchQuery, category: _selectedCategory);
        final sortedBooks = _sortBooks(books);

        if (sortedBooks.isEmpty) {
          return _buildEmptyState('لا توجد كتب تطابق البحث', Icons.search_off);
        }

        return _buildBooksGrid(sortedBooks);
      },
    );
  }

  Widget _buildFeaturedBooksTab() {
    return Consumer<BookService>(
      builder: (context, bookService, child) {
        final books = bookService.featuredBooks;
        return _buildBooksGrid(books);
      },
    );
  }

  Widget _buildTopRatedBooksTab() {
    return Consumer<BookService>(
      builder: (context, bookService, child) {
        final books = bookService.getTopRatedBooks();
        return _buildBooksGrid(books);
      },
    );
  }

  Widget _buildMostDownloadedBooksTab() {
    return Consumer<BookService>(
      builder: (context, bookService, child) {
        final books = bookService.getMostDownloadedBooks();
        return _buildBooksGrid(books);
      },
    );
  }

  Widget _buildBooksGrid(List<BookModel> books) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          return _buildBookCard(books[index]);
        },
      ),
    );
  }

  Widget _buildBookCard(BookModel book) {
    return Consumer<BookService>(
      builder: (context, bookService, child) {
        final isSaved = bookService.isBookSaved(book.id);
        
        return Card(
          elevation: 4,
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
                // غلاف الكتاب
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getBookColor(book.category),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              book.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: IconButton(
                            icon: Icon(
                              isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: isSaved ? Colors.red : Colors.grey,
                            ),
                            onPressed: () {
                              if (isSaved) {
                                bookService.unsaveBook(book.id);
                              } else {
                                bookService.saveBook(book.id);
                              }
                            },
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
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
                            Text(
                              '${book.downloadCount}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
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
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
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
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<BookModel> _sortBooks(List<BookModel> books) {
    final sorted = List<BookModel>.from(books);
    
    switch (_sortBy) {
      case 'الأحدث':
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'الأعلى تقييماً':
        sorted.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 'الأكثر تحميلاً':
        sorted.sort((a, b) => b.downloadCount.compareTo(a.downloadCount));
        break;
      case 'الأبجدي':
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
    }
    
    return sorted;
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ترتيب الكتب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'الأحدث',
            'الأعلى تقييماً',
            'الأكثر تحميلاً',
            'الأبجدي',
          ].map((sortOption) {
            return RadioListTile<String>(
              title: Text(sortOption),
              value: sortOption,
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showAddBookDialog() {
    // TODO: تطبيق صفحة إضافة كتاب جديد
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قريباً: إضافة كتاب جديد')),
    );
  }
}
