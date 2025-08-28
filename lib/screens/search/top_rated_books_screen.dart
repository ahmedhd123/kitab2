import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/book_service.dart';
import '../../services/auth_firebase_service.dart';
import '../../widgets/mobile_book_card.dart';
import '../../models/book_model.dart';
import '../book/book_details_screen.dart';

class TopRatedBooksScreen extends StatefulWidget {
  const TopRatedBooksScreen({super.key});

  @override
  State<TopRatedBooksScreen> createState() => _TopRatedBooksScreenState();
}

class _TopRatedBooksScreenState extends State<TopRatedBooksScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadFirst();
    });
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadFirst() async {
    final service = context.read<BookService>();
    await service.loadFirstBooksPage(orderBy: 'averageRating', descending: true, limit: 20);
    if (mounted) setState(() => _initialized = true);
  }

  void _onScroll() {
    final service = context.read<BookService>();
    if (!service.hasMorePaged(orderBy: 'averageRating', descending: true)) return;
    if (service.isLoading) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      service.loadNextBooksPage(orderBy: 'averageRating', descending: true, limit: 20);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final service = context.watch<BookService>();
    final items = service.getPagedBooks(orderBy: 'averageRating', descending: true);
    final hasMore = service.hasMorePaged(orderBy: 'averageRating', descending: true);

    Widget listContent() {
      return RefreshIndicator(
        onRefresh: _loadFirst,
        child: GridView.builder(
          controller: _scrollController,
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
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final book = items[index];
            final isSaved = context.read<BookService>().isBookSaved(book.id);
            return MobileBookCard(
              book: book,
              isBookmarked: isSaved,
              onTap: () => _openDetails(context, book),
              onBookmark: () async {
                final uid = context.read<AuthFirebaseService>().currentUser?.uid;
                await service.toggleSavedBook(book.id, userId: uid);
              },
            );
          },
        ),
      );
    }

    Widget bannerOrEmpty(Widget child) {
      return _bannerOrEmpty(context, l10n, child);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.topRatedTitle)),
      body: !_initialized && service.isLoading
          ? _buildSkeletonGrid()
          : items.isEmpty
              ? bannerOrEmpty(Center(child: Text(l10n.noTopRatedBooks)))
              : bannerOrEmpty(listContent()),
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => _skeletonCard(),
    );
  }

  Widget _skeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 65,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 35,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonLine(width: 120),
                  const SizedBox(height: 8),
                  _skeletonLine(width: 80),
                  const Spacer(),
                  _skeletonLine(width: 60),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _skeletonLine({double width = 100}) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  void _openDetails(BuildContext context, BookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailsScreen(book: book)),
    );
  }

  Widget _bannerOrEmpty(BuildContext context, AppLocalizations l10n, Widget child) {
    final service = context.watch<BookService>();
    return Column(
      children: [
        if (service.hasIndexHint && service.lastMissingIndexUrl != null)
          MaterialBanner(
            content: Text(l10n.indexHintDesc),
            leading: const Icon(Icons.info_outline),
            actions: [
              TextButton(
                onPressed: () async {
                  final link = service.lastMissingIndexUrl!;
                  try { await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication); } catch (_) {}
                },
                child: Text(l10n.openLink),
              ),
              TextButton(
                onPressed: () async {
                  final link = service.lastMissingIndexUrl!;
                  await Clipboard.setData(ClipboardData(text: link));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.linkCopied)),
                  );
                },
                child: Text(l10n.copyLink),
              ),
              TextButton(
                onPressed: () => context.read<BookService>().clearIndexHint(),
                child: Text(l10n.dismiss),
              ),
            ],
            backgroundColor: Colors.amber.shade50,
            elevation: 0,
            dividerColor: Colors.amber.shade200,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        Expanded(child: child),
      ],
    );
  }
}
