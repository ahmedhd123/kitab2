import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/public_challenge_service.dart';
import '../../services/auth_firebase_service.dart';
import '../../utils/design_tokens.dart';
import 'public_create_screen.dart';
import 'public_join_screen.dart';
import 'public_detail_screen.dart';

class PublicChallengesScreen extends StatefulWidget {
  const PublicChallengesScreen({super.key});

  @override
  State<PublicChallengesScreen> createState() => _PublicChallengesScreenState();
}

class _PublicChallengesScreenState extends State<PublicChallengesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PublicChallengeService>().loadActiveChallenges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<PublicChallengeService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحديات القراءة (العامة)'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'انضمام برمز',
            icon: const Icon(Icons.group_add),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PublicJoinScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PublicCreateScreen())),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('تحدي عام جديد'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: svc.publicChallenges.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final c = svc.publicChallenges[i];
          final days = c.daysLeft;
          return ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(c.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(days >= 0 ? 'متبقٍ $days يوم' : 'انتهى', style: const TextStyle(color: AppColors.primary)),
            ),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicDetailScreen(challengeId: c.id))),
          );
        },
      ),
    );
  }
}
