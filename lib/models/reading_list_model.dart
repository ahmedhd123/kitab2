// نموذج "قائمة قراءة" وعناصرها
// تُستخدم لإدارة القوائم المخصصة وربط عناصر داخلية/خارجية

import 'package:cloud_firestore/cloud_firestore.dart';

enum ReadingListPrivacy { private, shared }
enum ReadingListItemSource { internal, external }
enum ReadingListItemStatus { planned, in_progress, done }

class ReadingListModel {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final ReadingListPrivacy privacy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReadingListModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.privacy,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'description': description,
        'privacy': privacy.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory ReadingListModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ReadingListModel(
      id: doc.id,
      userId: d['userId'] as String,
      name: d['name'] as String,
      description: d['description'] as String?,
      privacy: ReadingListPrivacy.values.firstWhere(
        (e) => e.name == (d['privacy'] as String? ?? 'private'),
        orElse: () => ReadingListPrivacy.private,
      ),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    );
  }
}

class ReadingListItemModel {
  final String id;
  final String userId;
  final ReadingListItemSource source;
  final DocumentReference? bookRef; // عند source=internal
  final String? externalBookId; // عند source=external
  final ReadingListItemStatus status;
  final String priority; // low|normal|high
  final String? notes;
  final DateTime addedAt;

  const ReadingListItemModel({
    required this.id,
    required this.userId,
    required this.source,
    this.bookRef,
    this.externalBookId,
    required this.status,
    required this.priority,
    this.notes,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'source': source.name,
        'bookRef': bookRef,
        'externalBookId': externalBookId,
        'status': status.name,
        'priority': priority,
        'notes': notes,
        'addedAt': Timestamp.fromDate(addedAt),
      };

  factory ReadingListItemModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ReadingListItemModel(
      id: doc.id,
      userId: d['userId'] as String,
      source: ReadingListItemSource.values.firstWhere(
        (e) => e.name == (d['source'] as String? ?? 'internal'),
        orElse: () => ReadingListItemSource.internal,
      ),
      bookRef: d['bookRef'] as DocumentReference?,
      externalBookId: d['externalBookId'] as String?,
      status: ReadingListItemStatus.values.firstWhere(
        (e) => e.name == (d['status'] as String? ?? 'planned'),
        orElse: () => ReadingListItemStatus.planned,
      ),
      priority: (d['priority'] as String?) ?? 'normal',
      notes: d['notes'] as String?,
      addedAt: (d['addedAt'] as Timestamp).toDate(),
    );
  }
}
