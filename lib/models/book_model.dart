class BookModel {
  final String id;
  final String title;
  final String author;
  final String authorBio; // نبذة عن الكاتب
  final String description;
  final String category;
  final String coverImageUrl;
  final String bookSummary; // نبذة عن الكتاب
  final String fileUrl;
  final String fileType;
  final double averageRating;
  final int totalReviews;
  final int downloadCount;
  final String uploadedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? releaseDate; // تاريخ الإصدار
  final List<String> tags;
  final int pageCount;
  final String language;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
  this.authorBio = '',
    required this.description,
    required this.category,
    required this.coverImageUrl,
  this.bookSummary = '',
    required this.fileUrl,
    required this.fileType,
    required this.averageRating,
    required this.totalReviews,
    required this.downloadCount,
    required this.uploadedBy,
    required this.createdAt,
    this.updatedAt,
  this.releaseDate,
    required this.tags,
    required this.pageCount,
    required this.language,
  });

  // إنشاء BookModel من البيانات
  factory BookModel.fromMap(Map<String, dynamic> data) {
    return BookModel(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      author: data['author'] ?? '',
  authorBio: data['authorBio'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      coverImageUrl: data['coverImageUrl'] ?? '',
  bookSummary: data['bookSummary'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      fileType: data['fileType'] ?? 'pdf',
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      downloadCount: data['downloadCount'] ?? 0,
      uploadedBy: data['uploadedBy'] ?? '',
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt']) : null,
  releaseDate: data['releaseDate'] != null ? DateTime.tryParse(data['releaseDate']) : null,
      tags: List<String>.from(data['tags'] ?? []),
      pageCount: data['pageCount'] ?? 0,
      language: data['language'] ?? 'ar',
    );
  }

  // تحويل إلى Map للحفظ
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
  'authorBio': authorBio,
      'description': description,
      'category': category,
      'coverImageUrl': coverImageUrl,
  'bookSummary': bookSummary,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'downloadCount': downloadCount,
      'uploadedBy': uploadedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
  'releaseDate': releaseDate?.toIso8601String(),
      'tags': tags,
      'pageCount': pageCount,
      'language': language,
    };
  }

  // تحديث نسخة من الكتاب
  BookModel copyWith({
    String? id,
    String? title,
    String? author,
  String? authorBio,
    String? description,
    String? category,
    String? coverImageUrl,
    String? bookSummary,
    String? fileUrl,
    String? fileType,
    double? averageRating,
    int? totalReviews,
    int? downloadCount,
    String? uploadedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? releaseDate,
    List<String>? tags,
    int? pageCount,
    String? language,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
  authorBio: authorBio ?? this.authorBio,
      description: description ?? this.description,
      category: category ?? this.category,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      bookSummary: bookSummary ?? this.bookSummary,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      downloadCount: downloadCount ?? this.downloadCount,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      releaseDate: releaseDate ?? this.releaseDate,
      tags: tags ?? this.tags,
      pageCount: pageCount ?? this.pageCount,
      language: language ?? this.language,
    );
  }

  @override
  String toString() {
    return 'BookModel(id: $id, title: $title, author: $author)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
