import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/book_model.dart';
import '../../services/book_service.dart';
import '../book/book_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  
  List<BookModel> _searchResults = [];
  List<String> _recentSearches = [];
  bool _isSearching = false;
  String _selectedCategory = 'الكل';
  double _minRating = 0.0;
  String _sortBy = 'relevance';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // شريط البحث المحسن
            _buildEnhancedSearchBar(),
            
            // المحتوى الرئيسي
            Expanded(
              child: _searchController.text.isEmpty
                  ? _buildSearchSuggestions()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // أيقونة البحث
            Container(
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.search,
                color: Colors.grey,
                size: 24,
              ),
            ),
            
            // حقل النص
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                decoration: const InputDecoration(
                  hintText: 'ابحث عن كتاب، مؤلف، أو موضوع...',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                onChanged: _performSearch,
                onSubmitted: _onSearchSubmitted,
              ),
            ),
            
            // زر مسح النص
            if (_searchController.text.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.grey,
                  ),
                  tooltip: 'مسح',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'ابحث عن كتبك المفضلة',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جارٍ البحث...'),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'لم يتم العثور على نتائج',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final book = _searchResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Card(
            child: ListTile(
              leading: Container(
                width: 50,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.book,
                  color: Colors.white,
                ),
              ),
              title: Text(book.title),
              subtitle: Text('بقلم: ${book.author}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _navigateToBookDetails(book),
            ),
          ),
        );
      },
    );
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    // محاكاة البحث مع تأخير
    Future.delayed(const Duration(milliseconds: 500), () {
      final bookService = Provider.of<BookService>(context, listen: false);
      final allBooks = bookService.books;
      
      List<BookModel> results = allBooks.where((book) {
        return book.title.toLowerCase().contains(query.toLowerCase()) ||
               book.author.toLowerCase().contains(query.toLowerCase()) ||
               book.description.toLowerCase().contains(query.toLowerCase());
      }).toList();
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
          _recentSearches = _recentSearches.take(10).toList();
        }
      });
    }
    _searchFocus.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    _performSearch('');
    _searchFocus.unfocus();
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
