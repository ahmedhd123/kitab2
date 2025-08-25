import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/public_challenge_service.dart';
import '../../services/auth_firebase_service.dart';
import '../../models/public_challenge_model.dart';
import '../../utils/design_tokens.dart';

class PublicDetailScreen extends StatelessWidget {
  final String challengeId;
  const PublicDetailScreen({super.key, required this.challengeId});

  @override
  Widget build(BuildContext context) {
    final svc = context.read<PublicChallengeService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل التحدي'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<PublicChallengeModel>(
        stream: svc.watchChallenge(challengeId),
        builder: (context, challengeSnap) {
          final challenge = challengeSnap.data;
          final ended = challenge != null && DateTime.now().isAfter(challenge.endAt);
          return StreamBuilder<List<ChallengeParticipant>>(
            stream: svc.watchParticipants(challengeId),
            builder: (context, snap) {
              final participants = snap.data ?? const <ChallengeParticipant>[];
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: participants.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  if (i == 0) return _Header(challengeId: challengeId, ended: ended);
                  final p = participants[i - 1];
                  final percent = p.progressPercent;
                  final color = percent >= 80
                      ? AppColors.success
                      : percent >= 50
                          ? AppColors.warning
                          : AppColors.secondary;
                  final msg = percent >= 80
                      ? 'مبروك! لقد أكملت ${percent.toStringAsFixed(0)}%'
                      : percent >= 50
                          ? 'أحسنت! وصلت إلى ${percent.toStringAsFixed(0)}%'
                          : 'استمر! نسبة التقدم ${percent.toStringAsFixed(0)}%';
                  return ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: Text(p.displayName ?? p.userId, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: percent / 100.0, color: color, backgroundColor: Colors.grey.shade200),
                        const SizedBox(height: 4),
                        Text('التقدم: ${percent.toStringAsFixed(0)}% — قرأ ${p.pagesRead}/${p.pagesTarget} صفحة'),
                        if (ended) Padding(padding: const EdgeInsets.only(top: 4), child: Text(msg, style: TextStyle(color: color))),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _Header extends StatefulWidget {
  final String challengeId;
  final bool ended;
  const _Header({required this.challengeId, required this.ended});
  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  final _pagesRead = TextEditingController();
  bool _saving = false;
  @override
  void dispose() {
    _pagesRead.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthFirebaseService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('تحديث تقدّمي', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              tooltip: 'نسخ رابط/رمز الدعوة',
              icon: const Icon(Icons.share),
              onPressed: () async {
                // عرض تلميح: الرمز موجود داخل الوثيقة الرئيسية؛ يمكن للمُنظم نسخه من شاشة الإنشاء.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('انسخ رمز الدعوة من شاشة إنشاء التحدي.')),
                );
              },
            )
          ],
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _pagesRead,
              decoration: const InputDecoration(labelText: 'عدد الصفحات المقروءة'),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _saving
                ? null
                : () async {
                    final n = int.tryParse(_pagesRead.text.trim());
                    if (n == null) return;
                    if (widget.ended) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('انتهى التحدي، لا يمكن التعديل.')));
                      return;
                    }
                    setState(() => _saving = true);
                    try {
                      await context.read<PublicChallengeService>().updateProgress(
                            challengeId: widget.challengeId,
                            userId: auth.currentUser?.uid ?? 'anonymous',
                            pagesRead: n,
                          );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ')));
                      }
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('حفظ'),
          )
        ]),
        const SizedBox(height: 12),
        const Divider(),
      ],
    );
  }
}
