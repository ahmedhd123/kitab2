import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/plan_service.dart';
import '../../services/auth_firebase_service.dart';
import '../../models/reading_plan_model.dart';
import 'reading_lists_screen.dart';

class PlansHubScreen extends StatelessWidget {
  const PlansHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthFirebaseService>();
    final userId = auth.currentUser?.uid;
    final colorScheme = Theme.of(context).colorScheme;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text('يرجى تسجيل الدخول')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الخطط والقوائم'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    title: 'إنشاء خطة',
                    icon: Icons.flag_rounded,
                    color: colorScheme.primary,
                    onTap: () => _createQuickPlan(context, userId),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    title: 'قوائم القراءة',
                    icon: Icons.list_alt_rounded,
                    color: colorScheme.secondary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReadingListsScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: context.read<PlanService>().watchUserPlans(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final plans = snapshot.data ?? [];
                if (plans.isEmpty) {
                  return const Center(child: Text('لا توجد خطط بعد — ابدأ بإنشاء خطة جديدة'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: plans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _PlanTile(plan: plans[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createQuickPlan(BuildContext context, String userId) async {
    final controller = TextEditingController(text: 'خطة قراءة جديدة');
    final planService = context.read<PlanService>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('اسم الخطة', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: 'اكتب عنوان الخطة'),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final title = controller.text.trim();
                    if (title.isEmpty) return;
                    await planService.createPlan(
                      userId: userId,
                      title: title,
                      type: ReadingPlanType.custom,
                      goals: const [],
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('حفظ الخطة'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

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
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flag_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w700, color: color),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final ReadingPlanModel plan;
  const _PlanTile({required this.plan});

  @override
  Widget build(BuildContext context) {
    final color = switch (plan.status) {
      ReadingPlanStatus.active => Colors.green,
      ReadingPlanStatus.paused => Colors.orange,
      ReadingPlanStatus.done => Colors.blueGrey,
    };
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      title: Text(plan.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('أهداف: ${plan.goals.length} • الحالة: ${plan.status.name}'),
      leading: CircleAvatar(backgroundColor: color, child: const Icon(Icons.flag, color: Colors.white)),
    );
  }
}
