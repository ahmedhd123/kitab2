import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/book_model.dart';
import '../models/reading_progress_model.dart';
import 'book_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookService extends ChangeNotifier {
  final List<BookModel> _books = [];
  final List<ReadingProgressModel> _readingProgress = [];
  final List<String> _savedBooks = [];
  final BookRepository? _repository; // مستودع Firestore اختياري
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _booksSub; // اشتراك فوري
  // حالة المزامنة لكل (userId, bookId) => 'idle'|'syncing'|'success'|'failed'
  final Map<String, String> _syncStatus = {};
  // آخر تعارض مُكتشف (local, remote) لكل مفتاح userId_bookId
  final Map<String, Map<String, ReadingProgressModel>> _conflicts = {};
  
  bool _isLoading = false;
  String? _error;
  bool _initialRemoteTried = false; // لمنع التكرار غير الضروري

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
    // عند التهيئة: تحميل من السحابة فقط بدون بيانات تجريبية
    if (_repository != null) {
      _loadFromRemote()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        if (kDebugMode) debugPrint('[BookService] remote load timeout (10s)');
        return; // تجاهل
      }).catchError((e) {
        if (kDebugMode) debugPrint('[BookService] remote load error: $e');
      });
  _listenRealtime();
    }
  }

  Future<void> _loadFromRemote() async {
    if (_repository == null) return;
  if (_isLoading) return; // تفادي التوازي
    try {
      _setLoading(true);
      if (kDebugMode) debugPrint('[BookService] fetching remote books...');
      final remote = await _repository.fetchBooks();
      if (remote.isNotEmpty) {
        // دمج: استبدل الكتب التي لها نفس المعرف وأضف الجديدة بدون حذف العينات إن لم تكن موجودة
        int replaced = 0;
        for (final rb in remote) {
          final idx = _books.indexWhere((b) => b.id == rb.id);
            if (idx != -1) {
              _books[idx] = rb; // تحديث
              replaced++;
            } else {
              _books.add(rb); // إضافة جديدة
            }
        }
        if (kDebugMode) debugPrint('[BookService] merged remote books: fetched=${remote.length} replaced=$replaced totalNow=${_books.length}');
      } else if (kDebugMode) {
        debugPrint('[BookService] remote books list empty; keeping local sample');
      }
    } catch (e) {
      _setError('فشل في جلب البيانات السحابية');
      if (kDebugMode) debugPrint('[BookService] fetch error: $e');
    } finally {
      _setLoading(false);
      _initialRemoteTried = true;
    }
  }

  // استدعاء عام لإعادة التحميل (مثلاً بعد تسجيل الدخول)
  Future<void> refreshRemote({bool force = false}) async {
    if (_repository == null) return;
    if (!force && _initialRemoteTried && _books.isNotEmpty) return;
    await _loadFromRemote();
  }

  // الاستماع الفوري لتحديثات الكتب من Firestore
  void _listenRealtime() {
    try {
      _booksSub?.cancel();
      _booksSub = FirebaseFirestore.instance
          .collection('books')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        final remote = snapshot.docs.map((d) {
          try {
            final data = d.data();
            final createdAt = (data['createdAt'] is Timestamp)
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now();
            final updatedAt = (data['updatedAt'] is Timestamp)
                ? (data['updatedAt'] as Timestamp).toDate()
                : (data['updatedAt'] != null
                    ? DateTime.tryParse(data['updatedAt'].toString())
                    : null);
            return BookModel(
              id: d.id,
              title: data['title'] ?? '',
              author: data['author'] ?? '',
                authorBio: data['authorBio'] ?? '',
              description: data['description'] ?? '',
              category: data['category'] ?? '',
              coverImageUrl: data['coverImageUrl'] ?? '',
        bookSummary: data['bookSummary'] ?? '',
              fileUrl: data['fileUrl'] ?? '',
              fileType: data['fileType'] ?? 'pdf',
              averageRating: (data['averageRating'] ?? 0).toDouble(),
              totalReviews: data['totalReviews'] ?? 0,
              downloadCount: data['downloadCount'] ?? 0,
              uploadedBy: data['uploadedBy'] ?? '',
              createdAt: createdAt,
              updatedAt: updatedAt,
        releaseDate: (data['releaseDate'] is Timestamp)
          ? (data['releaseDate'] as Timestamp).toDate()
          : (data['releaseDate'] != null
            ? DateTime.tryParse(data['releaseDate'].toString())
            : null),
              tags: List<String>.from(data['tags'] ?? []),
              pageCount: data['pageCount'] ?? 0,
              language: data['language'] ?? 'ar',
            );
          } catch (e) {
            if (kDebugMode) debugPrint('[BookService] map error $e');
            return null;
          }
        }).whereType<BookModel>().toList();

        // دمج ذكي: استبدال أو إضافة فقط
        int replaced = 0;
        for (final rb in remote) {
          final idx = _books.indexWhere((b) => b.id == rb.id);
          if (idx != -1) {
            _books[idx] = rb;
            replaced++;
          } else {
            _books.add(rb);
          }
        }
        // إزالة الكتب المحلية التي حُذفت من السحابة
        _books.removeWhere((b) => remote.every((r) => r.id != b.id));
        if (kDebugMode) debugPrint('[BookService] realtime books update fetched=${remote.length} replaced=$replaced total=${_books.length}');
        notifyListeners();
      }, onError: (e) {
        if (kDebugMode) debugPrint('[BookService] realtime listen error: $e');
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[BookService] failed to start realtime listener: $e');
    }
  }

  // تمت إزالة البيانات التجريبية: يبدأ التطبيق فارغاً ثم يتم ملؤه من Firestore

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
  if (_savedBooks.isEmpty || _books.isEmpty) return [];
  return _books.where((book) => _savedBooks.contains(book.id)).toList();
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
      final key = '${userId}_$bookId';
      _syncStatus[key] = 'syncing';
      notifyListeners();

      final remote = await _repository.getProgress(userId, bookId);

      // If no remote exists, nothing to merge — return local
      final local = getReadingProgress(bookId, userId);
      if (remote == null) {
        // if local exists, push it to remote
        if (local != null) {
          try {
            await _repository.upsertProgress(local);
            _syncStatus[key] = 'success';
            notifyListeners();
          } catch (_) {
            _syncStatus[key] = 'failed';
            notifyListeners();
          }
        } else {
          _syncStatus[key] = 'success';
          notifyListeners();
        }
        return local;
      }

      // If local is null, adopt remote
      if (local == null) {
        final existingIndex = _readingProgress.indexWhere((p) => p.bookId == bookId && p.userId == userId);
        if (existingIndex != -1) {
          _readingProgress[existingIndex] = remote;
        } else {
          _readingProgress.add(remote);
        }
        _syncStatus[key] = 'success';
        notifyListeners();
        return remote;
      }

      // Both exist: optimistic merge — prefer latest lastReadAt and merge readingTime/bookmarks/highlights
      ReadingProgressModel merged;
      final cmp = local.lastReadAt.compareTo(remote.lastReadAt);
      if (cmp == 0) {
        // identical timestamps: merge fields conservatively
        merged = _mergeProgress(local, remote);
      } else if (cmp > 0) {
        // local is newer
        merged = _mergeProgress(local, remote, prefer: 'local');
      } else {
        // remote is newer
        merged = _mergeProgress(local, remote, prefer: 'remote');
      }

      // If merged differs from remote, upsert it
      final eq = const DeepCollectionEquality().equals(merged.toMap(), remote.toMap());
      if (!eq) {
        try {
          await _repository.upsertProgress(merged);
          _syncStatus[key] = 'success';
        } catch (_) {
          _syncStatus[key] = 'failed';
        }
      } else {
        _syncStatus[key] = 'success';
      }

      // store merged locally
      final existingIndex = _readingProgress.indexWhere((p) => p.bookId == bookId && p.userId == userId);
      if (existingIndex != -1) {
        _readingProgress[existingIndex] = merged;
      } else {
        _readingProgress.add(merged);
      }

      // conflict detection: if both had changes and lastReadAt differ, save conflict for UI
      if (local.lastReadAt != remote.lastReadAt && (DateTime.now().difference(local.lastReadAt).inDays < 30 || DateTime.now().difference(remote.lastReadAt).inDays < 30)) {
        _conflicts[key] = {'local': local, 'remote': remote};
      }

      notifyListeners();
      return merged;
    } catch (_) {
      _syncStatus['${userId}_$bookId'] = 'failed';
      notifyListeners();
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
  double? scrollOffset,
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
        scrollOffset: scrollOffset ?? existing.scrollOffset,
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
          scrollOffset: scrollOffset ?? 0.0,
        ),
      );
    }

    notifyListeners();
    // تحديث سحابي إن توفر مستودع
    try {
      final key = '${userId}_$bookId';
      _syncStatus[key] = 'syncing';
      notifyListeners();
      await _repository?.updateProgressData(
        userId: userId,
        bookId: bookId,
        currentPage: currentPage,
        totalPages: totalPages,
        additionalReadingTime: additionalReadingTime,
        bookmarks: bookmarks,
        highlights: highlights,
      );
      _syncStatus[key] = 'success';
      notifyListeners();
    } catch (_) {
      final key = '${userId}_$bookId';
      _syncStatus[key] = 'failed';
      notifyListeners();
    }
  }


  // Merge helper: combine readingTime and union bookmarks/highlights.
  ReadingProgressModel _mergeProgress(ReadingProgressModel a, ReadingProgressModel b, {String? prefer}) {
    // prefer determines which base to take for scalar fields (currentPage, totalPages, isCompleted, lastReadAt)
    final base = (prefer == 'remote') ? b : a;
    final other = (identical(base, a)) ? b : a;

    // readingTime: sum of both
    final combinedReadingTime = Duration(seconds: a.readingTime.inSeconds + b.readingTime.inSeconds);

    // bookmarks: merge maps, remote entries overwrite local if key collision when prefer==remote
    final mergedBookmarks = Map<String, dynamic>.from(a.bookmarks);
    b.bookmarks.forEach((k, v) {
      mergedBookmarks[k] = v;
    });

    // highlights: merge lists per page
    final mergedHighlights = <String, dynamic>{};
    final pages = <String>{}..addAll(a.highlights.keys)..addAll(b.highlights.keys);
    for (final p in pages) {
      final listA = List<String>.from(a.highlights[p] ?? []);
      final listB = List<String>.from(b.highlights[p] ?? []);
      final mergedList = <String>[...listA, ...listB.where((x) => !listA.contains(x))];
      mergedHighlights[p] = mergedList;
    }

    return base.copyWith(
      currentPage: base.currentPage,
      totalPages: base.totalPages,
      lastReadAt: base.lastReadAt.isAfter(other.lastReadAt) ? base.lastReadAt : other.lastReadAt,
      readingTime: combinedReadingTime,
      isCompleted: base.isCompleted || other.isCompleted,
      bookmarks: mergedBookmarks,
      highlights: mergedHighlights,
  scrollOffset: base.scrollOffset > other.scrollOffset ? base.scrollOffset : other.scrollOffset,
    );
  }

  // Public wrapper for tests or external callers that want to merge two progress entries.
  ReadingProgressModel mergeProgress(ReadingProgressModel a, ReadingProgressModel b, {String? prefer}) {
    return _mergeProgress(a, b, prefer: prefer);
  }

  // Expose sync status for UI
  String getSyncStatus(String bookId, String userId) => _syncStatus['${userId}_$bookId'] ?? 'idle';

  // Expose conflict if exists
  Map<String, ReadingProgressModel>? getConflict(String bookId, String userId) => _conflicts['${userId}_$bookId'];

  void clearConflict(String bookId, String userId) {
    _conflicts.remove('${userId}_$bookId');
    notifyListeners();
  }

  // Background sync worker
  Timer? _bgTimer;
  bool _bgActive = false;

  /// Start periodic background sync for the given [userId].
  /// While active, it will attempt to reconcile each local progress entry every [interval].
  void startBackgroundSync(String userId, {Duration interval = const Duration(seconds: 30)}) {
    stopBackgroundSync();
    _bgActive = true;
    _bgTimer = Timer.periodic(interval, (_) async {
      // iterate through local progress entries for this user
      final entries = _readingProgress.where((p) => p.userId == userId).toList();
      for (final p in entries) {
        try {
          await syncReadingProgressFromRemote(p.bookId, userId);
        } catch (_) {}
      }
    });
    notifyListeners();
  }

  void stopBackgroundSync() {
    _bgTimer?.cancel();
    _bgTimer = null;
    _bgActive = false;
    notifyListeners();
  }

  bool get isBackgroundSyncActive => _bgActive;
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
      // Add locally
      _books.add(book);
      notifyListeners();
      // If repository is present, persist remotely as well
      if (_repository != null) {
        try {
          await _repository.addOrUpdateBook(book);
        } catch (_) {}
      }
    } catch (e) {
      _setError('فشل في إضافة الكتاب: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Upload bytes and add a new book entry (uploads file to Storage and creates Firestore doc).
  Future<String?> uploadAndAddBook({
    required BookModel book,
    required String fileName,
    required List<int> bytes,
    required String contentType,
  void Function(double progress)? onProgress,
  }) async {
    if (_repository == null) {
      // fallback: just add locally and return null
      await addBook(book);
      return null;
    }

    final bookId = book.id;
    try {
      _setLoading(true);
      final fileUrl = await _repository.addBookWithFile(
        bookId: bookId,
        book: book,
        fileName: fileName,
        bytes: bytes,
        contentType: contentType,
        onProgress: onProgress,
      );
      // update local cache
      final idx = _books.indexWhere((b) => b.id == bookId);
      final updated = book.copyWith(fileUrl: fileUrl);
      if (idx != -1) {
        _books[idx] = updated;
      } else {
        _books.add(updated);
      }
      notifyListeners();
      return fileUrl;
    } catch (e) {
      _setError('فشل في رفع الكتاب: $e');
      return null;
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
      try { await _repository?.deleteBook(bookId); } catch (_) {}
    } catch (e) {
      _setError('فشل في حذف الكتاب: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// تحديث كتاب موجود (ويمكن مع تحديث الملف أو صورة الغلاف اختيارياً)
  Future<BookModel?> updateBook(
    BookModel book, {
    List<int>? newFileBytes,
    String? newFileName,
    String? newFileContentType,
    void Function(double progress)? onFileProgress,
    List<int>? coverImageBytes,
    String? coverImageContentType,
  }) async {
    _setLoading(true);
    try {
      BookModel updated = book.copyWith(updatedAt: DateTime.now());

      // رفع ملف الكتاب الجديد إن تم توفيره
      if (newFileBytes != null && newFileName != null && newFileContentType != null && _repository != null) {
        final fileUrl = await _repository.uploadBookFile(
          bookId: book.id,
          fileName: newFileName,
          bytes: newFileBytes,
          contentType: newFileContentType,
          onProgress: onFileProgress,
        );
        updated = updated.copyWith(fileUrl: fileUrl);
      }

      // رفع صورة الغلاف الجديدة إن تم توفيرها
      if (coverImageBytes != null && coverImageContentType != null && _repository != null) {
        final coverUrl = await _repository.uploadCoverImage(
          bookId: book.id,
          bytes: coverImageBytes,
          contentType: coverImageContentType,
        );
        updated = updated.copyWith(coverImageUrl: coverUrl);
      }

      // تحديث في Firestore
      await _repository?.addOrUpdateBook(updated);

      final idx = _books.indexWhere((b) => b.id == updated.id);
      if (idx != -1) {
        _books[idx] = updated;
      } else {
        _books.add(updated);
      }
      notifyListeners();
      return updated;
    } catch (e) {
      _setError('فشل في تحديث الكتاب: $e');
      return null;
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

  @override
  void dispose() {
    _booksSub?.cancel();
    super.dispose();
  }
}
