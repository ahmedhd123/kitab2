import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/design_tokens.dart';
import '../models/book_model.dart';
import '../services/book_service.dart';
import '../screens/book/book_details_screen.dart';

class BookCard extends StatelessWidget {
  final BookModel book;
  final double aspectRatio;
  final VoidCallback? onTap;

  const BookCard({super.key, required this.book, this.aspectRatio = .70, this.onTap});

  Color _categoryColor(String category) => AppColors.categoryColors[category] ?? AppColors.neutral400;

  @override
  Widget build(BuildContext context) {
    return Consumer<BookService>(
      builder: (context, bookService, child) {
        final isSaved = bookService.isBookSaved(book.id);
        final catColor = _categoryColor(book.category);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: Theme.of(context).cardColor,
            border: Border.all(color: AppColors.neutral200.withOpacity(.6), width: 1),
            boxShadow: AppShadows.subtle,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap ?? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookDetailsScreen(book: book),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 58,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          catColor.withOpacity(.80),
                          catColor.withOpacity(.55),
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 52,
                            color: Colors.white.withOpacity(.90),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(.30),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              book.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          left: 4,
                          child: IconButton(
                            icon: Icon(
                              isSaved ? Icons.bookmark : Icons.bookmark_outline,
                              color: isSaved ? AppColors.warning : Colors.white,
                            ),
                            splashRadius: 22,
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
                Expanded(
                  flex: 42,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 3),
                            Text(
                              book.averageRating.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            if (book.releaseDate != null) ...[
                              const SizedBox(width: 10),
                              const Icon(Icons.event, size: 14, color: Colors.grey),
                              const SizedBox(width: 3),
                              Text(
                                _fmtDate(book.releaseDate!),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                            const SizedBox(width: 10),
                            Icon(Icons.download_rounded, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 3),
                            Text('${book.downloadCount}', style: Theme.of(context).textTheme.labelSmall),
                          ],
                        )
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

  String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}
