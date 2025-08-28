import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/book_service.dart';
import '../../utils/category_utils.dart';
import '../../widgets/mobile_book_card.dart';
import '../../models/book_model.dart';
import '../book/book_details_screen.dart';
import '../../services/auth_firebase_service.dart';

/// صفحة تصفية حسب الفئة مع شريط فئات علوي للتبديل السريع
class CategoryExploreScreen extends StatefulWidget {
  final String initialCategory;
  const CategoryExploreScreen({super.key, required this.initialCategory});

  @override
  State<CategoryExploreScreen> createState() => _CategoryExploreScreenState();
}

class _CategoryExploreScreenState extends State<CategoryExploreScreen> {
  late String _selected;
  bool _loading = false;
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCategory;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _controller.addListener(_onScroll);
  }

  Future<void> _load({bool first = true}) async {
    final svc = context.read<BookService>();
    setState(() => _loading = true);
    if (first) {
      await svc.loadFirstBooksPage(category: _selected, orderBy: 'createdAt', descending: true, limit: 20);
    } else {
      await svc.loadNextBooksPage(category: _selected, orderBy: 'createdAt', descending: true, limit: 20);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _onScroll() {
    final svc = context.read<BookService>();
    if (!svc.hasMorePaged(category: _selected, orderBy: 'createdAt', descending: true)) return;
    if (_controller.position.pixels >= _controller.position.maxScrollExtent - 300) {
      _load(first: false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openDetails(BuildContext context, BookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailsScreen(book: book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<BookService>();
    final items = svc.getPagedBooks(category: _selected, orderBy: 'createdAt', descending: true);
    final hasMore = svc.hasMorePaged(category: _selected, orderBy: 'createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: Text(_selected)),
      body: Column(
        children: [
          SizedBox(
            height: 84,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              scrollDirection: Axis.horizontal,
              itemCount: BookService.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = BookService.categories[i];
                return _CategoryIconChip(
                  color: getCategoryAccent(c),
                  icon: getCategoryIcon(c),
                  label: c,
                  selected: c == _selected,
                  onTap: () async {
                    if (_selected == c) return;
                    setState(() => _selected = c);
                    await svc.refreshBooksPage(category: _selected, orderBy: 'createdAt', descending: true, limit: 20);
                  },
                );
              },
            ),
          ),
          Expanded(
            child: _loading && items.isEmpty
                ? _skeletonGrid()
                : (items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.menu_book, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('لا توجد كتب في هذه الفئة بعد'),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await svc.refreshBooksPage(category: _selected, orderBy: 'createdAt', descending: true, limit: 20);
                        },
                        child: GridView.builder(
                          controller: _controller,
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: items.length + (hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= items.length) {
                              return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                            }
                            final book = items[index];
                            final isSaved = context.read<BookService>().isBookSaved(book.id);
                            final auth = context.read<AuthFirebaseService>();
                            final uid = auth.currentUser?.uid;
                            return MobileBookCard(
                              book: book,
                              isBookmarked: isSaved,
                              onTap: () => _openDetails(context, book),
                              onBookmark: () async {
                                final now = await svc.toggleSavedBook(book.id, userId: uid);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(now ? 'تم الحفظ' : 'تم الإلغاء')));
                              },
                            );
                          },
                        ),
                      )),
          ),
        ],
      ),
    );
  }

  Widget _skeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _CategoryIconChip extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  const _CategoryIconChip({required this.color, required this.icon, required this.label, required this.onTap, this.selected = false});

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
              color: selected ? color.withOpacity(.25) : color.withOpacity(.12),
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
