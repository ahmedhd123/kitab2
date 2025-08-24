import 'package:flutter/material.dart';

// نماذج البيانات لنظام الخطط المحسن

class ReadingPlan {
  final String id;
  final String name;
  final String description;
  final PlanType type;
  final DateTime createdAt;
  final DateTime? targetDate;
  final List<String> bookIds;
  final Map<String, double> progress; // bookId -> progress (0-1)
  final ReadingGoal? goal;
  final PlanStatus status;
  final String userId;

  ReadingPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.createdAt,
    this.targetDate,
    this.bookIds = const [],
    this.progress = const {},
    this.goal,
    this.status = PlanStatus.active,
    required this.userId,
  });

  // حساب التقدم الإجمالي
  double get overallProgress {
    if (bookIds.isEmpty) return 0.0;
    double totalProgress = 0.0;
    for (String bookId in bookIds) {
      totalProgress += progress[bookId] ?? 0.0;
    }
    return totalProgress / bookIds.length;
  }

  // عدد الكتب المكتملة
  int get completedBooksCount {
    return progress.values.where((p) => p >= 1.0).length;
  }

  // عدد الكتب قيد القراءة
  int get inProgressBooksCount {
    return progress.values.where((p) => p > 0.0 && p < 1.0).length;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'targetDate': targetDate?.millisecondsSinceEpoch,
      'bookIds': bookIds,
      'progress': progress,
      'goal': goal?.toMap(),
      'status': status.toString(),
      'userId': userId,
    };
  }

  factory ReadingPlan.fromFirestore(Map<String, dynamic> data) {
    return ReadingPlan(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: PlanType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => PlanType.custom,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
      targetDate: data['targetDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['targetDate'])
          : null,
      bookIds: List<String>.from(data['bookIds'] ?? []),
      progress: Map<String, double>.from(data['progress'] ?? {}),
      goal: data['goal'] != null ? ReadingGoal.fromMap(data['goal']) : null,
      status: PlanStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => PlanStatus.active,
      ),
      userId: data['userId'] ?? '',
    );
  }
}

class ReadingGoal {
  final GoalType type;
  final int targetValue;
  final int currentValue;
  final DateTime deadline;
  final String unit; // 'books', 'pages', 'minutes'

  ReadingGoal({
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    required this.deadline,
    required this.unit,
  });

  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  bool get isCompleted => currentValue >= targetValue;

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'targetValue': targetValue,
      'currentValue': currentValue,
      'deadline': deadline.millisecondsSinceEpoch,
      'unit': unit,
    };
  }

  factory ReadingGoal.fromMap(Map<String, dynamic> data) {
    return ReadingGoal(
      type: GoalType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => GoalType.booksCount,
      ),
      targetValue: data['targetValue'] ?? 0,
      currentValue: data['currentValue'] ?? 0,
      deadline: DateTime.fromMillisecondsSinceEpoch(data['deadline'] ?? 0),
      unit: data['unit'] ?? 'books',
    );
  }
}

enum PlanType {
  wantToRead,     // مخطط لقراءته
  currentlyReading, // أقرأه حالياً
  completed,      // مكتملة
  favorites,      // مفضلة
  custom,         // مخصصة
  challenge,      // تحدي قراءة
}

enum PlanStatus {
  active,         // نشطة
  paused,         // متوقفة
  completed,      // مكتملة
  archived,       // مؤرشفة
}

enum GoalType {
  booksCount,     // عدد الكتب
  pagesCount,     // عدد الصفحات
  readingTime,    // وقت القراءة
  streakDays,     // أيام متتالية
}

// حالات الكتب المحسنة
enum EnhancedBookStatus {
  wantToRead,     // أريد قراءته
  currentlyReading, // أقرأه حالياً
  completed,      // مكتمل
  paused,         // متوقف
  dnf,           // لن أكمله (Did Not Finish)
  rereading,     // أعيد قراءته
}

extension PlanTypeExtension on PlanType {
  String get displayName {
    switch (this) {
      case PlanType.wantToRead:
        return 'مخطط لقراءته';
      case PlanType.currentlyReading:
        return 'أقرأه حالياً';
      case PlanType.completed:
        return 'مكتملة';
      case PlanType.favorites:
        return 'المفضلة';
      case PlanType.custom:
        return 'مخصصة';
      case PlanType.challenge:
        return 'تحدي قراءة';
    }
  }

  String get description {
    switch (this) {
      case PlanType.wantToRead:
        return 'الكتب التي تخطط لقراءتها';
      case PlanType.currentlyReading:
        return 'الكتب التي تقرأها حالياً مع تتبع التقدم';
      case PlanType.completed:
        return 'الكتب التي أنهيت قراءتها';
      case PlanType.favorites:
        return 'كتبك المفضلة وأكثرها إعجاباً';
      case PlanType.custom:
        return 'خطة مخصصة حسب اختيارك';
      case PlanType.challenge:
        return 'تحدي قراءة مع هدف زمني محدد';
    }
  }

  IconData get icon {
    switch (this) {
      case PlanType.wantToRead:
        return Icons.bookmark_add;
      case PlanType.currentlyReading:
        return Icons.menu_book;
      case PlanType.completed:
        return Icons.check_circle;
      case PlanType.favorites:
        return Icons.favorite;
      case PlanType.custom:
        return Icons.create;
      case PlanType.challenge:
        return Icons.emoji_events;
    }
  }

  Color get color {
    switch (this) {
      case PlanType.wantToRead:
        return const Color(0xFF2196F3);
      case PlanType.currentlyReading:
        return const Color(0xFF4CAF50);
      case PlanType.completed:
        return const Color(0xFF8BC34A);
      case PlanType.favorites:
        return const Color(0xFFE91E63);
      case PlanType.custom:
        return const Color(0xFF9C27B0);
      case PlanType.challenge:
        return const Color(0xFFFF9800);
    }
  }
}
