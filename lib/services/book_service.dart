import 'package:flutter/foundation.dart';
import '../models/book_model.dart';
import '../models/reading_progress_model.dart';
import 'book_repository.dart';

class BookService extends ChangeNotifier {
  final List<BookModel> _books = [];
  final List<ReadingProgressModel> _readingProgress = [];
  final List<String> _savedBooks = [];
  final BookRepository? _repository; // مستودع Firestore اختياري
  
  bool _isLoading = false;
  String? _error;

  // Getters
  List<BookModel> get books => List.unmodifiable(_books);
  List<BookModel> get featuredBooks => _books.take(6).toList();
  List<BookModel> get recentBooks => _books.take(10).toList();
  List<ReadingProgressModel> get readingProgress => List.unmodifiable(_readingProgress);
  List<String> get savedBooks => List.unmodifiable(_savedBooks);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // فئات الكتب
  static const List<String> categories = [
    'الكل',
    'الأدب',
    'العلوم',
    'التاريخ',
    'الفلسفة',
    'التكنولوجيا',
    'الدين',
    'الطبخ',
    'الرياضة',
    'السيرة الذاتية',
    'الخيال العلمي',
    'الرومانسية',
  ];

  BookService({BookRepository? repository}) : _repository = repository {
    _initializeSampleData();
    _loadFromRemote();
  }

  Future<void> _loadFromRemote() async {
    if (_repository == null) return;
    try {
      _setLoading(true);
    final remote = await _repository.fetchBooks();
      if (remote.isNotEmpty) {
        _books
          ..clear()
          ..addAll(remote);
      }
    } catch (e) {
      _setError('فشل في جلب البيانات السحابية');
    } finally {
      _setLoading(false);
    }
  }

  // تهيئة بيانات تجريبية
  void _initializeSampleData() {
    _books.addAll([
      BookModel(
        id: '1',
        title: 'مئة عام من العزلة',
        author: 'غابرييل غارسيا ماركيز',
        description: 'رواية خيالية من أعمال الأدب العالمي تحكي قصة عائلة بوينديا عبر سبعة أجيال في قرية ماكوندو الخيالية.',
        category: 'الأدب',
        coverImageUrl: 'assets/books/100_years.jpg',
        fileUrl: 'assets/books/100_years.pdf',
        fileType: 'pdf',
        averageRating: 4.5,
        totalReviews: 1200,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        tags: ['أدب عالمي', 'رواية', 'خيال'],
        pageCount: 432,
        language: 'ar',
        uploadedBy: 'admin',
        downloadCount: 5600,
      ),
      BookModel(
        id: '2',
        title: 'تاريخ موجز للزمن',
        author: 'ستيفن هوكينغ',
        description: 'كتاب علمي يشرح أسس الفيزياء النظرية والكونيات بطريقة مبسطة للقارئ العادي.',
        category: 'العلوم',
        coverImageUrl: 'assets/books/brief_history.jpg',
        fileUrl: 'assets/books/brief_history.pdf',
        fileType: 'pdf',
        averageRating: 4.8,
        totalReviews: 956,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        tags: ['فيزياء', 'كونيات', 'علم'],
        pageCount: 256,
        language: 'ar',
        uploadedBy: 'admin',
        downloadCount: 3400,
      ),
      BookModel(
        id: '3',
        title: 'فن الحرب',
        author: 'سون تزو',
        description: 'كتاب استراتيجي عسكري صيني قديم يحتوي على حكم وأساليب في الحرب والاستراتيجية.',
        category: 'الفلسفة',
        coverImageUrl: 'assets/books/art_of_war.jpg',
        fileUrl: 'assets/books/art_of_war.pdf',
        fileType: 'pdf',
        averageRating: 4.3,
        totalReviews: 2100,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        tags: ['استراتيجية', 'فلسفة', 'تاريخ'],
        pageCount: 128,
        language: 'ar',
        uploadedBy: 'admin',
        downloadCount: 8900,
      ),
      BookModel(
        id: '4',
        title: 'البرمجة بلغة Flutter',
        author: 'محمد أحمد',
        description: 'دليل شامل لتعلم تطوير التطبيقات باستخدام Flutter من الصفر حتى الاحتراف.',
        category: 'التكنولوجيا',
        coverImageUrl: 'assets/books/flutter_programming.jpg',
        fileUrl: 'assets/books/flutter_programming.pdf',
        fileType: 'pdf',
        averageRating: 4.6,
        totalReviews: 743,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        tags: ['برمجة', 'فلتر', 'تطوير تطبيقات'],
        pageCount: 412,
        language: 'ar',
        uploadedBy: 'admin',
        downloadCount: 1200,
      ),
      BookModel(
        id: '5',
        title: 'رحلة ابن بطوطة',
        author: 'ابن بطوطة',
        description: 'كتاب رحلات يصف فيه ابن بطوطة رحلاته عبر العالم الإسلامي في القرن الرابع عشر.',
        category: 'التاريخ',
        coverImageUrl: 'assets/books/ibn_battuta.jpg',
        fileUrl: 'assets/books/ibn_battuta.pdf',
        fileType: 'pdf',
        averageRating: 4.4,
        totalReviews: 1500,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        tags: ['رحلات', 'تاريخ إسلامي', 'جغرافيا'],
        pageCount: 584,
        language: 'ar',
        uploadedBy: 'admin',
        downloadCount: 2800,
      ),
      // كتاب تجريبي لملف PDF داخل assets
      BookModel(
        id: 'sample',
        title: 'كتاب تجريبي PDF',
        author: 'فريق التطوير',
        description: 'هذا كتاب تجريبي لعرض آلية فتح ملفات PDF المخزنة ضمن مجلد assets.',
        category: 'التكنولوجيا',
        coverImageUrl: 'assets/images/sample_cover.png', // ضع صورة لاحقاً بنفس الاسم
        fileUrl: 'assets/books/sample.pdf',
        fileType: 'pdf',
        averageRating: 0.0,
        totalReviews: 0,
        createdAt: DateTime.now(),
        tags: ['تجريبي', 'PDF', 'اختبار'],
  pageCount: 25,
        language: 'ar',
        uploadedBy: 'admin',
        downloadCount: 0,
      ),
    ]);

    // بيانات تقدم القراءة التجريبية
    _readingProgress.addAll([
      ReadingProgressModel(
        id: '1',
        userId: 'user1',
        bookId: '1',
        currentPage: 280,
        totalPages: 432,
        lastReadAt: DateTime.now().subtract(const Duration(hours: 2)),
        readingTime: const Duration(hours: 12, minutes: 30),
      ),
      ReadingProgressModel(
        id: '2',
        userId: 'user1',
        bookId: '2',
        currentPage: 82,
        totalPages: 256,
        lastReadAt: DateTime.now().subtract(const Duration(days: 1)),
        readingTime: const Duration(hours: 4, minutes: 15),
      ),
    ]);

    // كتب محفوظة تجريبية
    _savedBooks.addAll(['3', '4', '5']);
  }

