import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_firebase_service.dart';
import 'services/book_service.dart';
import 'services/review_service.dart';
import 'screens/auth/simple_login_screen.dart';
import 'screens/home/home_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthFirebaseService()),
        ChangeNotifierProvider(create: (context) => BookService()),
        // Make ReviewService available for screens that need it
        ChangeNotifierProvider(create: (context) => ReviewService()),
      ],
      child: MaterialApp(
        title: 'كتاب - تطبيق قراءة الكتب الإلكترونية',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthFirebaseService>(
      builder: (context, authService, child) {
        if (authService.currentUser != null) {
          return const HomeScreen();
        } else {
          return const SimpleLoginScreen();
        }
      },
    );
  }
}
