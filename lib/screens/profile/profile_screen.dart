import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_firebase_service.dart';
import 'my_reviews_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthFirebaseService>();
    final user = auth.currentUser;

    if (user == null) {
      return Scaffold(appBar: AppBar(title: const Text('الملف الشخصي')), body: _buildLoggedOutState(context));
    }

    final userDocStream = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'تعديل الملف',
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileSheet(context, auth),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userDocStream,
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? {};
          final displayName = (data['displayName'] as String?)?.trim().isNotEmpty == true
              ? (data['displayName'] as String)
              : (user.displayName ?? 'مستخدم');
          final email = user.email ?? '';
          final photoURL = (data['photoURL'] as String?)?.isNotEmpty == true ? data['photoURL'] as String : user.photoURL;
          final bio = data['bio'] as String? ?? '';

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HeaderCard(
                  name: displayName,
                  email: email,
                  photoURL: photoURL,
                  bio: bio,
                  onChangeAvatar: () => _changeAvatar(context, auth),
                  emailVerified: user.emailVerified,
                  onVerifyEmail: auth.sendEmailVerification,
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 12)),
              // إحصاءات سريعة حيّة
              SliverToBoxAdapter(
                child: _LiveStatsRow(userId: user.uid),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              SliverToBoxAdapter(child: _QuickActions()),
              SliverToBoxAdapter(child: const SizedBox(height: 24)),
              // إعدادات/مساعدة
      SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    _SettingsTile(icon: Icons.settings, title: 'الإعدادات', onTap: () {}),
                    const Divider(height: 0),
        _SettingsTile(icon: Icons.help_outline, title: 'المساعدة', onTap: () {}),
                    const Divider(height: 0),
                    _SettingsTile(
                      icon: Icons.info_outline,
                      title: 'حول التطبيق',
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'قارئ الكتب',
                          applicationVersion: '1.0.0',
                          children: const [Text('تطبيق لقراءة الكتب الإلكترونية وتقييمها')],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _SettingsTile(
                      icon: Icons.reviews,
                      title: 'مراجعاتي',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
                      ),
                    ),
                    const Divider(height: 0),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('تأكيد تسجيل الخروج'),
                              content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
                                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('تسجيل الخروج')),
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
                        icon: const Icon(Icons.logout),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 14)),
                        label: const Text('تسجيل الخروج'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
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
  final nameController = TextEditingController(text: (data['displayName'] as String?) ?? (user.displayName ?? ''));
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

class _HeaderCard extends StatelessWidget {
  final String name;
  final String email;
  final String? photoURL;
  final String bio;
  final VoidCallback onChangeAvatar;
  final bool emailVerified;
  final Future<void> Function() onVerifyEmail;

  const _HeaderCard({
    required this.name,
    required this.email,
    required this.photoURL,
    required this.bio,
    required this.onChangeAvatar,
    required this.emailVerified,
    required this.onVerifyEmail,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [cs.primary.withOpacity(0.10), cs.secondary.withOpacity(0.10)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.primary.withOpacity(0.15)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: cs.primary,
                  backgroundImage: (photoURL != null && photoURL!.isNotEmpty) ? NetworkImage(photoURL!) : null,
                  child: (photoURL == null || photoURL!.isEmpty)
                      ? Text(name.isNotEmpty ? name.characters.first.toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold))
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: InkWell(
                    onTap: onChangeAvatar,
                    child: Container(
                      decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(bio, textAlign: TextAlign.center),
            ],
            if (!emailVerified) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Icon(Icons.warning, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('يرجى التحقق من بريدك الإلكتروني')),
                  TextButton(onPressed: onVerifyEmail, child: const Text('إرسال')),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LiveStatsRow extends StatelessWidget {
  final String userId;
  const _LiveStatsRow({required this.userId});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final plans$ = db.collection('reading_plans').where('userId', isEqualTo: userId).snapshots();
    final lists$ = db.collection('reading_lists').where('userId', isEqualTo: userId).snapshots();
    final reviews$ = db.collection('reviews').where('userId', isEqualTo: userId).snapshots();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _CountCard(stream: plans$, label: 'الخطط', icon: Icons.flag_rounded, color: Colors.teal)),
          const SizedBox(width: 8),
          Expanded(child: _CountCard(stream: lists$, label: 'القوائم', icon: Icons.list_alt_rounded, color: Colors.indigo)),
          const SizedBox(width: 8),
          Expanded(child: _CountCard(stream: reviews$, label: 'المراجعات', icon: Icons.reviews, color: Colors.purple)),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final String label;
  final IconData icon;
  final Color color;

  const _CountCard({
    required this.stream,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Material(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                  Text('$count عنصر', style: Theme.of(context).textTheme.bodySmall),
                ])
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              color: cs.primary,
              icon: Icons.flag_rounded,
              label: 'إنشاء خطة',
              onTap: () => Navigator.pushNamed(context, '/plans'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              color: cs.secondary,
              icon: Icons.list_alt_rounded,
              label: 'قوائم القراءة',
              onTap: () => Navigator.pushNamed(context, '/plans'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.color, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_left),
      onTap: onTap,
    );
  }
}