  // البحث في الكتب
  List<BookModel> searchBooks(String query, {String? category}) {
    if (query.isEmpty && (category == null || category == 'الكل')) {
      return books;
    }

    return books.where((book) {
      final matchesQuery = query.isEmpty || 
          book.title.toLowerCase().contains(query.toLowerCase()) ||
          book.author.toLowerCase().contains(query.toLowerCase()) ||
          book.description.toLowerCase().contains(query.toLowerCase());
      
      final matchesCategory = category == null || 
          category == 'الكل' || 
          book.category == category;

      return matchesQuery && matchesCategory;
    }).toList();
  }

  // الحصول على كتاب بالمعرف
  BookModel? getBookById(String id) {
    try {
      return books.firstWhere((book) => book.id == id);
    } catch (e) {
      return null;
    }
  }

  // الحصول على الكتب حسب الفئة
  List<BookModel> getBooksByCategory(String category) {
    if (category == 'الكل') return books;
    return books.where((book) => book.category == category).toList();
  }

  // الحصول على الكتب الأكثر تقييماً
  List<BookModel> getTopRatedBooks({int limit = 10}) {
    final sorted = List<BookModel>.from(books);
    sorted.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return sorted.take(limit).toList();
  }

  // الحصول على الكتب الأكثر تحميلاً
  List<BookModel> getMostDownloadedBooks({int limit = 10}) {
    final sorted = List<BookModel>.from(books);
    sorted.sort((a, b) => b.downloadCount.compareTo(a.downloadCount));
    return sorted.take(limit).toList();
  }

  // حفظ كتاب
  Future<void> saveBook(String bookId) async {
    if (!_savedBooks.contains(bookId)) {
      _savedBooks.add(bookId);
      notifyListeners();
    }
  }

