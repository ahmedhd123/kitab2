import 'package:flutter/material.dart';

/// نسخة محسّنة من توكنز التصميم مع ألوان وتأثيرات حديثة للمجتمع الرقمي للكتب
class EnhancedAppColors {
  // لوحة ألوان ديناميكية حديثة
  static const Color primary = Color(0xFF4F46E5); // بنفسجي حديث
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryContainer = Color(0xFFEDE9FE);
  
  static const Color secondary = Color(0xFFEC4899); // وردي ديناميكي
  static const Color secondaryLight = Color(0xFFF472B6);
  static const Color secondaryDark = Color(0xBE185D);
  static const Color secondaryContainer = Color(0xFFFCE7F3);
  
  static const Color accent = Color(0xFF10B981); // أخضر طبيعي
  static const Color accentLight = Color(0xFF34D399);
  static const Color accentDark = Color(0xFF059669);
  static const Color accentContainer = Color(0xFFD1FAE5);
  
  // ألوان المجتمع والتفاعل
  static const Color social = Color(0xFF7C3AED); // بنفسجي اجتماعي
  static const Color socialLight = Color(0xFFA855F7);
  static const Color socialContainer = Color(0xFFF3E8FF);
  
  static const Color community = Color(0xFFF59E0B); // برتقالي دافئ
  static const Color communityLight = Color(0xFFFBBF24);
  static const Color communityContainer = Color(0xFFFEF3C7);
  
  // ألوان الحالة مع تدرجات
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF6EE7B7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  
  // خلفيات متدرجة حديثة
  static const Color surface = Color(0xFFFAFAFA);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF9FAFB);
  
  // درجات رمادية حديثة
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);
  
  // ألوان الفئات الأدبية المحسّنة
  static const Map<String, List<Color>> categoryGradients = {
    'الأدب': [Color(0xFFFF6B6B), Color(0xFFFF8787)], // أحمر دافئ
    'العلوم': [Color(0xFF4ECDC4), Color(0xFF44A08D)], // تركوازي
    'التاريخ': [Color(0xFF6C5CE7), Color(0xFFA29BFE)], // بنفسجي
    'الفلسفة': [Color(0xFFE17055), Color(0xFFEF4444)], // برتقالي محمر
    'التكنولوجيا': [Color(0xFF0984E3), Color(0xFF74B9FF)], // أزرق تقني
    'الدين': [Color(0xFF00B894), Color(0xFF55EFC4)], // أخضر روحاني
    'الطبخ': [Color(0xFFE67E22), Color(0xFFF39C12)], // برتقالي طبخ
    'الرياضة': [Color(0xFF6C5CE7), Color(0xFF74B9FF)], // بنفسجي أزرق
    'الرومانسية': [Color(0xFFE84393), Color(0xFFFD79A8)], // وردي رومانسي
    'الإثارة': [Color(0xFF636E72), Color(0xFFB2BEC3)], // رمادي مثير
    'الأطفال': [Color(0xFFFFDD59), Color(0xFFFFB74D)], // أصفر مرح
    'التنمية الذاتية': [Color(0xFF1DD1A1), Color(0xFF55EFC4)], // أخضر تطوير
  };
  
  // ألوان التقييم والمراجعة
  static const Color rating1 = Color(0xFFEF4444); // ضعيف
  static const Color rating2 = Color(0xFFF97316); // مقبول
  static const Color rating3 = Color(0xFFEAB308); // جيد
  static const Color rating4 = Color(0xFF22C55E); // ممتاز
  static const Color rating5 = Color(0xFF10B981); // رائع
  
  // ألوان التفاعل الاجتماعي
  static const Color like = Color(0xFFEF4444);
  static const Color share = Color(0xFF3B82F6);
  static const Color comment = Color(0xFF8B5CF6);
  static const Color follow = Color(0xFF10B981);
}

class EnhancedGradients {
  // تدرجات جذابة للخلفيات
  static const Gradient primaryGradient = LinearGradient(
    colors: [EnhancedAppColors.primary, EnhancedAppColors.primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient socialGradient = LinearGradient(
    colors: [EnhancedAppColors.social, EnhancedAppColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient communityGradient = LinearGradient(
    colors: [EnhancedAppColors.community, EnhancedAppColors.accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient glassmorphism = LinearGradient(
    colors: [
      Color(0x20FFFFFF),
      Color(0x10FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // تدرجات الكتب حسب الفئة
  static Gradient getCategoryGradient(String category) {
    final colors = EnhancedAppColors.categoryGradients[category] ?? 
        [EnhancedAppColors.gray400, EnhancedAppColors.gray500];
    return LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

class EnhancedShadows {
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get strong => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];
  
  static List<BoxShadow> get glow => [
    BoxShadow(
      color: EnhancedAppColors.primary.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 0),
    ),
  ];
  
  // ظلال ملونة للكتب
  static List<BoxShadow> categoryGlow(String category) {
    final colors = EnhancedAppColors.categoryGradients[category];
    final color = colors?.first ?? EnhancedAppColors.gray400;
    return [
      BoxShadow(
        color: color.withOpacity(0.3),
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
    ];
  }
}

class EnhancedSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
}

class EnhancedRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double circular = 50;
}

class EnhancedTypography {
  // أحجام الخط الحديثة
  static const double displayLarge = 32;
  static const double displayMedium = 28;
  static const double displaySmall = 24;
  static const double headlineLarge = 22;
  static const double headlineMedium = 20;
  static const double headlineSmall = 18;
  static const double titleLarge = 16;
  static const double titleMedium = 14;
  static const double titleSmall = 12;
  static const double bodyLarge = 16;
  static const double bodyMedium = 14;
  static const double bodySmall = 12;
  static const double labelLarge = 14;
  static const double labelMedium = 12;
  static const double labelSmall = 10;
  
  // أوزان الخط
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
}

class EnhancedAnimations {
  // مدة الحركات
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 750);
  
  // منحنيات الحركة
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticOut = Curves.elasticOut;
}
