import 'package:flutter/material.dart';

/// توكنز التصميم العامة للتطبيق (ألوان، مسافات، أنماط الحواف، الظلال)
/// يساعد هذا الفصل على الحفاظ على اتساق التصميم وإعادة الاستخدام.
class AppColors {
  // لوحة أساسية حديثة (أخضر معتدل + درجات رمادية دافئة)
  static const Color primary = Color(0xFF1E7F50); // أخضر حداثي
  static const Color primaryContainer = Color(0xFFDCF6E9);
  static const Color secondary = Color(0xFF146C94); // أزرق مخضر ناعم
  static const Color secondaryContainer = Color(0xFFE0F2FF);
  static const Color danger = Color(0xFFD84343);
  static const Color warning = Color(0xFFF6A700);
  static const Color success = Color(0xFF2E7D32);
  static const Color info = Color(0xFF2F6ED8);

  // محايد
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF7F9FA);
  static const Color neutral100 = Color(0xFFF0F2F4);
  static const Color neutral200 = Color(0xFFE2E6E9);
  static const Color neutral300 = Color(0xFFCBD3D9);
  static const Color neutral400 = Color(0xFFA7B2BC);
  static const Color neutral500 = Color(0xFF7B8792);
  static const Color neutral600 = Color(0xFF5B6670);
  static const Color neutral700 = Color(0xFF424A52);
  static const Color neutral800 = Color(0xFF2B3136);
  static const Color neutral900 = Color(0xFF161A1D);

  // خريطة ألوان للفئات (للاستعمال في الشارات أو الخلفيات التدريجية)
  static const Map<String, Color> categoryColors = {
    'الأدب': Color(0xFFE57C2F),
    'العلوم': Color(0xFF2F7DE5),
    'التاريخ': Color(0xFF8C54D9),
    'الفلسفة': Color(0xFFDB5068),
    'التكنولوجيا': Color(0xFF159D86),
    'الدين': Color(0xFF2E8B57),
    'الطبخ': Color(0xFFB26B35),
    'الرياضة': Color(0xFF5468FF),
  };
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
}

class AppShadows {
  static List<BoxShadow> subtle = [
    BoxShadow(
      color: Colors.black.withOpacity(.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevated = [
    BoxShadow(
      color: Colors.black.withOpacity(.07),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}
