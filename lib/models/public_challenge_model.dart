import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج تحدي قراءة عام (قابل للانضمام للجميع)
class PublicChallengeModel {
  final String id;
  final String ownerId;
  final String title; // اسم التحدي
  final String description; // الوصف
  final DateTime startAt; // تاريخ البداية
  final DateTime endAt; // تاريخ النهاية
  final DateTime createdAt;
  final String status; // active | closed
  final String inviteToken; // رابط/رمز المشاركة

  PublicChallengeModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.startAt,
    required this.endAt,
    required this.createdAt,
    required this.status,
    required this.inviteToken,
  });

  bool get isActive => status == 'active' && DateTime.now().isBefore(endAt);

  int get daysLeft => endAt.difference(DateTime.now()).inDays;

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'title': title,
        'description': description,
        'startAt': Timestamp.fromDate(startAt),
        'endAt': Timestamp.fromDate(endAt),
        'createdAt': Timestamp.fromDate(createdAt),
        'status': status,
        'inviteToken': inviteToken,
      };

  static PublicChallengeModel fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PublicChallengeModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startAt: (data['startAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endAt: (data['endAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'active',
      inviteToken: data['inviteToken'] ?? '',
    );
  }
}

/// عنصر كتاب مشارك به المستخدم داخل التحدي (قد يكون من المكتبة أو مُدخل يدوياً)
class ChallengeBookEntry {
  final String? bookId; // اختياري إذا كان من المكتبة
  final String title;
  final String? author;
  final String? coverUrl;
  final int pages; // عدد الصفحات

  ChallengeBookEntry({
    this.bookId,
    required this.title,
    this.author,
    this.coverUrl,
    required this.pages,
  });

  Map<String, dynamic> toMap() => {
        'bookId': bookId,
        'title': title,
        'author': author,
        'coverUrl': coverUrl,
        'pages': pages,
      };

  static ChallengeBookEntry fromMap(Map<String, dynamic> data) => ChallengeBookEntry(
        bookId: data['bookId'],
        title: data['title'] ?? '',
        author: data['author'],
        coverUrl: data['coverUrl'],
        pages: (data['pages'] ?? 0) as int,
      );
}

/// مشاركة مستخدم في التحدي
class ChallengeParticipant {
  final String userId;
  final String? displayName;
  final DateTime joinedAt;
  final int pagesTarget; // إجمالي الصفحات المستهدفة عبر الكتب المحددة
  final int pagesRead; // الصفحات المقروءة
  final int durationDays; // مدة القراءة التي حددها المشارك (اختياري)
  final List<ChallengeBookEntry> books;

  ChallengeParticipant({
    required this.userId,
    this.displayName,
    required this.joinedAt,
    required this.pagesTarget,
    required this.pagesRead,
    required this.durationDays,
    required this.books,
  });

  double get progressPercent => pagesTarget > 0 ? (pagesRead / pagesTarget) * 100.0 : 0.0;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayName': displayName,
        'joinedAt': Timestamp.fromDate(joinedAt),
        'pagesTarget': pagesTarget,
        'pagesRead': pagesRead,
        'durationDays': durationDays,
        'books': books.map((b) => b.toMap()).toList(),
      };

  static ChallengeParticipant fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final books = (data['books'] as List<dynamic>? ?? [])
        .map((e) => ChallengeBookEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return ChallengeParticipant(
      userId: data['userId'] ?? doc.id,
      displayName: data['displayName'],
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pagesTarget: (data['pagesTarget'] ?? 0) as int,
      pagesRead: (data['pagesRead'] ?? 0) as int,
      durationDays: (data['durationDays'] ?? 0) as int,
      books: books,
    );
  }
}
