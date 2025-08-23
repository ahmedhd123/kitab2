import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/reading_plan_model.dart';

// خدمة إدارة خطط القراءة
class PlanService extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  Future<ReadingPlanModel> createPlan({
    required String userId,
    required String title,
    ReadingPlanType type = ReadingPlanType.custom,
    List<PlanGoal> goals = const [],
  }) async {
    try {
      final now = DateTime.now();
      final ref = await _db.collection('reading_plans').add({
        'userId': userId,
        'title': title,
        'type': type.name,
        'status': ReadingPlanStatus.active.name,
        'goals': goals.map((g) => g.toMap()).toList(),
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
      final snap = await ref.get();
      final model = ReadingPlanModel.fromFirestore(snap);
      notifyListeners();
      return model;
    } catch (e) {
      debugPrint('createPlan error: $e');
      rethrow;
    }
  }

  /// إنشاء "تحدّي قراءة" سنوي على نمط Goodreads
  Future<ReadingPlanModel> createYearlyChallenge({
    required String userId,
    required int year,
    required int targetBooks,
  }) async {
    try {
      final now = DateTime.now();
      final start = DateTime(year, 1, 1);
      final end = DateTime(year, 12, 31, 23, 59, 59);
      final ref = await _db.collection('reading_plans').add({
        'userId': userId,
        'title': 'تحدّي القراءة $year',
        'type': ReadingPlanType.challenge.name,
        'status': ReadingPlanStatus.active.name,
        'goals': const [],
        'year': year,
        'targetBooks': targetBooks,
        'completedBooks': 0,
        'startAt': Timestamp.fromDate(start),
        'endAt': Timestamp.fromDate(end),
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
      final snap = await ref.get();
      final model = ReadingPlanModel.fromFirestore(snap);
      notifyListeners();
      return model;
    } catch (e) {
      debugPrint('createYearlyChallenge error: $e');
      rethrow;
    }
  }

  Stream<List<ReadingPlanModel>> watchUserPlans(String userId) {
    // نتجنب الحاجة إلى فهرس مركّب عبر الفرز محلياً بعد الجلب
    return _db
        .collection('reading_plans')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final items = s.docs.map((d) => ReadingPlanModel.fromFirestore(d)).toList();
          items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return items;
        });
  }

  Future<void> updatePlanStatus(String planId, ReadingPlanStatus status) async {
    await _db.collection('reading_plans').doc(planId).update({
      'status': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    notifyListeners();
  }

  Future<void> addGoal(String planId, PlanGoal goal) async {
    final ref = _db.collection('reading_plans').doc(planId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data()!;
      final goals = (data['goals'] as List<dynamic>? ?? []);
      goals.add(goal.toMap());
      tx.update(ref, {
        'goals': goals,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
    notifyListeners();
  }
}
