import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/book_service.dart';
import '../../services/auth_firebase_service.dart';
import '../../widgets/book_card.dart';
import '../../widgets/mobile_book_card.dart';
import '../../models/book_model.dart';
import '../../utils/enhanced_design_tokens.dart';
import '../book/book_details_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with TickerProviderStateMixin {
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
      backgroundColor: EnhancedAppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerScrolled) => [
          _buildEnhancedAppBar(),
          _buildSearchAndFiltersSection(),
        ],
            pinned: true,
            floating: true,
            snap: true,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: _HeaderStats(
                onJumpToSaved: () => _tabController.animateTo(0),
                onJumpToReading: () => _tabController.animateTo(1),
                onJumpToCompleted: () => _tabController.animateTo(2),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(112),
              child: SizedBox(
                height: 112,
                child: Column(
                children: [
                  _SearchAndActions(
                    query: _query,
                    onQueryChanged: (v) => setState(() => _query = v),
                    isGrid: _grid,
                    onToggleLayout: () => setState(() => _grid = !_grid),
                    onSortSelected: (value) => setState(() => _sort = value),
                    currentSort: _sort,
                    options: sortOptions,
                  ),
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'محفوظ'),
                      Tab(text: 'أقرأ'),
                      Tab(text: 'مكتمل'),
                    ],
                  ),
                ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _CategoryChips(
              selected: _category,
              onSelected: (c) => setState(() => _category = c),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _LibraryTab(
              providerBuilder: (ctx) => Provider.of<BookService>(ctx),
              booksGetter: (svc, uid) => svc.getSavedBooks(),
              empty: _EmptyState(
                title: 'لا توجد كتب محفوظة',
                subtitle: 'احفظ كتبك المفضّلة للوصول السريع إليها لاحقاً',
                actionLabel: 'ابحث عن كتاب',
                onAction: () => _jumpToSearch(context),
              ),
              query: _query,
              category: _category,
              sort: _sort,
              grid: _grid,
            ),
            _LibraryTab(
              providerBuilder: (ctx) => Provider.of<BookService>(ctx),
              booksGetter: (svc, uid) => uid == null ? [] : svc.getReadingBooks(uid),
              guardLoginMessage: 'سجّل الدخول لعرض كتبك قيد القراءة',
              query: _query,
              category: _category,
              sort: _sort,
              grid: _grid,
            ),
            _LibraryTab(
              providerBuilder: (ctx) => Provider.of<BookService>(ctx),
              booksGetter: (svc, uid) => uid == null ? [] : svc.getCompletedBooks(uid),
              guardLoginMessage: 'سجّل الدخول لعرض الكتب المكتملة',
              query: _query,
              category: _category,
              sort: _sort,
              grid: _grid,
            ),
          ],
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }

  void _jumpToSearch(BuildContext context) {
    Navigator.of(context).pushNamed('/home');
  }
}

class _SortOption {
  final String value;
  final String label;
  const _SortOption(this.value, this.label);
}

List<_SortOption> _sortOptionsForTab(int tabIndex) {
  switch (tabIndex) {
    case 1: // أقرأ
      return const [
        _SortOption('last_read', 'آخر قراءة'),
        _SortOption('title', 'العنوان'),
        _SortOption('rating', 'الأعلى تقييماً'),
      ];
    case 2: // مكتمل
      return const [
        _SortOption('rating', 'الأعلى تقييماً'),
        _SortOption('title', 'العنوان'),
        _SortOption('downloads', 'الأكثر تحميلاً'),
      ];
    case 0: // محفوظ
    default:
      return const [
        _SortOption('rating', 'الأعلى تقييماً'),
        _SortOption('title', 'العنوان'),
        _SortOption('downloads', 'الأكثر تحميلاً'),
      ];
  }
}

