// نموذج "خطة قراءة"
// ملاحظات:
// - استخدم أسماء الحقول بالإنجليزية، والنصوص/التعليقات بالعربية
// - التحويل مع Firestore عبر toMap() و fromFirestore()

import 'package:cloud_firestore/cloud_firestore.dart';

// أنواع الخطط: تاريخية، مخصصة، أو تحدّي سنوي على نمط Goodreads
enum ReadingPlanType { history, custom, challenge }
enum ReadingPlanStatus { active, paused, done }

class PlanGoal {
  final String kind; // count | time | series | genre
  final int? target; // مثل عدد الكتب
  final String? period; // weekly | monthly | yearly
  final DateTime? dueDate;
  final int? progress; // تقدم رقمي بسيط

  const PlanGoal({
    required this.kind,
    this.target,
    this.period,
    this.dueDate,
    this.progress,
  });

  Map<String, dynamic> toMap() {
    return {
      'kind': kind,
      'target': target,
      'period': period,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'progress': progress,
    };
  }

  factory PlanGoal.fromMap(Map<String, dynamic> data) {
    return PlanGoal(
      kind: data['kind'] as String,
      target: data['target'] as int?,
      period: data['period'] as String?,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      progress: data['progress'] as int?,
    );
  }
}

class ReadingPlanModel {
  final String id;
  final String userId;
  final String title; // عنوان الخطة (مثلاً: تحدّي قراءة 20 كتاباً في 2025)
  final ReadingPlanType type;
  final ReadingPlanStatus status;
  final List<PlanGoal> goals;
  final DateTime createdAt;
  final DateTime updatedAt;

  // حقول خاصة بتحدّي القراءة (Goodreads-like)
  final int? year; // السنة المستهدفة (مثلاً 2025)
  final int? targetBooks; // عدد الكتب المستهدف قراءتها في السنة
  final int? completedBooks; // عدد الكتب المُنجَزة حتى الآن
  final DateTime? startAt; // تاريخ بداية التحدّي
  final DateTime? endAt; // تاريخ نهاية التحدّي

  const ReadingPlanModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.status,
    required this.goals,
    required this.createdAt,
    required this.updatedAt,
  this.year,
  this.targetBooks,
  this.completedBooks,
  this.startAt,
  this.endAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'type': type.name,
      'status': status.name,
      'goals': goals.map((g) => g.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      // تحدّي القراءة
      'year': year,
      'targetBooks': targetBooks,
      'completedBooks': completedBooks,
      'startAt': startAt != null ? Timestamp.fromDate(startAt!) : null,
      'endAt': endAt != null ? Timestamp.fromDate(endAt!) : null,
    };
  }

  factory ReadingPlanModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    DateTime _toDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }
    return ReadingPlanModel(
      id: doc.id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      type: ReadingPlanType.values.firstWhere(
        (e) => e.name == (data['type'] as String? ?? 'custom'),
        orElse: () => ReadingPlanType.custom,
      ),
      status: ReadingPlanStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'active'),
        orElse: () => ReadingPlanStatus.active,
      ),
      goals: (data['goals'] as List<dynamic>? ?? [])
          .map((g) => PlanGoal.fromMap(Map<String, dynamic>.from(g as Map)))
          .toList(),
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
      year: (data['year'] as num?)?.toInt(),
      targetBooks: (data['targetBooks'] as num?)?.toInt(),
      completedBooks: (data['completedBooks'] as num?)?.toInt(),
      startAt: data['startAt'] != null ? _toDate(data['startAt']) : null,
      endAt: data['endAt'] != null ? _toDate(data['endAt']) : null,
    );
  }

  // نسبة إنجاز التحدّي (0..1)
  double get challengeProgress {
    final t = targetBooks ?? 0;
    final c = completedBooks ?? 0;
    if (t <= 0) return 0;
    final p = c / t;
    return p.clamp(0, 1);
  }
}
