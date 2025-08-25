import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/reading_challenge_service.dart';
import '../../utils/design_tokens.dart';
import 'create_challenge_screen.dart';

/// شاشة أهداف القراءة (الاسم الجديد للشاشة القديمة)
class ReadingGoalsScreen extends StatelessWidget {
  const ReadingGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = Provider.of<ReadingChallengeService>(context);
    final items = svc.challenges;
    return Scaffold(
      appBar: AppBar(
        title: const Text('أهداف القراءة'),
  backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
  onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateChallengeScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('هدف جديد'),
  backgroundColor: AppColors.primary,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) {
          final c = items[i];
          final percent = (c.challengeProgress * 100).toStringAsFixed(0);
          return ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                LinearProgressIndicator(value: c.challengeProgress),
                const SizedBox(height: 4),
                Text('التقدم: $percent%')
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: items.length,
      ),
    );
  }
}
