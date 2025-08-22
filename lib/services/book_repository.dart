import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:async';
import '../models/book_model.dart';
import '../models/reading_progress_model.dart';
import 'package:flutter/foundation.dart';

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

  /// Uploads a file bytes to Firebase Storage under `books/{bookId}/{fileName}` and
  /// returns a download URL.
  /// Uploads bytes to Storage and reports progress via [onProgress].
  /// Returns the download URL on success. Throws on failure or timeout.
  Future<String> uploadBookFile({
    required String bookId,
    required String fileName,
    required List<int> bytes,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    final storage = FirebaseStorage.instance;
    final ref = storage.ref().child('books').child(bookId).child(fileName);
    final metadata = SettableMetadata(contentType: contentType);
    if (kDebugMode) {
      debugPrint('[uploadBookFile] START bookId=$bookId file=$fileName bytes=${bytes.length} contentType=$contentType fullPath=${ref.fullPath}');
    }
    final uploadTask = ref.putData(Uint8List.fromList(bytes), metadata);

    // Listen to snapshot events and report progress if requested.
    final sub = uploadTask.snapshotEvents.listen((snapshot) {
      try {
        final transferred = snapshot.bytesTransferred;
        final total = snapshot.totalBytes;
        if (total > 0) {
          final p = transferred / total;
          onProgress?.call(p);
        }
        if (kDebugMode) {
          debugPrint('[uploadBookFile] state=${snapshot.state} transferred=$transferred/$total (${total == 0 ? 0 : (transferred/total*100).toStringAsFixed(2)}%)');
        }
      } catch (_) {}
    }, onError: (error, st) {
      if (kDebugMode) debugPrint('[uploadBookFile] snapshot stream error: $error');
    });

    try {
      // Set an upper bound to avoid infinite wait; 10 minutes for large files.
      final snapshot = await uploadTask
          .whenComplete(() {})
          .timeout(const Duration(minutes: 10), onTimeout: () {
        if (kDebugMode) debugPrint('[uploadBookFile] TIMEOUT after 10 minutes');
        throw TimeoutException('Upload timed out');
      });
      final url = await snapshot.ref.getDownloadURL();
      onProgress?.call(1.0);
      if (kDebugMode) debugPrint('[uploadBookFile] SUCCESS url=$url');
      return url;
    } on TimeoutException catch (e) {
      if (kDebugMode) debugPrint('[uploadBookFile] Caught TimeoutException: $e');
      rethrow;
    } on FirebaseException catch (e) {
      if (kDebugMode) debugPrint('[uploadBookFile] FirebaseException code=${e.code} message=${e.message}');
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('[uploadBookFile] ERROR $e');
      rethrow;
    } finally {
      await sub.cancel();
    }
  }

  /// Convenience: upload file bytes then create/update Firestore document for the book.
  Future<String> addBookWithFile({
    required String bookId,
    required BookModel book,
    required String fileName,
    required List<int> bytes,
    required String contentType,
  void Function(double progress)? onProgress,
  }) async {
    final fileUrl = await uploadBookFile(
        bookId: bookId,
        fileName: fileName,
        bytes: bytes,
        contentType: contentType,
        onProgress: onProgress);
    final updated = book.copyWith(fileUrl: fileUrl, uploadedBy: book.uploadedBy);
    try {
      await addOrUpdateBook(updated);
    } catch (e) {
      if (kDebugMode) debugPrint('[addBookWithFile] Firestore write failed but returning fileUrl anyway: $e');
    }
    return fileUrl;
  }

  Future<void> incrementDownload(String bookId) async {
    await _booksCol.doc(bookId).update({'downloadCount': FieldValue.increment(1)});
  }

  /// حذف كتاب من Firestore (لا يحذف الملف من Storage لتبسيط التنفيذ حالياً)
  Future<void> deleteBook(String bookId) async {
    await _booksCol.doc(bookId).delete();
  }

  /// رفع صورة غلاف للكتاب books/{bookId}/cover.jpg وإرجاع الرابط
  Future<String> uploadCoverImage({
    required String bookId,
    required List<int> bytes,
    required String contentType,
  }) async {
    final storage = FirebaseStorage.instance;
    final ref = storage.ref().child('books').child(bookId).child('cover.jpg');
    final metadata = SettableMetadata(contentType: contentType);
    await ref.putData(Uint8List.fromList(bytes), metadata);
    return await ref.getDownloadURL();
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
        id: '${userId}_$bookId',
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
  releaseDate: data['releaseDate'] != null ? DateTime.tryParse(data['releaseDate'].toString()) : null,
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
