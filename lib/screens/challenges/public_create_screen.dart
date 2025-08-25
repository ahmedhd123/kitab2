import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/public_challenge_service.dart';
import '../../services/auth_firebase_service.dart';
import '../../utils/design_tokens.dart';

class PublicCreateScreen extends StatefulWidget {
  const PublicCreateScreen({super.key});

  @override
  State<PublicCreateScreen> createState() => _PublicCreateScreenState();
}

class _PublicCreateScreenState extends State<PublicCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 30));
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحدي عام جديد'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'اسم التحدي'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل الاسم' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'الوصف'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DateTile(
                      label: 'البداية',
                      date: _start,
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _start,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setState(() => _start = d);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateTile(
                      label: 'النهاية',
                      date: _end,
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _end,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setState(() => _end = d);
                      },
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('إنشاء ومشاركة الرابط'),
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
      final auth = context.read<AuthFirebaseService>();
      final svc = context.read<PublicChallengeService>();
      final c = await svc.createPublicChallenge(
        ownerId: auth.currentUser?.uid ?? 'anonymous',
        title: _title.text.trim(),
        description: _desc.text.trim(),
        startAt: _start,
        endAt: _end,
      );
      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('تم إنشاء التحدي'),
            content: SelectableText('رمز الدعوة: ${c.inviteToken}\nشارك هذا الرمز لينضم الآخرون.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateTile({required this.label, required this.date, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(label),
      subtitle: Text('${date.year}-${date.month}-${date.day}'),
      trailing: const Icon(Icons.date_range),
      onTap: onTap,
    );
  }
}
