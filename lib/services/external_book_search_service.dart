import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/external_book_model.dart';

// خدمة البحث الخارجي (إصدار أولي):
// - تبحث داخلياً في external_books أولاً
// - مكان لاستدعاء مصدر خارجي لاحقاً (Open Library/Google Books) عبر Cloud Functions
class ExternalBookSearchService extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  Future<List<ExternalBookModel>> search(String query) async {
    if (query.trim().isEmpty) return [];

    // بحث داخلي بسيط بالعنوان (lowercase)
    final q = query.toLowerCase();
    final snap = await _db
        .collection('external_books')
        .where('readable', isEqualTo: false)
        .get();
    final internal = snap.docs
        .map((d) => ExternalBookModel.fromFirestore(d))
        .where((b) => b.title.toLowerCase().contains(q))
        .toList();

    // TODO: عند عدم وجود نتائج كافية، استدعِ Cloud Function لمصدر خارجي ثم خزّن النتائج
    return internal;
  }

  Future<ExternalBookModel> upsertExternalBook({
    required String createdBy,
    required String source,
    required String externalId,
    required String title,
    required List<String> authors,
    int? publishedYear,
    String? coverUrl,
    String? isbn13,
    String? isbn10,
    List<String> categories = const [],
    String? description,
    String? language,
  }) async {
    final col = _db.collection('external_books');
    final existing = await col
        .where('source', isEqualTo: source)
        .where('externalId', isEqualTo: externalId)
        .limit(1)
        .get();

    final data = ExternalBookModel(
      id: existing.docs.isNotEmpty ? existing.docs.first.id : 'tmp',
      source: source,
      externalId: externalId,
      title: title,
      authors: authors,
      publishedYear: publishedYear,
      coverUrl: coverUrl,
      isbn13: isbn13,
      isbn10: isbn10,
      categories: categories,
      description: description,
      language: language,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      readable: false,
    );

    if (existing.docs.isNotEmpty) {
      final docId = existing.docs.first.id;
      await col.doc(docId).update(data.toMap());
      final updated = await col.doc(docId).get();
      final model = ExternalBookModel.fromFirestore(updated);
      notifyListeners();
      return model;
    } else {
      final ref = await col.add(data.toMap());
      final snap = await ref.get();
      final model = ExternalBookModel.fromFirestore(snap);
      notifyListeners();
      return model;
    }
  }
}
