import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/public_challenge_service.dart';
import '../../services/auth_firebase_service.dart';
import '../../models/public_challenge_model.dart';
import '../../utils/design_tokens.dart';

class PublicJoinScreen extends StatefulWidget {
  const PublicJoinScreen({super.key});
  @override
  State<PublicJoinScreen> createState() => _PublicJoinScreenState();
}

class _PublicJoinScreenState extends State<PublicJoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _token = TextEditingController();
  final _durationDays = TextEditingController(text: '30');

  // كتاب واحد كبداية؛ يمكن توسيعها لاحقاً لإضافة أكثر من كتاب
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _cover = TextEditingController();
  final _pages = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _token.dispose();
    _durationDays.dispose();
    _title.dispose();
    _author.dispose();
    _cover.dispose();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الانضمام لتحدي'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('أدخل رمز الدعوة الذي وصلك:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _token,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.vpn_key), hintText: 'رمز الدعوة'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل الرمز' : null,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('الكتب المشاركة (أدخل كتاباً إن لم يوجد في المكتبة):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'اسم الكتاب'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل اسم الكتاب' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(controller: _author, decoration: const InputDecoration(labelText: 'اسم المؤلف')),
              const SizedBox(height: 8),
              TextFormField(controller: _cover, decoration: const InputDecoration(labelText: 'رابط صورة الغلاف')), 
              const SizedBox(height: 8),
              TextFormField(
                controller: _pages,
                decoration: const InputDecoration(labelText: 'عدد الصفحات'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'أدخل رقم صفحات صحيح';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationDays,
                decoration: const InputDecoration(labelText: 'مدة القراءة (أيام)'),
                keyboardType: TextInputType.number,
                validator: (v) => int.tryParse(v ?? '') == null ? 'أدخل رقم' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('انضم إلى التحدي'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final svc = context.read<PublicChallengeService>();
      final auth = context.read<AuthFirebaseService>();
      final books = [
        ChallengeBookEntry(
          title: _title.text.trim(),
          author: _author.text.trim().isEmpty ? null : _author.text.trim(),
          coverUrl: _cover.text.trim().isEmpty ? null : _cover.text.trim(),
          pages: int.parse(_pages.text.trim()),
        ),
      ];
      await svc.joinByInvite(
        inviteToken: _token.text.trim(),
        userId: auth.currentUser?.uid ?? 'anonymous',
        displayName: auth.currentUser?.displayName,
        books: books,
        durationDays: int.parse(_durationDays.text.trim()),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الانضمام بنجاح')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الانضمام: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
