import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_firebase_service.dart';
import '../../services/reading_challenge_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/design_tokens.dart';

class CreateChallengeScreen extends StatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetBooksController = TextEditingController();
  
  int _selectedYear = DateTime.now().year;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime(_selectedYear, 1, 1);
    _endDate = DateTime(_selectedYear, 12, 31);
    _titleController.text = 'تحدي القراءة $_selectedYear';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetBooksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء تحدي قراءة'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان التوضيحي
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Text(
                            'إنشاء تحدي قراءة شخصي',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'حدد هدفاً لعدد الكتب التي تريد قراءتها خلال فترة زمنية معينة، وتابع تقدمك نحو تحقيق هذا الهدف.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // اسم التحدي
              _buildSectionTitle('اسم التحدي'),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'مثال: تحدي القراءة 2025',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال اسم التحدي';
                  }
                  if (value.trim().length < 3) {
                    return 'اسم التحدي يجب أن يكون 3 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 25),
              
              // عدد الكتب المستهدف
              _buildSectionTitle('عدد الكتب المستهدف'),
              TextFormField(
                controller: _targetBooksController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'مثال: 24',
                  prefixIcon: const Icon(Icons.book),
                  suffixText: 'كتاب',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال عدد الكتب المستهدف';
                  }
                  final target = int.tryParse(value);
                  if (target == null || target <= 0) {
                    return 'يرجى إدخال رقم صحيح أكبر من 0';
                  }
                  if (target > 1000) {
                    return 'العدد كبير جداً! اختر رقماً معقولاً';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 25),
              
              // السنة
              _buildSectionTitle('السنة'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: List.generate(5, (index) {
                      final year = DateTime.now().year + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text('$year'),
                      );
                    }),
                    onChanged: (year) {
                      if (year != null) {
                        setState(() {
                          _selectedYear = year;
                          _startDate = DateTime(year, 1, 1);
                          _endDate = DateTime(year, 12, 31);
                          _titleController.text = 'تحدي القراءة $year';
                        });
                      }
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 25),
              
              // تواريخ البداية والنهاية
              _buildSectionTitle('فترة التحدي'),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'تاريخ البداية',
                      date: _startDate,
                      onTap: () => _selectDate(isStartDate: true),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildDateField(
                      label: 'تاريخ النهاية',
                      date: _endDate,
                      onTap: () => _selectDate(isStartDate: false),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // زر الإنشاء
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rocket_launch, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'إنشاء التحدي',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? '${date.day}/${date.month}/${date.year}'
                      : 'اختر التاريخ',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final initialDate = isStartDate ? _startDate : _endDate;
    final firstDate = DateTime(2020);
    final lastDate = DateTime(2030);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          // التأكد من أن تاريخ النهاية بعد البداية
          if (_endDate != null && _endDate!.isBefore(pickedDate)) {
            _endDate = DateTime(pickedDate.year, 12, 31);
          }
        } else {
          _endDate = pickedDate;
          // التأكد من أن تاريخ البداية قبل النهاية
          if (_startDate != null && _startDate!.isAfter(pickedDate)) {
            _startDate = DateTime(pickedDate.year, 1, 1);
          }
        }
      });
    }
  }

  Future<void> _createChallenge() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحديد تواريخ البداية والنهاية')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthFirebaseService>(context, listen: false);
      final challengeService = Provider.of<ReadingChallengeService>(context, listen: false);
      
      if (authService.currentUser == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      await challengeService.createChallenge(
        userId: authService.currentUser!.uid,
        title: _titleController.text.trim(),
        targetBooks: int.parse(_targetBooksController.text),
        year: _selectedYear,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 تم إنشاء التحدي بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء التحدي: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

