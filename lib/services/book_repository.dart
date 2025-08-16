import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';
import '../models/reading_progress_model.dart';

/// مستودع للتعامل مع Firestore لعناصر الكتب والتقدم
class BookRepository {
  final FirebaseFirestore _db;
  BookRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _booksCol => _db.collection('books');
  CollectionReference<Map<String, dynamic>> get _progressCol => _db.collection('readingProgress');

  Future<List<BookModel>> fetchBooks({int? limit}) async {
    Query<Map<String, dynamic>> q = _booksCol.orderBy('createdAt', descending: true);
    if (limit != null) q = q.limit(limit);
    final snap = await q.get();
    return snap.docs.map((d) => _fromFirestoreBook(d)).toList();
  }

  /// Advanced fetch with optional filters and sorting
  Future<List<BookModel>> fetchBooksAdvanced({
    String? category,
    String? author,
    double? minRating,
    String? sortBy, // 'rating' | 'downloads' | 'recent'
    int? limit,
  }) async {
    Query<Map<String, dynamic>> q = _booksCol;
    if (category != null && category.isNotEmpty && category != 'الكل') {
      q = q.where('category', isEqualTo: category);
    }
    if (author != null && author.isNotEmpty) {
      q = q.where('author', isEqualTo: author);
    }
    if (minRating != null) {
      q = q.where('averageRating', isGreaterThanOrEqualTo: minRating);
    }

    if (sortBy == 'rating') {
      q = q.orderBy('averageRating', descending: true);
    } else if (sortBy == 'downloads') {
      q = q.orderBy('downloadCount', descending: true);
    } else {
      q = q.orderBy('createdAt', descending: true);
    }

    if (limit != null) q = q.limit(limit);

    final snap = await q.get();
    return snap.docs.map((d) => _fromFirestoreBook(d)).toList();
  }

  Future<BookModel?> getBook(String id) async {
    final doc = await _booksCol.doc(id).get();
    if (!doc.exists) return null;
    return _fromFirestoreBook(doc);
  }

  Future<void> addOrUpdateBook(BookModel book) async {
    await _booksCol.doc(book.id).set(book.toMap(), SetOptions(merge: true));
  }

  Future<void> incrementDownload(String bookId) async {
    await _booksCol.doc(bookId).update({'downloadCount': FieldValue.increment(1)});
  }

  Future<ReadingProgressModel?> getProgress(String userId, String bookId) async {
    final q = await _progressCol
        .where('userId', isEqualTo: userId)
        .where('bookId', isEqualTo: bookId)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return _fromFirestoreProgress(q.docs.first);
  }

  /// User library stored under users/{userId}/library with doc id = bookId
  CollectionReference<Map<String, dynamic>> _userLibrary(String userId) =>
      _db.collection('users').doc(userId).collection('library');

  Future<List<String>> getUserLibrary(String userId) async {
    final snap = await _userLibrary(userId).get();
    return snap.docs.map((d) => d.id).toList();
  }

  Future<void> addToUserLibrary(String userId, String bookId, String status) async {
    await _userLibrary(userId).doc(bookId).set({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> removeFromUserLibrary(String userId, String bookId) async {
    await _userLibrary(userId).doc(bookId).delete();
  }

  Future<List<String>> getUserLibraryByStatus(String userId, String status) async {
    final q = await _userLibrary(userId).where('status', isEqualTo: status).get();
    return q.docs.map((d) => d.id).toList();
  }

  Future<void> upsertProgress(ReadingProgressModel progress) async {
    await _progressCol.doc(progress.id).set(progress.toMap(), SetOptions(merge: true));
  }

  Future<void> updateProgressData({
    required String userId,
    required String bookId,
    required int currentPage,
    required int totalPages,
    Duration? additionalReadingTime,
    Map<String, dynamic>? bookmarks,
    Map<String, dynamic>? highlights,
  }) async {
    final existing = await getProgress(userId, bookId);
    final now = DateTime.now();
    if (existing == null) {
      final newP = ReadingProgressModel(
        id: '${userId}_${bookId}',
        userId: userId,
        bookId: bookId,
        currentPage: currentPage,
        totalPages: totalPages,
        lastReadAt: now,
        readingTime: additionalReadingTime ?? Duration.zero,
        isCompleted: currentPage >= totalPages && totalPages > 0,
        bookmarks: bookmarks ?? const {},
        highlights: highlights ?? const {},
      );
      await upsertProgress(newP);
    } else {
      final updated = existing.copyWith(
        currentPage: currentPage,
        totalPages: totalPages,
        lastReadAt: now,
        readingTime: existing.readingTime + (additionalReadingTime ?? Duration.zero),
        isCompleted: currentPage >= totalPages && totalPages > 0,
        bookmarks: bookmarks ?? existing.bookmarks,
        highlights: highlights ?? existing.highlights,
      );
      await upsertProgress(updated);
    }
  }

  BookModel _fromFirestoreBook(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    // التعامل مع Timestamp
    final createdAt = (data['createdAt'] is Timestamp)
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now();
    final updatedAt = (data['updatedAt'] is Timestamp)
        ? (data['updatedAt'] as Timestamp).toDate()
        : (data['updatedAt'] != null
            ? DateTime.tryParse(data['updatedAt'].toString())
            : null);
    return BookModel(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      coverImageUrl: data['coverImageUrl'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      fileType: data['fileType'] ?? 'pdf',
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      downloadCount: data['downloadCount'] ?? 0,
      uploadedBy: data['uploadedBy'] ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      tags: List<String>.from(data['tags'] ?? []),
      pageCount: data['pageCount'] ?? 0,
      language: data['language'] ?? 'ar',
    );
  }

  ReadingProgressModel _fromFirestoreProgress(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final lastReadAt = (data['lastReadAt'] is Timestamp)
        ? (data['lastReadAt'] as Timestamp).toDate()
        : DateTime.tryParse(data['lastReadAt']?.toString() ?? '') ?? DateTime.now();
    return ReadingProgressModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      bookId: data['bookId'] ?? '',
      currentPage: data['currentPage'] ?? 0,
      totalPages: data['totalPages'] ?? 0,
      lastReadAt: lastReadAt,
      readingTime: Duration(seconds: data['readingTimeSeconds'] ?? 0),
      isCompleted: data['isCompleted'] ?? false,
      bookmarks: Map<String, dynamic>.from(data['bookmarks'] ?? {}),
      highlights: Map<String, dynamic>.from(data['highlights'] ?? {}),
    );
  }
}
