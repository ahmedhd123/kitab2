import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/book_service.dart';
import '../../widgets/mobile_book_card.dart';
import '../../models/book_model.dart';
import '../book/book_details_screen.dart';

class PopularBooksScreen extends StatelessWidget {
  const PopularBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookService = Provider.of<BookService>(context);
    final books = bookService.getMostDownloadedBooks(limit: 100);

    return Scaffold(
      appBar: AppBar(title: const Text('الأكثر رواجاً')),
      body: books.isEmpty
          ? const Center(child: Text('لا توجد كتب رائجة حالياً'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return MobileBookCard(
                  book: book,
                  onTap: () => _openDetails(context, book),
                );
              },
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
