import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // لـ ChangeNotifier
// (debugPrint replaced with print for simplicity)
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

/// خدمة مصادقة Firebase حقيقية (بديلة لـ SimpleAuthService)
class AuthFirebaseService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> signIn(String email, String password) async {
    if (!_isFirebaseConfigured()) {
      return 'Firebase غير مكوّن. شغّل "flutterfire configure" وحدث ملف firebase_options.dart';
    }
    try {
  print('[AuthFirebaseService] signIn attempt email=$email');
      await _auth.signInWithEmailAndPassword(email: email, password: password);
  print('[AuthFirebaseService] signIn success uid=${_auth.currentUser?.uid}');
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
  print('[AuthFirebaseService] signIn FirebaseAuthException code=${e.code} message=${e.message}');
      return _mapError(e.code);
    } catch (e) {
  print('[AuthFirebaseService] signIn unknown error: $e');
      return 'حدث خطأ غير متوقع';
    }
  }

  Future<String?> register(String email, String password, String name) async {
    if (!_isFirebaseConfigured()) {
      return 'Firebase غير مكوّن. شغّل "flutterfire configure" وحدث ملف firebase_options.dart';
    }
    try {
  print('[AuthFirebaseService] register attempt email=$email name=$name');
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await cred.user?.updateDisplayName(name);
      await _db.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'email': email,
        'displayName': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
  print('[AuthFirebaseService] register success uid=${cred.user?.uid}');
      // إرسال بريد تحقق إن أمكن
      try {
        if (cred.user != null && !cred.user!.emailVerified) {
          await cred.user!.sendEmailVerification();
        }
      } catch (_) {}
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
  print('[AuthFirebaseService] register FirebaseAuthException code=${e.code} message=${e.message}');
      return _mapError(e.code);
    } catch (e) {
  print('[AuthFirebaseService] register unknown error: $e');
      return 'حدث خطأ غير متوقع';
    }
  }

  /// إعادة تعيين كلمة المرور عبر البريد الإلكتروني
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // نجاح
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    } catch (e) {
      return 'حدث خطأ غير متوقع';
    }
  }

  bool _isFirebaseConfigured() {
    // Detect obvious placeholders in firebase_options.dart
    final opts = DefaultFirebaseOptions.currentPlatform;
  final key = opts.apiKey;
  final project = opts.projectId;
    if (key.isEmpty || project.isEmpty) return false;
    if (key.contains('API_KEY') || key.contains('WEB_API_KEY') || project.contains('YOUR_PROJECT_ID')) {
      return false;
    }
    return true;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'المستخدم غير موجود';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'البريد مستخدم مسبقاً';
      case 'invalid-email':
        return 'البريد غير صالح';
      case 'weak-password':
        return 'كلمة المرور ضعيفة';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقاً';
      default:
        return 'خطأ في المصادقة';
    }
  }
}
