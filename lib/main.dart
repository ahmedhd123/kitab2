import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// تمت إزالة SimpleAuthService بعد الانتقال الكامل إلى Firebase Auth
import 'services/book_service.dart';
import 'services/book_repository.dart';
import 'services/auth_firebase_service.dart';
import 'screens/auth/simple_login_screen.dart';
import 'screens/home/home_screen.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تهيئة Firebase (Placeholders حالياً حتى يتم استبدال القيم عبر flutterfire configure)
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
              '/login': (context) => const SimpleLoginScreen(),
            },
            debugShowCheckedModeBanner: false,
            home: Builder(
              builder: (context) {
                final auth = Provider.of<AuthFirebaseService>(context, listen: false);
                return StreamBuilder(
                  stream: auth.authStateChanges,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SplashScreen();
                    }
                    if (snapshot.hasData) {
                      return const HomeScreen();
                    } else {
                      return const SimpleLoginScreen();
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