class _HeaderStats extends StatelessWidget {
  final VoidCallback onJumpToSaved;
  final VoidCallback onJumpToReading;
  final VoidCallback onJumpToCompleted;
  const _HeaderStats({
    required this.onJumpToSaved,
    required this.onJumpToReading,
    required this.onJumpToCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.12),
            theme.colorScheme.secondary.withValues(alpha: 0.08),
          ],
        ),
      ),
      padding: const EdgeInsets.only(top: 72, left: 16, right: 16, bottom: 16),
      child: Consumer2<BookService, AuthFirebaseService>(
        builder: (context, svc, auth, _) {
          final uid = auth.currentUser?.uid;
          final saved = svc.getSavedBooks().length;
          final reading = uid == null ? 0 : svc.getReadingBooks(uid).length;
          final completed = uid == null ? 0 : svc.getCompletedBooks(uid).length;
          return Row(
            children: [
              _StatCard(label: 'محفوظ', value: saved.toString(), onTap: onJumpToSaved, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              _StatCard(label: 'أقرأ', value: reading.toString(), onTap: onJumpToReading, color: theme.colorScheme.tertiary),
              const SizedBox(width: 8),
              _StatCard(label: 'مكتمل', value: completed.toString(), onTap: onJumpToCompleted, color: theme.colorScheme.secondary),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;
  const _StatCard({required this.label, required this.value, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ]),
              CircleAvatar(radius: 16, backgroundColor: color.withValues(alpha: 0.15), child: Icon(Icons.auto_stories, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchAndActions extends StatelessWidget {
  final String query;
  final ValueChanged<String> onQueryChanged;
  final bool isGrid;
  final VoidCallback onToggleLayout;
  final void Function(String value) onSortSelected;
  final String currentSort;
  final List<_SortOption> options;
  const _SearchAndActions({
    required this.query,
    required this.onQueryChanged,
    required this.isGrid,
    required this.onToggleLayout,
    required this.onSortSelected,
    required this.currentSort,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onQueryChanged,
              decoration: InputDecoration(
                hintText: 'ابحث داخل مكتبتي...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: isGrid ? 'عرض قائمة' : 'عرض شبكة',
            onPressed: onToggleLayout,
            icon: Icon(isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: 'ترتيب',
            onSelected: onSortSelected,
            initialValue: currentSort,
      itemBuilder: (context) => options
        .map((o) => PopupMenuItem(value: o.value, child: Text(o.label)))
        .toList(),
            icon: const Icon(Icons.sort_rounded),
          )
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  const _CategoryChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
  final categories = BookService.categories;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = categories[i];
          final selectedNow = c == selected;
          return ChoiceChip(
            label: Text(c),
            selected: selectedNow,
            onSelected: (_) => onSelected(c),
          );
        },
      ),
    );
  }
}

class _LibraryTab extends StatelessWidget {
  final BookService Function(BuildContext ctx) providerBuilder;
  final List Function(BookService, String? uid) booksGetter;
  final String? guardLoginMessage;
  final _EmptyState? empty;
  final String query;
  final String category;
  final String sort;
  final bool grid;

  const _LibraryTab({
    required this.providerBuilder,
    required this.booksGetter,
    this.guardLoginMessage,
    this.empty,
    required this.query,
    required this.category,
    required this.sort,
    required this.grid,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<BookService, AuthFirebaseService>(
      builder: (context, svc, auth, _) {
        final uid = auth.currentUser?.uid;
        if (guardLoginMessage != null && uid == null) {
          return _LoginGuard(message: guardLoginMessage!);
        }
        var books = List.of(booksGetter(svc, uid));
        // filter by search and category
        if (query.isNotEmpty) {
          final q = query.toLowerCase();
          books = books.where((b) => b.title.toLowerCase().contains(q) || b.author.toLowerCase().contains(q) || b.description.toLowerCase().contains(q)).toList();
        }
        if (category != 'الكل') {
          books = books.where((b) => b.category == category).toList();
        }
        // sort
        switch (sort) {
          case 'title':
            books.sort((a, b) => a.title.compareTo(b.title));
            break;
          case 'last_read':
            if (uid != null) {
              books.sort((a, b) {
                final pa = svc.getReadingProgress(a.id, uid);
                final pb = svc.getReadingProgress(b.id, uid);
                final ta = pa?.lastReadAt;
                final tb = pb?.lastReadAt;
                if (ta == null && tb == null) return 0;
                if (ta == null) return 1; // nulls last
                if (tb == null) return -1;
                return tb.compareTo(ta); // desc
              });
              break;
            }
            // fallback to title if no uid
            books.sort((a, b) => a.title.compareTo(b.title));
            break;
          case 'downloads':
            books.sort((a, b) => b.downloadCount.compareTo(a.downloadCount));
            break;
          case 'rating':
          default:
            books.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        }

        if (books.isEmpty) {
          return empty ?? const _EmptyState(title: 'لا توجد عناصر', subtitle: 'أضف بعض الكتب أولاً');
        }

        final padding = const EdgeInsets.all(8);
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: grid
              ? GridView.builder(
                  key: const ValueKey('grid'),
                  padding: padding,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: .75,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, i) => MobileBookCard(book: books[i]),
                )
              : ListView.builder(
                  key: const ValueKey('list'),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: books.length,
                  itemBuilder: (context, i) {
                    final b = books[i];
                    return MobileBookListTile(book: b);
                  },
                ),
        );
      },
    );
  }
}

class _ListTileBook extends StatelessWidget {
  final BookModel book;
  const _ListTileBook({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BookDetailsScreen(book: book)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 3/4,
                child: Image.network(book.coverImageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: theme.colorScheme.surfaceContainerHighest)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.star_rounded, size: 18, color: Colors.amber.withValues(alpha: 0.9)),
                    const SizedBox(width: 4),
                    Text(book.averageRating.toStringAsFixed(1), style: theme.textTheme.labelMedium),
                    const SizedBox(width: 12),
                    const Icon(Icons.download_rounded, size: 16),
                    const SizedBox(width: 4),
                    Text(book.downloadCount.toString(), style: theme.textTheme.labelMedium),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _EmptyState({required this.title, this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_rounded, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(onPressed: onAction, icon: const Icon(Icons.search_rounded), label: Text(actionLabel!)),
            ]
          ],
        ),
      ),
    );
  }
}

class _LoginGuard extends StatelessWidget {
  final String message;
  const _LoginGuard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushNamed('/login'),
            child: const Text('سجّل الدخول'),
          )
        ],
      ),
    );
  }
}
