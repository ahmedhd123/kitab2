import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// تمت إزالة SimpleAuthService بعد الانتقال الكامل إلى Firebase Auth
import 'services/book_service.dart';
import 'services/book_repository.dart';
import 'services/auth_firebase_service.dart'; // الخدمة الموحدة للمصادقة
import 'services/review_service.dart';
import 'screens/auth/login_screen.dart'; // شاشة تسجيل الدخول المحسّنة
import 'screens/home/home_screen.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تهيئة Firebase (Placeholders حالياً حتى يتم استبدال القيم عبر flutterfire configure)
  try {
    // على أندرويد، سنعتمد على الضبط الأصلي من google-services.json
    // وعلى المنصات الأخرى نستخدم DefaultFirebaseOptions
    if (defaultTargetPlatform == TargetPlatform.android) {
      await Firebase.initializeApp();
    } else {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
    // On web, IndexedDB/persistence can be unavailable (incognito, restricted envs).
    // Disable persistence to avoid the "client is offline" errors when IndexedDB isn't usable.
    if (kIsWeb) {
      try {
        FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
        debugPrint('Firestore settings: disabled persistence on web');
      } catch (e) {
        debugPrint('Failed to set Firestore settings: $e');
      }
    }
  } catch (e) {
    debugPrint('Firebase init skipped/failed: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthFirebaseService()),
        ChangeNotifierProvider(create: (context) => BookService(repository: BookRepository())),
        ChangeNotifierProvider(create: (context) => ThemeService()),
        // Register ReviewService so screens can read/write reviews via Provider
        ChangeNotifierProvider(create: (context) => ReviewService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'كتاب - تطبيق قراءة الكتب الإلكترونية',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ar'),
              Locale('en'),
            ],
            locale: const Locale('ar'),
            builder: (context, child) {
              return Directionality(textDirection: TextDirection.rtl, child: child!);
            },
            // Named routes used by various screens (SplashScreen and auth flows)
            routes: {
              '/home': (context) => const HomeScreen(),
              '/login': (context) => const LoginScreen(),
            },
            debugShowCheckedModeBanner: false,
            home: Builder(
              builder: (context) {
                final auth = Provider.of<AuthFirebaseService>(context, listen: false);
                return StreamBuilder(
                  // تجنّب الانتظار اللانهائي في حال تعذّر تهيئة Firebase أو انقطاع الشبكة
                  // بعد 5 ثوانٍ سنعتبر أن المستخدم غير مسجّل دخول ونعرض شاشة تسجيل الدخول
                  stream: auth.authStateChanges.timeout(
                    const Duration(seconds: 5),
                    onTimeout: (sink) {
                      // ادفع قيمة null لتوجيه المستخدم لشاشة تسجيل الدخول
                      sink.add(null);
                    },
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SplashScreen();
                    }
                    if (snapshot.hasData) {
                      return const HomeScreen();
                    } else {
                      return const LoginScreen();
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// AuthWrapper القديم تمت إزالته؛ الاعتماد الآن على SplashScreen و Firebase Auth
