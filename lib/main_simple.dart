import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/simple_auth_service.dart';
import 'services/book_service.dart';
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
        ChangeNotifierProvider(create: (context) => SimpleAuthService()),
        ChangeNotifierProvider(create: (context) => BookService()),
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
    return Consumer<SimpleAuthService>(
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
