import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enhanced_reading_plan_model.dart';
import '../../models/book_model.dart';
import '../../services/enhanced_plan_service.dart';
import '../../services/auth_firebase_service.dart';
import '../../services/book_service.dart';
import '../../utils/enhanced_design_tokens.dart';
import '../../widgets/enhanced_book_cards.dart';

class EnhancedPlansScreen extends StatefulWidget {
  const EnhancedPlansScreen({super.key});

  @override
  State<EnhancedPlansScreen> createState() => _EnhancedPlansScreenState();
}

class _EnhancedPlansScreenState extends State<EnhancedPlansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPlans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadPlans() {
    final auth = Provider.of<AuthFirebaseService>(context, listen: false);
    final planService = Provider.of<EnhancedPlanService>(context, listen: false);
    
    if (auth.currentUser != null) {
      planService.loadUserPlans(auth.currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            _PlansOverviewTab(),
            _MyPlansTab(),
            _ReadingStatsTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePlanDialog(),
        backgroundColor: EnhancedAppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'خطة جديدة',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: EnhancedAppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'خطط القراءة',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: EnhancedGradients.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(EnhancedSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Consumer<EnhancedPlanService>(
                    builder: (context, planService, _) {
                      final stats = planService.getReadingStats();
                      return _buildQuickStats(stats);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        onTap: (index) => setState(() => _selectedTabIndex = index),
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(text: 'نظرة عامة', icon: Icon(Icons.dashboard)),
          Tab(text: 'خططي', icon: Icon(Icons.list)),
          Tab(text: 'الإحصائيات', icon: Icon(Icons.analytics)),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ReadingStats stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard(
          icon: Icons.flag,
          value: '${stats.totalPlans}',
          label: 'خطط نشطة',
        ),
        _buildStatCard(
          icon: Icons.menu_book,
          value: '${stats.totalBooks}',
          label: 'كتاب',
        ),
        _buildStatCard(
          icon: Icons.check_circle,
          value: '${stats.completedBooks}',
          label: 'مكتمل',
        ),
        _buildStatCard(
          icon: Icons.trending_up,
          value: '${(stats.averageProgress * 100).toInt()}%',
          label: 'التقدم',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showCreatePlanDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CreatePlanSheet(),
    );
  }
}

// تبويب النظرة العامة
class _PlansOverviewTab extends StatelessWidget {
  const _PlansOverviewTab();

  @override
  Widget build(BuildContext context) {
    return Consumer2<EnhancedPlanService, BookService>(
      builder: (context, planService, bookService, _) {
        if (planService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final activePlans = planService.getActivePlans();
        
        if (activePlans.isEmpty) {
          return _buildEmptyState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(EnhancedSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الخطط السريعة (المبنية على حالات الكتب)
              _buildQuickPlansSection(activePlans, bookService),
              
              const SizedBox(height: EnhancedSpacing.xl),
              
              // الخطط المخصصة النشطة
              _buildActiveCustomPlans(activePlans, bookService),
              
              const SizedBox(height: EnhancedSpacing.xl),
              
              // التحديات النشطة
              _buildActiveChallenges(activePlans, bookService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickPlansSection(List<ReadingPlan> activePlans, BookService bookService) {
    final quickPlanTypes = [
      PlanType.currentlyReading,
      PlanType.wantToRead,
      PlanType.completed,
      PlanType.favorites,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📚 خططك السريعة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: EnhancedAppColors.gray800,
          ),
        ),
        
        const SizedBox(height: EnhancedSpacing.md),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: EnhancedSpacing.md,
            mainAxisSpacing: EnhancedSpacing.md,
            childAspectRatio: 1.2,
          ),
          itemCount: quickPlanTypes.length,
          itemBuilder: (context, index) {
            final type = quickPlanTypes[index];
            final plan = activePlans.firstWhere(
              (p) => p.type == type,
              orElse: () => ReadingPlan(
                id: 'temp',
                name: type.displayName,
                description: type.description,
                type: type,
                createdAt: DateTime.now(),
                userId: '',
              ),
            );
            
            return _buildQuickPlanCard(plan, bookService);
          },
        ),
      ],
    );
  }

  Widget _buildQuickPlanCard(ReadingPlan plan, BookService bookService) {
    final booksInPlan = plan.bookIds
        .map((id) => bookService.getBookById(id))
        .where((book) => book != null)
        .cast<BookModel>()
        .toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            plan.type.color,
            plan.type.color.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(EnhancedRadius.lg),
        boxShadow: EnhancedShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToPlanDetails(plan),
          borderRadius: BorderRadius.circular(EnhancedRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(EnhancedSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      plan.type.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        plan.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  '${booksInPlan.length} كتاب',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                
                const Spacer(),
                
                if (plan.overallProgress > 0)
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: plan.overallProgress,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        '${(plan.overallProgress * 100).toInt()}% مكتمل',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveCustomPlans(List<ReadingPlan> activePlans, BookService bookService) {
    final customPlans = activePlans
        .where((p) => p.type == PlanType.custom)
        .toList();

    if (customPlans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '🎯 خططك المخصصة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: EnhancedAppColors.gray800,
              ),
            ),
            TextButton(
              onPressed: () {
                // انتقال لعرض جميع الخطط المخصصة
              },
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        
        const SizedBox(height: EnhancedSpacing.md),
        
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: customPlans.length,
            itemBuilder: (context, index) {
              final plan = customPlans[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(left: EnhancedSpacing.md),
                child: _buildCustomPlanCard(plan, bookService),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomPlanCard(ReadingPlan plan, BookService bookService) {
    final booksInPlan = plan.bookIds
        .map((id) => bookService.getBookById(id))
        .where((book) => book != null)
        .cast<BookModel>()
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EnhancedRadius.lg),
        boxShadow: EnhancedShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToPlanDetails(plan),
          borderRadius: BorderRadius.circular(EnhancedRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(EnhancedSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: plan.type.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        plan.type.icon,
                        color: plan.type.color,
                        size: 20,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: EnhancedAppColors.gray800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${booksInPlan.length} كتاب',
                            style: const TextStyle(
                              fontSize: 12,
                              color: EnhancedAppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  plan.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: EnhancedAppColors.gray700,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const Spacer(),
                
                if (plan.overallProgress > 0)
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: plan.overallProgress,
                        backgroundColor: EnhancedAppColors.gray200,
                        valueColor: AlwaysStoppedAnimation<Color>(plan.type.color),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        '${(plan.overallProgress * 100).toInt()}% مكتمل',
                        style: const TextStyle(
                          fontSize: 11,
                          color: EnhancedAppColors.gray600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveChallenges(List<ReadingPlan> activePlans, BookService bookService) {
    final challenges = activePlans
        .where((p) => p.type == PlanType.challenge)
        .toList();

    if (challenges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏆 التحديات النشطة',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: EnhancedAppColors.gray800,
          ),
        ),
        
        const SizedBox(height: EnhancedSpacing.md),
        
        ...challenges.map((challenge) => Container(
          margin: const EdgeInsets.only(bottom: EnhancedSpacing.md),
          child: _buildChallengeCard(challenge, bookService),
        )),
      ],
    );
  }

  Widget _buildChallengeCard(ReadingPlan challenge, BookService bookService) {
    final daysLeft = challenge.targetDate != null
        ? challenge.targetDate!.difference(DateTime.now()).inDays
        : 0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF9800),
            Color(0xFFFFB74D),
          ],
        ),
        borderRadius: BorderRadius.circular(EnhancedRadius.lg),
        boxShadow: EnhancedShadows.medium,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToPlanDetails(challenge),
          borderRadius: BorderRadius.circular(EnhancedRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(EnhancedSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 28,
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            challenge.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (daysLeft > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$daysLeft يوم',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // شريط التقدم
                LinearProgressIndicator(
                  value: challenge.overallProgress,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${challenge.completedBooksCount}/${challenge.bookIds.length} كتاب',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(challenge.overallProgress * 100).toInt()}% مكتمل',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EnhancedSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'لا توجد خطط قراءة حالياً',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: EnhancedAppColors.gray700,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'ابدأ بإنشاء خطة قراءة لتنظيم كتبك وتتبع تقدمك',
              style: TextStyle(
                fontSize: 16,
                color: EnhancedAppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton.icon(
              onPressed: () {
                // إظهار نافذة إنشاء خطة
              },
              icon: const Icon(Icons.add),
              label: const Text('إنشاء خطة جديدة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EnhancedAppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPlanDetails(ReadingPlan plan) {
    // TODO: تطبيق التنقل لصفحة تفاصيل الخطة
  }
}

// تبويب خططي
class _MyPlansTab extends StatelessWidget {
  const _MyPlansTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedPlanService>(
      builder: (context, planService, _) {
        final plans = planService.plans;
        
        if (plans.isEmpty) {
          return const Center(
            child: Text('لا توجد خطط'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(EnhancedSpacing.lg),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            return Container(
              margin: const EdgeInsets.only(bottom: EnhancedSpacing.md),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: plan.type.color.withOpacity(0.1),
                  child: Icon(plan.type.icon, color: plan.type.color),
                ),
                title: Text(plan.name),
                subtitle: Text('${plan.bookIds.length} كتاب'),
                trailing: Text('${(plan.overallProgress * 100).toInt()}%'),
                onTap: () {
                  // انتقال لتفاصيل الخطة
                },
              ),
            );
          },
        );
      },
    );
  }
}

// تبويب الإحصائيات
class _ReadingStatsTab extends StatelessWidget {
  const _ReadingStatsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('إحصائيات القراءة - قريباً'),
    );
  }
}

// نافذة إنشاء خطة جديدة
class _CreatePlanSheet extends StatefulWidget {
  const _CreatePlanSheet();

  @override
  State<_CreatePlanSheet> createState() => _CreatePlanSheetState();
}

class _CreatePlanSheetState extends State<_CreatePlanSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  PlanType _selectedType = PlanType.custom;
  DateTime? _targetDate;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EnhancedRadius.xl),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: EnhancedSpacing.lg,
          right: EnhancedSpacing.lg,
          top: EnhancedSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + EnhancedSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // مقبض السحب
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: EnhancedAppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'إنشاء خطة قراءة جديدة',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: EnhancedAppColors.gray800,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // اسم الخطة
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الخطة',
                hintText: 'مثل: كتب الأدب العربي',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // وصف الخطة
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'وصف الخطة (اختياري)',
                hintText: 'اكتب وصفاً مختصراً للخطة...',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // نوع الخطة
            const Text(
              'نوع الخطة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: EnhancedAppColors.gray700,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PlanType.values.map((type) {
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(type.icon, size: 16),
                      const SizedBox(width: 4),
                      Text(type.displayName),
                    ],
                  ),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedType = type);
                    }
                  },
                  selectedColor: type.color.withOpacity(0.2),
                  checkmarkColor: type.color,
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // أزرار العمل
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء'),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: ElevatedButton(
                    onPressed: _createPlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EnhancedAppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('إنشاء الخطة'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _createPlan() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم الخطة')),
      );
      return;
    }

    final auth = Provider.of<AuthFirebaseService>(context, listen: false);
    final planService = Provider.of<EnhancedPlanService>(context, listen: false);

    if (auth.currentUser == null) return;

    final success = await planService.createPlan(
      userId: auth.currentUser!.uid,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      targetDate: _targetDate,
    );

    if (success != null && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الخطة بنجاح')),
      );
    }
  }
}
