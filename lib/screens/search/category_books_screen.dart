import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/book_service.dart';
import '../../widgets/mobile_book_card.dart';
import '../../models/book_model.dart';
import '../book/book_details_screen.dart';

class CategoryBooksScreen extends StatefulWidget {
  final String category;
  const CategoryBooksScreen({super.key, required this.category});

  @override
  State<CategoryBooksScreen> createState() => _CategoryBooksScreenState();
}

class _CategoryBooksScreenState extends State<CategoryBooksScreen> {
  static const int pageSize = 12;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final bookService = Provider.of<BookService>(context);
    final all = widget.category == 'الكل'
        ? bookService.books
        : bookService.getBooksByCategory(widget.category);

    final totalPages = (all.length / pageSize).ceil().clamp(1, 9999);
    final start = (_page * pageSize).clamp(0, all.length);
    final end = ((_page + 1) * pageSize).clamp(0, all.length);
    final pageItems = all.sublist(start, end);

    return Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      body: Column(
        children: [
          Expanded(
            child: pageItems.isEmpty
                ? const Center(child: Text('لا توجد كتب في هذه الفئة'))
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: pageItems.length,
                    itemBuilder: (context, index) {
                      final book = pageItems[index];
                      return MobileBookCard(
                        book: book,
                        onTap: () => _openDetails(context, book),
                      );
                    },
                  ),
          ),
          _buildPaginator(totalPages),
        ],
      ),
    );
  }

  Widget _buildPaginator(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _page > 0 ? () => setState(() => _page--) : null,
            icon: const Icon(Icons.chevron_right),
          ),
          Text('صفحة ${_page + 1} من $totalPages'),
          IconButton(
            onPressed: _page < totalPages - 1 ? () => setState(() => _page++) : null,
            icon: const Icon(Icons.chevron_left),
          ),
        ],
      ),
    );
  }

  void _openDetails(BuildContext context, BookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailsScreen(book: book)),
    );
  }
}
