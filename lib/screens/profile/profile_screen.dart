import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_firebase_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthFirebaseService>(context);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        automaticallyImplyLeading: false,
        actions: [
          if (user != null)
            IconButton(
              tooltip: 'تعديل الملف',
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditProfileSheet(context, auth),
            ),
        ],
      ),
      body: user == null
          ? _buildLoggedOutState(context)
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() ?? {};
                final displayName = data['displayName'] as String? ?? user.displayName ?? 'مستخدم';
                final email = user.email ?? '';
                final photoURL = data['photoURL'] as String? ?? user.photoURL;
                final bio = data['bio'] as String? ?? '';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // معلومات المستخدم
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomLeft,
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Theme.of(context).primaryColor,
                                    backgroundImage: (photoURL != null && photoURL.isNotEmpty)
                                        ? NetworkImage(photoURL)
                                        : null,
                                    child: (photoURL == null || photoURL.isEmpty)
                                        ? Text(
                                            (displayName.isNotEmpty ? displayName[0] : 'U').toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 32,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    child: InkWell(
                                      onTap: () => _changeAvatar(context, auth),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.all(6),
                                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                displayName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                email,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                              if (bio.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  bio,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                )
                              ],
                              if (!user.emailVerified) ...[
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
                                          await auth.sendEmailVerification();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('تم إرسال رسالة التحقق')),
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
                              leading: const Icon(Icons.person_outline),
                              title: const Text('تعديل المعلومات'),
                              trailing: const Icon(Icons.chevron_left),
                              onTap: () => _showEditProfileSheet(context, auth),
                            ),
                            const Divider(),
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
                                  children: const [
                                    Text('تطبيق لقراءة الكتب الإلكترونية وتقييمها'),
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
                              await auth.signOut();
                              if (context.mounted) {
                                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
                );
              },
            ),
    );
  }

  Widget _buildLoggedOutState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 80, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('يرجى تسجيل الدخول لعرض ملفك الشخصي'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false),
            child: const Text('تسجيل الدخول'),
          )
        ],
      ),
    );
  }

  Future<void> _changeAvatar(BuildContext context, AuthFirebaseService auth) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false, withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر قراءة الملف')));
        }
        return;
      }
    final ext = (file.extension ?? '').toLowerCase();
    final contentType = ext == 'png'
      ? 'image/png'
      : ext == 'webp'
        ? 'image/webp'
        : 'image/jpeg';
      final err = await auth.uploadAvatarBytes(bytes, contentType: contentType);
      if (context.mounted) {
        if (err == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الصورة')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    }
  }

  Future<void> _showEditProfileSheet(BuildContext context, AuthFirebaseService auth) async {
    final user = auth.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};
    final nameController = TextEditingController(text: data['displayName'] as String? ?? user.displayName ?? '');
    final bioController = TextEditingController(text: data['bio'] as String? ?? '');
    final formKey = GlobalKey<FormState>();

    // ignore: use_build_context_synchronously
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('تعديل الملف الشخصي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'الاسم'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bioController,
                  decoration: const InputDecoration(labelText: 'نبذة مختصرة'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final err = await auth.updateProfile(
                        displayName: nameController.text.trim(),
                        bio: bioController.text.trim(),
                      );
                      if (ctx.mounted) {
                        if (err == null) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث البيانات')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                        }
                      }
                    },
                    child: const Text('حفظ'),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
