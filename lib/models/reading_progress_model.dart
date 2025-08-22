class ReadingProgressModel {
  final String id;
  final String userId;
  final String bookId;
  final int currentPage;
  final int totalPages;
  final DateTime lastReadAt;
  final Duration readingTime;
  final bool isCompleted;
  final Map<String, dynamic> bookmarks; // صفحة -> ملاحظة
  final Map<String, dynamic> highlights; // صفحة -> نص مميز
  final double scrollOffset; // لحفظ موضع التمرير داخل الفصل/الصفحة (اختياري)

  ReadingProgressModel({
    required this.id,
    required this.userId,
    required this.bookId,
    this.currentPage = 0,
    required this.totalPages,
    required this.lastReadAt,
    this.readingTime = Duration.zero,
    this.isCompleted = false,
    this.bookmarks = const {},
    this.highlights = const {},
  this.scrollOffset = 0.0,
  });

  // نسبة التقدم (0.0 - 1.0)
  double get progressPercentage {
    if (totalPages == 0) return 0.0;
    return (currentPage / totalPages).clamp(0.0, 1.0);
  }

  // تحويل من Map
  factory ReadingProgressModel.fromMap(Map<String, dynamic> data) {
    return ReadingProgressModel(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      bookId: data['bookId'] ?? '',
      currentPage: data['currentPage'] ?? 0,
      totalPages: data['totalPages'] ?? 0,
      lastReadAt: DateTime.parse(data['lastReadAt'] ?? DateTime.now().toIso8601String()),
      readingTime: Duration(seconds: data['readingTimeSeconds'] ?? 0),
      isCompleted: data['isCompleted'] ?? false,
      bookmarks: Map<String, dynamic>.from(data['bookmarks'] ?? {}),
      highlights: Map<String, dynamic>.from(data['highlights'] ?? {}),
  scrollOffset: (data['scrollOffset'] is num) ? (data['scrollOffset'] as num).toDouble() : 0.0,
    );
  }

  // تحويل إلى Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'bookId': bookId,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'lastReadAt': lastReadAt.toIso8601String(),
      'readingTimeSeconds': readingTime.inSeconds,
      'isCompleted': isCompleted,
      'bookmarks': bookmarks,
      'highlights': highlights,
  'scrollOffset': scrollOffset,
    };
  }

  // نسخ مع تحديث
  ReadingProgressModel copyWith({
    String? id,
    String? userId,
    String? bookId,
    int? currentPage,
    int? totalPages,
    DateTime? lastReadAt,
    Duration? readingTime,
    bool? isCompleted,
    Map<String, dynamic>? bookmarks,
    Map<String, dynamic>? highlights,
    double? scrollOffset,
  }) {
    return ReadingProgressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookId: bookId ?? this.bookId,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      readingTime: readingTime ?? this.readingTime,
      isCompleted: isCompleted ?? this.isCompleted,
      bookmarks: bookmarks ?? this.bookmarks,
      highlights: highlights ?? this.highlights,
      scrollOffset: scrollOffset ?? this.scrollOffset,
    );
  }

  @override
  String toString() {
    return 'ReadingProgressModel(id: $id, bookId: $bookId, progress: ${(progressPercentage * 100).toInt()}%)';
  }
}
