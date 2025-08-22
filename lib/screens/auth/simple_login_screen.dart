import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_firebase_service.dart';

class SimpleLoginScreen extends StatefulWidget {
  const SimpleLoginScreen({super.key});

  @override
  State<SimpleLoginScreen> createState() => _SimpleLoginScreenState();
}

class _SimpleLoginScreenState extends State<SimpleLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final firebase = Provider.of<AuthFirebaseService>(context, listen: false);
    final err = await firebase.signIn(_emailController.text.trim(), _passwordController.text);
    if (err != null && mounted) {
      _showError(err);
      return;
    }
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _showError(String msg) {
    if (!mounted) return; // تجنب استخدام context بعد التخلص من الودجت
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Text('SimpleLoginScreen', style: TextStyle(fontSize: 24, color: Colors.red)),
            Expanded(
              child: Consumer<AuthFirebaseService>(
                builder: (context, firebaseAuth, child) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // شعار التطبيق
                            Icon(
                              Icons.menu_book,
                              size: 80,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'مرحباً بك في تطبيق كتاب',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'اكتشف وقرأ واستمتع بأفضل الكتب الإلكترونية',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),
                            // حقل البريد الإلكتروني
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'البريد الإلكتروني',
                                prefixIcon: Icon(Icons.email),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'يرجى إدخال البريد الإلكتروني';
                                }
                                if (!value.contains('@')) {
                                  return 'يرجى إدخال بريد إلكتروني صحيح';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // حقل كلمة المرور
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _isObscured,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _signIn(),
                              decoration: InputDecoration(
                                labelText: 'كلمة المرور',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () {
                                    setState(() {
                                      _isObscured = !_isObscured;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'يرجى إدخال كلمة المرور';
                                }
                                if (value.length < 6) {
                                  return 'كلمة المرور يجب أن تكون أكثر من 6 أحرف';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            // زر تسجيل الدخول
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _signIn,
                                child: const Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // رابط إنشاء حساب جديد
                            TextButton(
                              onPressed: () {
                                _showRegisterDialog(context);
                              },
                              child: const Text('إنشاء حساب جديد'),
                            ),
                            const SizedBox(height: 16),
                            // معلومات للاختبار
                            // تمت إزالة ملاحظات اختبار SimpleAuthService
                          ],
                        ), // end inner Column
                      ), // end Form
                    ), // end SingleChildScrollView
                  ); // end Center
                }, // end builder
              ), // end Consumer
            ), // end Expanded
          ],
        ),
      ),
    );
  }

  void _showRegisterDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إنشاء حساب جديد'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال الاسم';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال البريد الإلكتروني';
                  }
                  if (!value.contains('@')) {
                    return 'يرجى إدخال بريد إلكتروني صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال كلمة المرور';
                  }
                  if (value.length < 6) {
                    return 'كلمة المرور يجب أن تكون أكثر من 6 أحرف';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final firebase = Provider.of<AuthFirebaseService>(context, listen: false);
                final err = await firebase.register(
                  emailController.text.trim(),
                  passwordController.text,
                  nameController.text.trim(),
                );
                if (err != null && context.mounted) {
                  _showError(err);
                } else if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              }
            },
            child: const Text('إنشاء الحساب'),
          ),
        ],
      ),
    );
  }
}
