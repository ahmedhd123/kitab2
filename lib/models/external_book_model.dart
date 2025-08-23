// نموذج "كتاب خارجي" محفوظ للتخطيط والمراجعة فقط (غير قابل للقراءة داخل التطبيق)

import 'package:cloud_firestore/cloud_firestore.dart';

class ExternalBookModel {
  final String id;
  final String source; // openLibrary | googleBooks | goodreads ...
  final String externalId;
  final String title;
  final List<String> authors;
  final int? publishedYear;
  final String? coverUrl;
  final String? isbn13;
  final String? isbn10;
  final List<String> categories;
  final String? description;
  final String? language;
  final String createdBy;
  final DateTime createdAt;
  final bool readable; // دائماً false

  const ExternalBookModel({
    required this.id,
    required this.source,
    required this.externalId,
    required this.title,
    required this.authors,
    this.publishedYear,
    this.coverUrl,
    this.isbn13,
    this.isbn10,
    required this.categories,
    this.description,
    this.language,
    required this.createdBy,
    required this.createdAt,
    this.readable = false,
  });

  Map<String, dynamic> toMap() => {
        'source': source,
        'externalId': externalId,
        'title': title,
        'authors': authors,
        'publishedYear': publishedYear,
        'coverUrl': coverUrl,
        'isbn13': isbn13,
        'isbn10': isbn10,
        'categories': categories,
        'description': description,
        'language': language,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'readable': false,
      };

  factory ExternalBookModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ExternalBookModel(
      id: doc.id,
      source: d['source'] as String,
      externalId: d['externalId'] as String,
      title: d['title'] as String,
      authors: (d['authors'] as List<dynamic>? ?? []).cast<String>(),
      publishedYear: d['publishedYear'] as int?,
      coverUrl: d['coverUrl'] as String?,
      isbn13: d['isbn13'] as String?,
      isbn10: d['isbn10'] as String?,
      categories: (d['categories'] as List<dynamic>? ?? []).cast<String>(),
      description: d['description'] as String?,
      language: d['language'] as String?,
      createdBy: d['createdBy'] as String,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      readable: (d['readable'] as bool?) ?? false,
    );
  }
}
