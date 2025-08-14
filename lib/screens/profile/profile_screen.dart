import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // معلومات المستخدم
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.displayName ?? 'مستخدم',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    if (user != null && !user.emailVerified) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'يرجى التحقق من بريدك الإلكتروني',
                                style: TextStyle(color: Colors.orange[700]),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await authService.sendEmailVerification();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم إرسال رسالة التحقق'),
                                    ),
                                  );
                                }
                              },
                              child: const Text('إرسال'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // خيارات الملف الشخصي
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.book),
                    title: const Text('كتبي'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      // TODO: انتقال لصفحة كتب المستخدم
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('سجل القراءة'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      // TODO: انتقال لصفحة سجل القراءة
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.star),
                    title: const Text('مراجعاتي'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      // TODO: انتقال لصفحة مراجعات المستخدم
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // الإعدادات
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('الإعدادات'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      // TODO: انتقال لصفحة الإعدادات
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('المساعدة'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      // TODO: انتقال لصفحة المساعدة
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('حول التطبيق'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'قارئ الكتب',
                        applicationVersion: '1.0.0',
                        children: [
                          const Text('تطبيق لقراءة الكتب الإلكترونية وتقييمها'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // زر تسجيل الخروج
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // تأكيد تسجيل الخروج
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('تأكيد تسجيل الخروج'),
                      content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('إلغاء'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('تسجيل الخروج'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await authService.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('تسجيل الخروج'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
