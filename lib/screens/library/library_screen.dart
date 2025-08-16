import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/book_service.dart';
import '../../services/auth_firebase_service.dart';
import '../../widgets/book_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مكتبتي'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'محفوظ'), Tab(text: 'أقرأ'), Tab(text: 'مكتمل')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSavedTab(),
          _buildReadingTab(),
          _buildCompletedTab(),
        ],
      ),
    );
  }

  Widget _buildSavedTab() {
    return Consumer<BookService>(builder: (context, service, _) {
      final books = service.getSavedBooks();
      if (books.isEmpty) return const Center(child: Text('لا توجد كتب محفوظة'));
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .7, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: books.length,
        itemBuilder: (context, i) => BookCard(book: books[i]),
      );
    });
  }

  Widget _buildReadingTab() {
    return Consumer2<BookService, AuthFirebaseService>(builder: (context, service, auth, _) {
      final uid = auth.currentUser?.uid;
      if (uid == null) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('سجّل الدخول لعرض كتبك قيد القراءة'), const SizedBox(height: 12), ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سجّل الدخول'))), child: const Text('سجّل الدخول'))]));
      final books = service.getReadingBooks(uid);
      if (books.isEmpty) return const Center(child: Text('لا توجد كتب قيد القراءة'));
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .7, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: books.length,
        itemBuilder: (context, i) => BookCard(book: books[i]),
      );
    });
  }

  Widget _buildCompletedTab() {
    return Consumer2<BookService, AuthFirebaseService>(builder: (context, service, auth, _) {
      final uid = auth.currentUser?.uid;
      if (uid == null) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('سجّل الدخول لعرض الكتب المكتملة'), const SizedBox(height: 12), ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سجّل الدخول'))), child: const Text('سجّل الدخول'))]));
      final books = service.getCompletedBooks(uid);
      if (books.isEmpty) return const Center(child: Text('لا توجد كتب مكتملة'));
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .7, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: books.length,
        itemBuilder: (context, i) => BookCard(book: books[i]),
      );
    });
  }
}
