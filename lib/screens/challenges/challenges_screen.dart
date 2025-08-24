import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reading_plan_model.dart';
import '../../services/auth_service.dart';
import '../../services/reading_challenge_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/design_tokens.dart';
import 'create_challenge_screen.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChallenges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadChallenges() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      final challengeService = Provider.of<ReadingChallengeService>(context, listen: false);
      challengeService.loadUserChallenges(authService.currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحديات القراءة'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'النشطة'),
            Tab(text: 'المكتملة'),
            Tab(text: 'المتوقفة'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateChallengeScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('تحدي جديد'),
      ),
      body: Consumer<ReadingChallengeService>(
        builder: (context, challengeService, child) {
          final challenges = challengeService.challenges;
          
          if (challenges.isEmpty) {
            return _buildEmptyState();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildChallengesList(
                challenges.where((c) => c.status == ReadingPlanStatus.active).toList(),
                'لا توجد تحديات نشطة',
              ),
              _buildChallengesList(
                challenges.where((c) => c.status == ReadingPlanStatus.done).toList(),
                'لا توجد تحديات مكتملة',
              ),
              _buildChallengesList(
                challenges.where((c) => c.status == ReadingPlanStatus.paused).toList(),
                'لا توجد تحديات متوقفة',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.emoji_events,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'لا توجد تحديات بعد!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: 12),
            
            const Text(
              'ابدأ رحلتك في القراءة بإنشاء تحدي قراءة شخصي وحدد أهدافك',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateChallengeScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('إنشاء تحدي جديد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengesList(List<ReadingPlanModel> challenges, String emptyMessage) {
    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bookmark_border,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return _buildChallengeCard(challenge);
      },
    );
  }

  Widget _buildChallengeCard(ReadingPlanModel challenge) {
    final progress = challenge.challengeProgress;
    final completedBooks = challenge.completedBooks ?? 0;
    final targetBooks = challenge.targetBooks ?? 0;
    final progressPercent = (progress * 100).round();
    
    // حساب الأيام المتبقية
    final now = DateTime.now();
    final endDate = challenge.endAt ?? DateTime(now.year, 12, 31);
    final daysRemaining = endDate.difference(now).inDays;
    
    // تحديد اللون حسب حالة التحدي
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (challenge.status) {
      case ReadingPlanStatus.active:
        statusColor = AppColors.success;
        statusText = 'نشط';
        statusIcon = Icons.play_circle_filled;
        break;
      case ReadingPlanStatus.done:
        statusColor = AppColors.primary;
        statusText = 'مكتمل';
        statusIcon = Icons.check_circle;
        break;
      case ReadingPlanStatus.paused:
        statusColor = AppColors.warning;
        statusText = 'متوقف';
        statusIcon = Icons.pause_circle_filled;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان والحالة
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (challenge.year != null)
                        Text(
                          'سنة ${challenge.year}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // التقدم
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'التقدم: $completedBooks من $targetBooks كتاب',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$progressPercent%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        minHeight: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // معلومات إضافية
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  daysRemaining > 0 
                      ? '$daysRemaining أيام متبقية'
                      : challenge.status == ReadingPlanStatus.done 
                          ? 'تم الإنجاز!' 
                          : 'انتهت المدة',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                if (challenge.status == ReadingPlanStatus.active) ...[
                  IconButton(
                    onPressed: () => _updateProgress(challenge),
                    icon: const Icon(Icons.add_circle),
                    color: AppColors.success,
                    tooltip: 'تحديث التقدم',
                  ),
                  IconButton(
                    onPressed: () => _pauseChallenge(challenge),
                    icon: const Icon(Icons.pause_circle),
                    color: AppColors.warning,
                    tooltip: 'إيقاف التحدي',
                  ),
                ],
                if (challenge.status == ReadingPlanStatus.paused) ...[
                  IconButton(
                    onPressed: () => _resumeChallenge(challenge),
                    icon: const Icon(Icons.play_circle),
                    color: AppColors.success,
                    tooltip: 'استئناف التحدي',
                  ),
                ],
                IconButton(
                  onPressed: () => _deleteChallenge(challenge),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  tooltip: 'حذف التحدي',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProgress(ReadingPlanModel challenge) async {
    final controller = TextEditingController(
      text: (challenge.completedBooks ?? 0).toString(),
    );
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تحديث التقدم'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('كم كتاباً أنجزت في تحدي "${challenge.title}"؟'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'عدد الكتب المنجزة',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final books = int.tryParse(controller.text);
                if (books != null && books >= 0) {
                  Navigator.pop(context, books);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
    
    if (result != null) {
      final challengeService = Provider.of<ReadingChallengeService>(context, listen: false);
      await challengeService.updateChallengeProgress(challenge.id, result);
      
      if (result >= (challenge.targetBooks ?? 0)) {
        await challengeService.updateChallengeStatus(challenge.id, ReadingPlanStatus.done);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 تهانينا! لقد حققت هدفك في التحدي!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
    
    controller.dispose();
  }

  Future<void> _pauseChallenge(ReadingPlanModel challenge) async {
    final challengeService = Provider.of<ReadingChallengeService>(context, listen: false);
    await challengeService.updateChallengeStatus(challenge.id, ReadingPlanStatus.paused);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إيقاف التحدي')),
      );
    }
  }

  Future<void> _resumeChallenge(ReadingPlanModel challenge) async {
    final challengeService = Provider.of<ReadingChallengeService>(context, listen: false);
    await challengeService.updateChallengeStatus(challenge.id, ReadingPlanStatus.active);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم استئناف التحدي')),
      );
    }
  }

  Future<void> _deleteChallenge(ReadingPlanModel challenge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف التحدي'),
          content: Text('هل أنت متأكد من حذف تحدي "${challenge.title}"؟\nلن تتمكن من استرداده.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      final challengeService = Provider.of<ReadingChallengeService>(context, listen: false);
      await challengeService.deleteChallenge(challenge.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف التحدي')),
        );
      }
    }
  }
}