  // إلغاء حفظ كتاب
  Future<void> unsaveBook(String bookId) async {
    _savedBooks.remove(bookId);
    notifyListeners();
  }

  // التحقق من حفظ الكتاب
  bool isBookSaved(String bookId) {
    return _savedBooks.contains(bookId);
  }

  // الحصول على الكتب المحفوظة
  List<BookModel> getSavedBooks() {
    return books.where((book) => _savedBooks.contains(book.id)).toList();
  }

  // الحصول على تقدم القراءة لكتاب معين
  ReadingProgressModel? getReadingProgress(String bookId, String userId) {
    try {
      return _readingProgress.firstWhere(
        (progress) => progress.bookId == bookId && progress.userId == userId,
      );
    } catch (e) {
      return null;
    }
  }

  // مزامنة التقدم من السحابة (Firestore) وإدخاله محلياً
  Future<ReadingProgressModel?> syncReadingProgressFromRemote(String bookId, String userId) async {
    if (_repository == null) return getReadingProgress(bookId, userId);
    try {
  final remote = await _repository.getProgress(userId, bookId);
      if (remote != null) {
        final existingIndex = _readingProgress.indexWhere((p) => p.bookId == bookId && p.userId == userId);
        if (existingIndex != -1) {
          _readingProgress[existingIndex] = remote;
        } else {
          _readingProgress.add(remote);
        }
        notifyListeners();
      }
      return remote;
    } catch (_) {
      return getReadingProgress(bookId, userId);
    }
  }

  // Advanced server-side search wrapper
  Future<List<BookModel>> fetchBooksAdvanced({
    String? category,
    String? author,
    double? minRating,
    String? sortBy,
    int? limit,
  }) async {
    if (_repository == null) return [];
    return await _repository.fetchBooksAdvanced(
      category: category,
      author: author,
      minRating: minRating,
      sortBy: sortBy,
      limit: limit,
    );
  }

  // User library methods
  Future<void> addToLibrary(String userId, String bookId, String status) async {
    if (_repository == null) return;
    await _repository.addToUserLibrary(userId, bookId, status);
    notifyListeners();
  }

  Future<void> removeFromLibrary(String userId, String bookId) async {
    if (_repository == null) return;
    await _repository.removeFromUserLibrary(userId, bookId);
    notifyListeners();
  }

  Future<List<String>> getLibraryByStatus(String userId, String status) async {
    if (_repository == null) return [];
    return await _repository.getUserLibraryByStatus(userId, status);
  }

  // تحديث تقدم القراءة
  Future<void> updateReadingProgress({
    required String bookId,
    required String userId,
    required int currentPage,
    required int totalPages,
    Duration? additionalReadingTime,
  Map<String, dynamic>? bookmarks,
  Map<String, dynamic>? highlights,
  }) async {
    final existingIndex = _readingProgress.indexWhere(
      (progress) => progress.bookId == bookId && progress.userId == userId,
    );

    final newReadingTime = additionalReadingTime ?? Duration.zero;
    
    if (existingIndex != -1) {
      // تحديث التقدم الموجود
      final existing = _readingProgress[existingIndex];
      _readingProgress[existingIndex] = existing.copyWith(
        currentPage: currentPage,
        totalPages: totalPages,
        lastReadAt: DateTime.now(),
        readingTime: existing.readingTime + newReadingTime,
        isCompleted: currentPage >= totalPages,
        bookmarks: bookmarks ?? existing.bookmarks,
        highlights: highlights ?? existing.highlights,
      );
    } else {
      // إنشاء تقدم جديد
      _readingProgress.add(
        ReadingProgressModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          bookId: bookId,
          currentPage: currentPage,
          totalPages: totalPages,
          lastReadAt: DateTime.now(),
          readingTime: newReadingTime,
          isCompleted: currentPage >= totalPages,
          bookmarks: bookmarks ?? const {},
          highlights: highlights ?? const {},
        ),
      );
    }

    notifyListeners();

