<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# تعليمات Copilot لمشروع قارئ الكتب

## نظرة عامة على المشروع
هذا تطبيق Flutter لقراءة الكتب الإلكترونية يدعم:
- PDF و EPUB reading
- نظام المصادقة باستخدام Firebase
- تقييم ومراجعة الكتب
- دعم كامل للغة العربية
- إدارة الحالة باستخدام Provider

## معايير الكود

### اللغة والتعليقات
- استخدم اللغة العربية في التعليقات والنصوص المعروضة للمستخدم
- اكتب أسماء المتغيرات والدوال بالإنجليزية
- استخدم تعليقات واضحة باللغة العربية

### بنية الكود
- اتبع معايير Flutter وDart الرسمية
- استخدم Provider لإدارة الحالة
- فصل منطق العمل عن واجهة المستخدم
- استخدم async/await للعمليات غير المتزامنة

### Firebase Integration
- استخدم Firebase Auth للمصادقة
- استخدم Cloud Firestore لقاعدة البيانات
- استخدم Firebase Storage لتخزين الملفات
- تطبق ممارسات الأمان الجيدة

### تصميم الواجهات
- استخدم Material Design 3
- تأكد من دعم اللغة العربية (RTL)
- اجعل التصميم responsive
- استخدم الألوان المحددة في app_theme.dart

### معالجة الأخطاء
- تطبيق try-catch في العمليات المهمة
- عرض رسائل خطأ واضحة للمستخدم
- التحقق من حالة null safety
- تطبيق validation للمدخلات

### قراءة الكتب
- استخدم flutter_pdfview للـ PDF
- استخدم epub_viewer للـ EPUB
- احفظ تقدم القراءة في Firestore
- تطبيق إعدادات القراءة المخصصة

### النماذج والخدمات
- استخدم النماذج الموجودة: BookModel, ReviewModel
- استخدم الخدمات: AuthService, BookService, ReviewService
- تطبيق validation في النماذج
- استخدم toMap() و fromFirestore() للتحويل

## أمثلة على الأكواد المفضلة

### إنشاء widget جديد:
```dart
class CustomWidget extends StatelessWidget {
  const CustomWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // تطبيق التصميم هنا
    );
  }
}
```

### استخدام Provider:
```dart
final authService = Provider.of<AuthService>(context, listen: false);
final bookService = Provider.of<BookService>(context);
```

### معالجة العمليات غير المتزامنة:
```dart
Future<void> _performAsyncOperation() async {
  try {
    setState(() {
      _isLoading = true;
    });
    
    // العملية هنا
    
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
```

## ما يجب تجنبه
- لا تستخدم hard-coded strings للنصوص المعروضة
- لا تتجاهل معالجة الأخطاء
- لا تستخدم setState في العمليات غير المتزامنة بدون التحقق من mounted
- لا تنس تطبيق dispose() للcontrollers
- لا تستخدم Navigator.push بدون معالجة الاستثناءات

## الملفات الرئيسية
- `lib/main.dart` - نقطة البداية
- `lib/services/` - خدمات Firebase والبيانات
- `lib/models/` - نماذج البيانات
- `lib/screens/` - واجهات المستخدم
- `lib/utils/app_theme.dart` - تصميم التطبيق

## التحقق من الجودة
- تأكد من عمل التطبيق مع البيانات الحقيقية والوهمية
- اختبر التطبيق مع حسابات مختلفة
- تأكد من عمل التطبيق في الوضع الليلي والنهاري
- اختبر على أحجام شاشات مختلفة
