class ReviewModel {
  final String id;
  final String bookId;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> likes;
  final List<String> dislikes;

  ReviewModel({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl = '',
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
    this.likes = const [],
    this.dislikes = const [],
  });

  // تحويل من Map
  factory ReviewModel.fromMap(Map<String, dynamic> data) {
    return ReviewModel(
      id: data['id'] ?? '',
      bookId: data['bookId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt']) : null,
      likes: List<String>.from(data['likes'] ?? []),
      dislikes: List<String>.from(data['dislikes'] ?? []),
    );
  }

  // تحويل إلى Map للحفظ
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'likes': likes,
      'dislikes': dislikes,
    };
  }

  // إنشاء من مستند Firestore
  factory ReviewModel.fromFirestore(dynamic doc) {
    final data = (doc is Map<String, dynamic>) ? doc : (doc.data() as Map<String, dynamic>);
    return ReviewModel(
      id: doc is Map<String, dynamic> ? (data['id'] ?? '') : (doc.id ?? data['id'] ?? ''),
      bookId: data['bookId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: _parseDate(data['createdAt']),
      updatedAt: data['updatedAt'] != null ? _parseDate(data['updatedAt']) : null,
      likes: List<String>.from(data['likes'] ?? []),
      dislikes: List<String>.from(data['dislikes'] ?? []),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    // دعم Timestamp الخاص بـ Firestore دون استيراد مباشر لتجنب الأخطاء أثناء عدم توفر الحزمة
    final ts = value.toString();
    return DateTime.tryParse(ts) ?? DateTime.now();
  }

  // عدد الإعجابات
  int get likesCount => likes.length;

  // عدد عدم الإعجاب
  int get dislikesCount => dislikes.length;

  // نسخة محدثة من المراجعة
  ReviewModel copyWith({
    String? id,
    String? bookId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    double? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? likes,
    List<String>? dislikes,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
    );
  }

  @override
  String toString() {
    return 'ReviewModel(id: $id, bookId: $bookId, userName: $userName, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
