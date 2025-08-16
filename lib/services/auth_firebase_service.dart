import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    } catch (_) {
      return 'حدث خطأ غير متوقع';
    }
  }

  Future<String?> register(String email, String password, String name) async {
    if (!_isFirebaseConfigured()) {
      return 'Firebase غير مكوّن. شغّل "flutterfire configure" وحدث ملف firebase_options.dart';
    }
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await cred.user?.updateDisplayName(name);
      await _db.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'email': email,
        'displayName': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    } catch (_) {
      return 'حدث خطأ غير متوقع';
    }
  }

  bool _isFirebaseConfigured() {
    // Detect obvious placeholders in firebase_options.dart
    final opts = DefaultFirebaseOptions.currentPlatform;
    final key = opts.apiKey ?? '';
    final project = opts.projectId ?? '';
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
