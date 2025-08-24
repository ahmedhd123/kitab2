import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/reading_plan_model.dart';

/// خدمة إدارة تحديات القراءة
class ReadingChallengeService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ReadingPlanModel> _challenges = [];
  List<ReadingPlanModel> get challenges => List.unmodifiable(_challenges);

  /// إنشاء تحدي قراءة جديد
  Future<ReadingPlanModel> createChallenge({
    required String userId,
    required String title,
    required int targetBooks,
    required int year,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? DateTime(year, 1, 1);
      final end = endDate ?? DateTime(year, 12, 31, 23, 59, 59);
      
      final challengeData = {
        'userId': userId,
        'title': title,
        'type': ReadingPlanType.challenge.name,
        'status': ReadingPlanStatus.active.name,
        'goals': [],
        'year': year,
        'targetBooks': targetBooks,
        'completedBooks': 0,
        'startAt': Timestamp.fromDate(start),
        'endAt': Timestamp.fromDate(end),
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final docRef = await _firestore.collection('reading_challenges').add(challengeData);
      final doc = await docRef.get();
      final challenge = ReadingPlanModel.fromFirestore(doc);
      
      _challenges.add(challenge);
      notifyListeners();
      
      debugPrint('[ReadingChallengeService] تم إنشاء تحدي: ${challenge.title}');
      return challenge;
    } catch (e) {
      debugPrint('[ReadingChallengeService] خطأ في إنشاء التحدي: $e');
      rethrow;
    }
  }

  /// جلب تحديات المستخدم
  Future<void> loadUserChallenges(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reading_challenges')
          .where('userId', isEqualTo: userId)
          .get();

      _challenges = querySnapshot.docs
          .map((doc) => ReadingPlanModel.fromFirestore(doc))
          .toList();
      
      // ترتيب التحديات محلياً حسب تاريخ الإنشاء
      _challenges.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      debugPrint('[ReadingChallengeService] تم جلب ${_challenges.length} تحدي');
      notifyListeners();
    } catch (e) {
      debugPrint('[ReadingChallengeService] خطأ في جلب التحديات: $e');
      rethrow;
    }
  }

  /// تحديث تقدم التحدي
  Future<void> updateChallengeProgress(String challengeId, int completedBooks) async {
    try {
      await _firestore.collection('reading_challenges').doc(challengeId).update({
        'completedBooks': completedBooks,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // تحديث البيانات المحلية
      final index = _challenges.indexWhere((c) => c.id == challengeId);
      if (index != -1) {
        final oldChallenge = _challenges[index];
        final updatedChallenge = ReadingPlanModel(
          id: oldChallenge.id,
          userId: oldChallenge.userId,
          title: oldChallenge.title,
          type: oldChallenge.type,
          status: oldChallenge.status,
          goals: oldChallenge.goals,
          createdAt: oldChallenge.createdAt,
          updatedAt: DateTime.now(),
          year: oldChallenge.year,
          targetBooks: oldChallenge.targetBooks,
          completedBooks: completedBooks,
          startAt: oldChallenge.startAt,
          endAt: oldChallenge.endAt,
        );
        
        _challenges[index] = updatedChallenge;
        notifyListeners();
      }
      
      debugPrint('[ReadingChallengeService] تم تحديث التقدم: $completedBooks');
    } catch (e) {
      debugPrint('[ReadingChallengeService] خطأ في تحديث التقدم: $e');
      rethrow;
    }
  }

  /// إنهاء/إيقاف تحدي
  Future<void> updateChallengeStatus(String challengeId, ReadingPlanStatus status) async {
    try {
      await _firestore.collection('reading_challenges').doc(challengeId).update({
        'status': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // تحديث البيانات المحلية
      final index = _challenges.indexWhere((c) => c.id == challengeId);
      if (index != -1) {
        final oldChallenge = _challenges[index];
        final updatedChallenge = ReadingPlanModel(
          id: oldChallenge.id,
          userId: oldChallenge.userId,
          title: oldChallenge.title,
          type: oldChallenge.type,
          status: status,
          goals: oldChallenge.goals,
          createdAt: oldChallenge.createdAt,
          updatedAt: DateTime.now(),
          year: oldChallenge.year,
          targetBooks: oldChallenge.targetBooks,
          completedBooks: oldChallenge.completedBooks,
          startAt: oldChallenge.startAt,
          endAt: oldChallenge.endAt,
        );
        
        _challenges[index] = updatedChallenge;
        notifyListeners();
      }
      
      debugPrint('[ReadingChallengeService] تم تحديث حالة التحدي: ${status.name}');
    } catch (e) {
      debugPrint('[ReadingChallengeService] خطأ في تحديث حالة التحدي: $e');
      rethrow;
    }
  }

  /// حذف تحدي
  Future<void> deleteChallenge(String challengeId) async {
    try {
      await _firestore.collection('reading_challenges').doc(challengeId).delete();
      
      _challenges.removeWhere((c) => c.id == challengeId);
      notifyListeners();
      
      debugPrint('[ReadingChallengeService] تم حذف التحدي');
    } catch (e) {
      debugPrint('[ReadingChallengeService] خطأ في حذف التحدي: $e');
      rethrow;
    }
  }

  /// الحصول على التحدي النشط للسنة الحالية
  ReadingPlanModel? get currentYearChallenge {
    final currentYear = DateTime.now().year;
    return _challenges
        .where((c) => c.year == currentYear && c.status == ReadingPlanStatus.active)
        .firstOrNull;
  }

  /// الحصول على التحديات النشطة
  List<ReadingPlanModel> get activeChallenges {
    return _challenges
        .where((c) => c.status == ReadingPlanStatus.active)
        .toList();
  }

  /// مراقبة تحديات المستخدم في الوقت الفعلي
  Stream<List<ReadingPlanModel>> watchUserChallenges(String userId) {
    return _firestore
        .collection('reading_challenges')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      _challenges = snapshot.docs
          .map((doc) => ReadingPlanModel.fromFirestore(doc))
          .toList();
      
      // ترتيب التحديات محلياً حسب تاريخ الإنشاء
      _challenges.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // تحديث UI
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      
      return _challenges;
    });
  }
}
