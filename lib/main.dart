import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// تمت إزالة SimpleAuthService بعد الانتقال الكامل إلى Firebase Auth
import 'services/book_service.dart';
import 'services/book_repository.dart';
import 'services/auth_firebase_service.dart'; // الخدمة الموحدة للمصادقة
import 'services/review_service.dart';
import 'screens/auth/login_screen.dart'; // شاشة تسجيل الدخول المحسّنة
import 'screens/home/redesigned_home_screen.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';
import 'services/enhanced_plan_service.dart';
import 'services/plan_service.dart';
import 'services/reading_challenge_service.dart';
import 'screens/plans/enhanced_plans_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/library/enhanced_library_screen.dart';
import 'services/reading_list_service.dart';
import 'services/external_book_search_service.dart';
import 'screens/plans/plans_hub_screen.dart';
import 'utils/web_optimizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تحسينات خاصة بالويب والهواتف المحمولة
  if (kIsWeb) {
    // تحسين الأداء على الويب
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }
  
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
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: false,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        debugPrint('Firestore settings: disabled persistence on web with unlimited cache');
      } catch (e) {
        debugPrint('Failed to set Firestore settings: $e');
      }
    }
  } catch (e) {
    debugPrint('Firebase init skipped/failed: $e');
  }
  
  // تفعيل تحسينات الويب للهواتف المحمولة
  if (kIsWeb) {
    WebOptimizations.initialize();
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
        // خدمات الخطط والقوائم والبحث الخارجي
        ChangeNotifierProvider(create: (context) => PlanService()),
        ChangeNotifierProvider(create: (context) => ReadingListService()),
        ChangeNotifierProvider(create: (context) => ExternalBookSearchService()),
        ChangeNotifierProvider(create: (context) => EnhancedPlanService()),
        ChangeNotifierProvider(create: (context) => ReadingChallengeService()),
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
              '/home': (context) => const RedesignedHomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/plans': (context) => const PlansHubScreen(),
              '/enhanced-plans': (context) => const EnhancedPlansScreen(),
              '/search': (context) => const SearchScreen(),
              '/library': (context) => const EnhancedLibraryScreen(),
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
                      return const RedesignedHomeScreen();
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
