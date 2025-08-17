import 'package:flutter_test/flutter_test.dart';
import 'package:kitab2/models/book_model.dart';
import 'package:kitab2/services/book_service.dart';
import 'package:kitab2/models/reading_progress_model.dart';
import 'package:kitab2/services/book_repository.dart';

class FakeRepo implements BookRepository {
  final bool fail;
  ReadingProgressModel? _stored;
  FakeRepo({this.fail = false, ReadingProgressModel? initial}) : _stored = initial;

  @override
  Future<void> upsertProgress(ReadingProgressModel progress) async {
    if (fail) throw Exception('network');
    _stored = progress;
    return;
  }

  @override
  Future<void> updateProgressData({required String userId, required String bookId, required int currentPage, required int totalPages, Duration? additionalReadingTime, Map<String, dynamic>? bookmarks, Map<String, dynamic>? highlights}) async {
    if (fail) throw Exception('network');
    if (_stored == null) {
      _stored = ReadingProgressModel(
        id: '${userId}_$bookId',
        userId: userId,
        bookId: bookId,
        currentPage: currentPage,
        totalPages: totalPages,
        lastReadAt: DateTime.now(),
        readingTime: additionalReadingTime ?? Duration.zero,
        bookmarks: bookmarks ?? {},
        highlights: highlights ?? {},
      );
    } else {
      _stored = _stored!.copyWith(
        currentPage: currentPage,
        totalPages: totalPages,
        lastReadAt: DateTime.now(),
        readingTime: _stored!.readingTime + (additionalReadingTime ?? Duration.zero),
        bookmarks: bookmarks ?? _stored!.bookmarks,
        highlights: highlights ?? _stored!.highlights,
      );
    }
    return;
  }

  @override
  Future<ReadingProgressModel?> getProgress(String userId, String bookId) async => _stored;

  // The rest of BookRepository methods are not needed for these tests; provide stubs.
  @override
  Future<List<BookModel>> fetchBooks({int? limit}) async => [];

  @override
  Future<List<BookModel>> fetchBooksAdvanced({String? category, String? author, double? minRating, String? sortBy, int? limit}) async => [];

  @override
  Future<BookModel?> getBook(String id) async => null;

  @override
  Future<void> addOrUpdateBook(BookModel book) async {}

  @override
  Future<void> incrementDownload(String bookId) async {}

  @override
  Future<String> uploadBookFile({required String bookId, required String fileName, required List<int> bytes, required String contentType, void Function(double)? onProgress}) async {
    if (fail) throw Exception('network');
    // return a fake URL
    return 'https://example.com/${bookId}/${fileName}';
  }

  @override
  Future<String> addBookWithFile({required String bookId, required BookModel book, required String fileName, required List<int> bytes, required String contentType, void Function(double)? onProgress}) async {
    if (fail) throw Exception('network');
    final url = await uploadBookFile(bookId: bookId, fileName: fileName, bytes: bytes, contentType: contentType);
    return url;
  }

  @override
  Future<List<String>> getUserLibrary(String userId) async => [];

  @override
  Future<void> addToUserLibrary(String userId, String bookId, String status) async {}

  @override
  Future<void> removeFromUserLibrary(String userId, String bookId) async {}

  @override
  Future<List<String>> getUserLibraryByStatus(String userId, String status) async => [];
}

// For merge tests we don't need a repository; we'll call mergeProgress directly on BookService.

void main() {
  // No Firebase initialization required; tests use a fake repository and pure merge logic.
  test('updateReadingProgress happy path updates local and calls repo', () async {
    final repo = FakeRepo(fail: false);
    final svc = BookService(repository: repo);
    await svc.updateReadingProgress(bookId: 'b1', userId: 'u1', currentPage: 5, totalPages: 10, additionalReadingTime: Duration(seconds: 30));
    final p = svc.getReadingProgress('b1', 'u1');
    expect(p, isNotNull);
    expect(p!.currentPage, 5);
    expect(svc.getSyncStatus('b1', 'u1'), 'success');
  });

  test('updateReadingProgress network failure sets sync failed but keeps local', () async {
    final repo = FakeRepo(fail: true);
    final svc = BookService(repository: repo);
    await svc.updateReadingProgress(bookId: 'b2', userId: 'u2', currentPage: 3, totalPages: 20, additionalReadingTime: Duration(seconds: 20));
    final p = svc.getReadingProgress('b2', 'u2');
    expect(p, isNotNull);
    expect(p!.currentPage, 3);
    expect(svc.getSyncStatus('b2', 'u2'), 'failed');
  });

  test('mergeProgress merges two entries preferring newer lastReadAt and sums readingTime', () {
    final now = DateTime.now();
    final remote = ReadingProgressModel(
      id: 'u3_b3',
      userId: 'u3',
      bookId: 'b3',
      currentPage: 10,
      totalPages: 100,
      lastReadAt: now,
      readingTime: const Duration(minutes: 5),
    );
    final local = ReadingProgressModel(
      id: 'u3_b3_local',
      userId: 'u3',
      bookId: 'b3',
      currentPage: 8,
      totalPages: 100,
      lastReadAt: now.subtract(const Duration(minutes: 10)),
      readingTime: const Duration(minutes: 2),
    );
    final svc = BookService(repository: null);
  final merged = svc.mergeProgress(local, remote, prefer: 'remote');
    expect(merged.currentPage, 10);
    expect(merged.readingTime.inMinutes, greaterThanOrEqualTo(7));
    expect(merged.lastReadAt.isAtSameMomentAs(remote.lastReadAt), isTrue);
  });
}
