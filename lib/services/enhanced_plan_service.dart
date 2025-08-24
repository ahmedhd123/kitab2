import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/enhanced_reading_plan_model.dart';
import '../models/book_model.dart';

class EnhancedPlanService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<ReadingPlan> _plans = [];
  bool _isLoading = false;

  List<ReadingPlan> get plans => _plans;
  bool get isLoading => _isLoading;

  // تحميل خطط المستخدم مع تحديثات في الوقت الفعلي
  Future<void> loadUserPlans(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('[EnhancedPlanService] جاري تحميل خطط المستخدم: $userId');

      final snapshot = await _firestore
          .collection('reading_plans')
          .where('userId', isEqualTo: userId)
          .get(); // إزالة orderBy لتجنب مشاكل الفهرس

      _plans = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id; // إضافة معرف الوثيقة
              return ReadingPlan.fromFirestore(data);
            } catch (e) {
              debugPrint('[EnhancedPlanService] خطأ في تحليل خطة: ${doc.id}, $e');
              return null;
            }
          })
          .whereType<ReadingPlan>()
          .toList();

      // ترتيب الخطط محلياً حسب تاريخ الإنشاء
      _plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      debugPrint('[EnhancedPlanService] تم تحميل ${_plans.length} خطة');
      
    } catch (e) {
      debugPrint('[EnhancedPlanService] خطأ في تحميل الخطط: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // مراقبة خطط المستخدم في الوقت الفعلي
  Stream<List<ReadingPlan>> watchUserPlans(String userId) {
    debugPrint('[EnhancedPlanService] بدء مراقبة خطط المستخدم: $userId');
    
    return _firestore
        .collection('reading_plans')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      debugPrint('[EnhancedPlanService] تحديث خطط: ${snapshot.docs.length} وثيقة');
      
      _plans = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              return ReadingPlan.fromFirestore(data);
            } catch (e) {
              debugPrint('[EnhancedPlanService] خطأ في تحليل خطة: ${doc.id}, $e');
              return null;
            }
          })
          .whereType<ReadingPlan>()
          .toList();

      // ترتيب محلي
      _plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // تحديث UI
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      
      return _plans;
    });
  }

  // إنشاء خطة جديدة مع تحسينات
  Future<String?> createPlan({
    required String userId,
    required String name,
    required String description,
    required PlanType type,
    DateTime? targetDate,
    List<String> initialBookIds = const [],
    ReadingGoal? goal,
  }) async {
    try {
      debugPrint('[EnhancedPlanService] إنشاء خطة جديدة: $name');
      
      final planId = _firestore.collection('reading_plans').doc().id;
      final now = DateTime.now();
      
      final plan = ReadingPlan(
        id: planId,
        name: name,
        description: description,
        type: type,
        createdAt: now,
        targetDate: targetDate,
        bookIds: initialBookIds,
        goal: goal,
        userId: userId,
        progress: {}, // تهيئة فارغة
        status: PlanStatus.active,
      );

      final planData = plan.toMap();
      planData['createdAt'] = Timestamp.fromDate(now);
      planData['updatedAt'] = Timestamp.fromDate(now);
      
      await _firestore
          .collection('reading_plans')
          .doc(planId)
          .set(planData);

      // إضافة للقائمة المحلية
      _plans.insert(0, plan);
      notifyListeners();

      debugPrint('[EnhancedPlanService] تم إنشاء الخطة بنجاح: $planId');
      return planId;
    } catch (e) {
      debugPrint('[EnhancedPlanService] خطأ في إنشاء الخطة: $e');
      return null;
    }
  }

  // إضافة كتاب إلى خطة
  Future<bool> addBookToPlan(String planId, String bookId) async {
    try {
      final planIndex = _plans.indexWhere((p) => p.id == planId);
      if (planIndex == -1) return false;

      final plan = _plans[planIndex];
      if (plan.bookIds.contains(bookId)) return true;

      final updatedBookIds = [...plan.bookIds, bookId];
      final updatedProgress = Map<String, double>.from(plan.progress);
      updatedProgress[bookId] = 0.0;

      await _firestore.collection('reading_plans').doc(planId).update({
        'bookIds': updatedBookIds,
        'progress': updatedProgress,
      });

      _plans[planIndex] = ReadingPlan(
        id: plan.id,
        name: plan.name,
        description: plan.description,
        type: plan.type,
        createdAt: plan.createdAt,
        targetDate: plan.targetDate,
        bookIds: updatedBookIds,
        progress: updatedProgress,
        goal: plan.goal,
        status: plan.status,
        userId: plan.userId,
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding book to plan: $e');
      return false;
    }
  }

  // تحديث تقدم كتاب في خطة
  Future<bool> updateBookProgress(String planId, String bookId, double progress) async {
    try {
      final planIndex = _plans.indexWhere((p) => p.id == planId);
      if (planIndex == -1) return false;

      final plan = _plans[planIndex];
      final updatedProgress = Map<String, double>.from(plan.progress);
      updatedProgress[bookId] = progress.clamp(0.0, 1.0);

      await _firestore.collection('reading_plans').doc(planId).update({
        'progress': updatedProgress,
      });

      _plans[planIndex] = ReadingPlan(
        id: plan.id,
        name: plan.name,
        description: plan.description,
        type: plan.type,
        createdAt: plan.createdAt,
        targetDate: plan.targetDate,
        bookIds: plan.bookIds,
        progress: updatedProgress,
        goal: plan.goal,
        status: plan.status,
        userId: plan.userId,
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating book progress: $e');
      return false;
    }
  }

  // إزالة كتاب من خطة
  Future<bool> removeBookFromPlan(String planId, String bookId) async {
    try {
      final planIndex = _plans.indexWhere((p) => p.id == planId);
      if (planIndex == -1) return false;

      final plan = _plans[planIndex];
      final updatedBookIds = plan.bookIds.where((id) => id != bookId).toList();
      final updatedProgress = Map<String, double>.from(plan.progress);
      updatedProgress.remove(bookId);

      await _firestore.collection('reading_plans').doc(planId).update({
        'bookIds': updatedBookIds,
        'progress': updatedProgress,
      });

      _plans[planIndex] = ReadingPlan(
        id: plan.id,
        name: plan.name,
        description: plan.description,
        type: plan.type,
        createdAt: plan.createdAt,
        targetDate: plan.targetDate,
        bookIds: updatedBookIds,
        progress: updatedProgress,
        goal: plan.goal,
        status: plan.status,
        userId: plan.userId,
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error removing book from plan: $e');
      return false;
    }
  }

  // تحديث خطة
  Future<bool> updatePlan(ReadingPlan plan) async {
    try {
      await _firestore
          .collection('reading_plans')
          .doc(plan.id)
          .update(plan.toMap());

      final index = _plans.indexWhere((p) => p.id == plan.id);
      if (index != -1) {
        _plans[index] = plan;
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating plan: $e');
      return false;
    }
  }

  // حذف خطة
  Future<bool> deletePlan(String planId) async {
    try {
      await _firestore.collection('reading_plans').doc(planId).delete();
      _plans.removeWhere((p) => p.id == planId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting plan: $e');
      return false;
    }
  }

  // الحصول على خطط حسب النوع
  List<ReadingPlan> getPlansByType(PlanType type) {
    return _plans.where((plan) => plan.type == type && plan.status == PlanStatus.active).toList();
  }

  // الحصول على الخطط النشطة
  List<ReadingPlan> getActivePlans() {
    return _plans.where((plan) => plan.status == PlanStatus.active).toList();
  }

  // الحصول على تقدم الكتاب في جميع الخطط
  Map<String, double> getBookProgressInAllPlans(String bookId) {
    final result = <String, double>{};
    for (final plan in _plans) {
      if (plan.bookIds.contains(bookId) && plan.progress.containsKey(bookId)) {
        result[plan.name] = plan.progress[bookId]!;
      }
    }
    return result;
  }

  // إحصائيات القراءة العامة
  ReadingStats getReadingStats() {
    final activePlans = getActivePlans();
    int totalBooks = 0;
    int completedBooks = 0;
    int inProgressBooks = 0;
    double totalProgress = 0.0;

    for (final plan in activePlans) {
      totalBooks += plan.bookIds.length;
      completedBooks += plan.completedBooksCount;
      inProgressBooks += plan.inProgressBooksCount;
      totalProgress += plan.overallProgress;
    }

    return ReadingStats(
      totalPlans: activePlans.length,
      totalBooks: totalBooks,
      completedBooks: completedBooks,
      inProgressBooks: inProgressBooks,
      averageProgress: activePlans.isNotEmpty ? totalProgress / activePlans.length : 0.0,
    );
  }

  // إنشاء خطط افتراضية للمستخدم الجديد
  Future<void> createDefaultPlans(String userId) async {
    final defaultPlans = [
      {
        'name': 'أريد قراءته',
        'description': 'الكتب التي أخطط لقراءتها قريباً',
        'type': PlanType.wantToRead,
      },
      {
        'name': 'أقرأ حالياً',
        'description': 'الكتب التي أقرأها في الوقت الحالي',
        'type': PlanType.currentlyReading,
      },
      {
        'name': 'مكتملة',
        'description': 'الكتب التي انتهيت من قراءتها',
        'type': PlanType.completed,
      },
      {
        'name': 'المفضلة',
        'description': 'كتبي المفضلة التي أُعجبت بها',
        'type': PlanType.favorites,
      },
    ];

    for (final planData in defaultPlans) {
      await createPlan(
        userId: userId,
        name: planData['name'] as String,
        description: planData['description'] as String,
        type: planData['type'] as PlanType,
      );
    }
  }
}

class ReadingStats {
  final int totalPlans;
  final int totalBooks;
  final int completedBooks;
  final int inProgressBooks;
  final double averageProgress;

  ReadingStats({
    required this.totalPlans,
    required this.totalBooks,
    required this.completedBooks,
    required this.inProgressBooks,
    required this.averageProgress,
  });
}
