import 'package:flutter/foundation.dart';

// نسخة مبسطة من خدمة المصادقة للاختبار
class SimpleAuthService extends ChangeNotifier {
  String? _currentUser;
  bool _isLoading = false;

  String? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  // محاكاة تسجيل الدخول
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // محاكاة انتظار الشبكة
    await Future.delayed(const Duration(seconds: 2));

    // محاكاة التحقق من بيانات الدخول
    if (email.isNotEmpty && password.length >= 6) {
      _currentUser = email;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // محاكاة إنشاء حساب جديد
  Future<bool> registerWithEmail(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();

    // محاكاة انتظار الشبكة
    await Future.delayed(const Duration(seconds: 2));

    // محاكاة إنشاء الحساب
    if (email.isNotEmpty && password.length >= 6 && name.isNotEmpty) {
      _currentUser = email;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
  }

  // إعادة تعيين كلمة المرور
  Future<bool> resetPassword(String email) async {
    // محاكاة إرسال بريد إعادة تعيين كلمة المرور
    await Future.delayed(const Duration(seconds: 1));
    return email.isNotEmpty;
  }
}