    // تحديث سحابي إن توفر مستودع
    try {
      await _repository?.updateProgressData(
        userId: userId,
        bookId: bookId,
        currentPage: currentPage,
        totalPages: totalPages,
        additionalReadingTime: additionalReadingTime,
        bookmarks: bookmarks,
        highlights: highlights,
      );
    } catch (_) {}
  }

  // ===== إدارة العلامات المرجعية =====
  Future<void> addBookmark({
    required String bookId,
    required String userId,
    required int page,
    String? note,
  }) async {
    final progress = getReadingProgress(bookId, userId);
    final updatedBookmarks = Map<String, dynamic>.from(progress?.bookmarks ?? {});
    updatedBookmarks[page.toString()] = note ?? '';
    await updateReadingProgress(
      bookId: bookId,
      userId: userId,
      currentPage: progress?.currentPage ?? page,
      totalPages: progress?.totalPages ?? 0,
      bookmarks: updatedBookmarks,
      highlights: progress?.highlights,
    );
  }

  Future<void> removeBookmark({
    required String bookId,
    required String userId,
    required int page,
  }) async {
    final progress = getReadingProgress(bookId, userId);
    if (progress == null) return;
    final updatedBookmarks = Map<String, dynamic>.from(progress.bookmarks);
    updatedBookmarks.remove(page.toString());
    await updateReadingProgress(
      bookId: bookId,
      userId: userId,
      currentPage: progress.currentPage,
      totalPages: progress.totalPages,
      bookmarks: updatedBookmarks,
      highlights: progress.highlights,
    );
  }

  // ===== إدارة الإبرازات البسيطة (تخزين النص) =====
  Future<void> addHighlight({
    required String bookId,
    required String userId,
    required int page,
    required String text,
  }) async {
    final progress = getReadingProgress(bookId, userId);
    final updatedHighlights = Map<String, dynamic>.from(progress?.highlights ?? {});
    final pageKey = page.toString();
    final List list = List.from(updatedHighlights[pageKey] ?? []);
    list.add(text);
    updatedHighlights[pageKey] = list;
    await updateReadingProgress(
      bookId: bookId,
      userId: userId,
      currentPage: progress?.currentPage ?? page,
      totalPages: progress?.totalPages ?? 0,
      bookmarks: progress?.bookmarks,
      highlights: updatedHighlights,
    );
  }

  Future<void> removeHighlight({
    required String bookId,
    required String userId,
    required int page,
    required int index,
  }) async {
    final progress = getReadingProgress(bookId, userId);
    if (progress == null) return;
    final updatedHighlights = Map<String, dynamic>.from(progress.highlights);
    final pageKey = page.toString();
    final List list = List.from(updatedHighlights[pageKey] ?? []);
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      updatedHighlights[pageKey] = list;
      await updateReadingProgress(
        bookId: bookId,
        userId: userId,
        currentPage: progress.currentPage,
        totalPages: progress.totalPages,
        bookmarks: progress.bookmarks,
        highlights: updatedHighlights,
      );
    }
  }

  // الحصول على الكتب قيد القراءة
  List<BookModel> getReadingBooks(String userId) {
    final readingBookIds = _readingProgress
        .where((progress) => progress.userId == userId && !progress.isCompleted)
        .map((progress) => progress.bookId)
        .toList();

    return books.where((book) => readingBookIds.contains(book.id)).toList();
  }

  // الحصول على الكتب المكتملة
  List<BookModel> getCompletedBooks(String userId) {
    final completedBookIds = _readingProgress
        .where((progress) => progress.userId == userId && progress.isCompleted)
        .map((progress) => progress.bookId)
        .toList();

    return books.where((book) => completedBookIds.contains(book.id)).toList();
  }

  // إضافة كتاب جديد
  Future<void> addBook(BookModel book) async {
    _setLoading(true);
    try {
      _books.add(book);
      notifyListeners();
    } catch (e) {
      _setError('فشل في إضافة الكتاب: $e');
    } finally {
      _setLoading(false);
    }
  }

  // حذف كتاب
  Future<void> deleteBook(String bookId) async {
    _setLoading(true);
    try {
      _books.removeWhere((book) => book.id == bookId);
      _readingProgress.removeWhere((progress) => progress.bookId == bookId);
      _savedBooks.remove(bookId);
      notifyListeners();
    } catch (e) {
      _setError('فشل في حذف الكتاب: $e');
    } finally {
      _setLoading(false);
    }
  }

  // تحديث عدد التحميلات
  Future<void> incrementDownloadCount(String bookId) async {
    final bookIndex = _books.indexWhere((book) => book.id == bookId);
    if (bookIndex != -1) {
      _books[bookIndex] = _books[bookIndex].copyWith(
        downloadCount: _books[bookIndex].downloadCount + 1,
      );
      notifyListeners();
  try { await _repository?.incrementDownload(bookId); } catch (_) {}
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
