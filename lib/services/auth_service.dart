import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  
  // تسجيل الدخول بالإيميل وكلمة المرور
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return null; // نجح تسجيل الدخول
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    } catch (e) {
      return 'حدث خطأ غير متوقع';
    }
  }

  // إنشاء حساب جديد
  Future<String?> registerWithEmail(
    String email, 
    String password, 
    String displayName
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // تحديث اسم المستخدم
      await result.user?.updateDisplayName(displayName);
      
      // إنشاء ملف تعريف المستخدم في Firestore
      await _createUserProfile(result.user!, displayName);
      
      notifyListeners();
      return null; // نجح إنشاء الحساب
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    } catch (e) {
      return 'حدث خطأ غير متوقع';
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  // إرسال رابط إعادة تعيين كلمة المرور
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // تم إرسال الرابط بنجاح
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    } catch (e) {
      return 'حدث خطأ غير متوقع';
    }
  }

  // إنشاء ملف تعريف المستخدم في Firestore
  Future<void> _createUserProfile(User user, String displayName) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'favoriteBooks': [],
        'readingHistory': [],
      });
    } catch (e) {
      print('خطأ في إنشاء ملف تعريف المستخدم: $e');
    }
  }

  // الحصول على رسالة الخطأ باللغة العربية
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'لا يوجد مستخدم بهذا الإيميل';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'هذا الإيميل مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'invalid-email':
        return 'عنوان الإيميل غير صالح';
      case 'operation-not-allowed':
        return 'هذه العملية غير مسموحة';
      case 'too-many-requests':
        return 'تم تجاوز عدد المحاولات المسموحة';
      default:
        return 'حدث خطأ في المصادقة';
    }
  }

  // استمع لتغييرات حالة المصادقة
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
