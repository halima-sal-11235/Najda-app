import 'package:flutter/material.dart';
import 'package:najda/main.dart';

import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../driving/driving_screen.dart';
import 'report_accident.dart';
import 'accidents_map.dart';

class HomeScreen extends StatelessWidget {
   HomeScreen({super.key});

  String _firstName() {
    final user = supabase.auth.currentUser;
    final full = (user?.userMetadata?['full_name'] as String?)?.trim();
    if (full == null || full.isEmpty) return '';
    return full.split(' ').first;
  }
  final List<QuestionModel> accidentQuestions = [
  QuestionModel(
    questionText: 'ماذا حدث؟',
    options: ['اصطدام سيارتين', 'انقلاب', 'دهس راجل', 'أخرى'],
  ),
  QuestionModel(
    questionText: 'هل يوجد إصابات؟',
    options: ['إصابات بليغة', 'أشخاص محتجزون', 'إصابات خفيفة', 'لا توجد'],
  ),
  QuestionModel(
    questionText: 'حالة الطريق والخطورة؟',
    options: ['حريق بالمركبة', 'طريق مسدود', 'تسرب وقود', 'طريق سالك'],
  ),
];

  // void _comingSoon(BuildContext context) {
  //   ScaffoldMessenger.of(
  //     context,
  //   ).showSnackBar(const SnackBar(content: Text('قريباً')));
  // }

  @override
  Widget build(BuildContext context) {
    final name = _firstName();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name.isEmpty ? 'مرحباً' : 'مرحباً، $name',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const _ConnectionChip(),
                ],
              ),
              const SizedBox(height: 24),
              _DrivingCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DrivingScreen()),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SmallCard(
                      icon: Icons.upload_rounded,
                      label: 'إبلاغ يدوي',
                      onTap: () => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AccidentQuestionnaireScreen(
      questions: accidentQuestions,
      OnCompleted: (answers) {
        // Send answers dictionary to Python backend or Supabase
        print("User Answers: $answers");
      },
    ),
  ),
),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SmallCard(
                      icon: Icons.location_on_outlined,
                      label: 'خريطة الحوادث',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AccidentMap()),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'في الخطر الشديد اتصل بـ 14 أو 17',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionChip extends StatelessWidget {
  const _ConnectionChip();

  @override
  Widget build(BuildContext context) {
    // TODO: replace with the real state (connectivity_plus + GPS check)
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: AppColors.teal),
        SizedBox(width: 6),
        Text(
          'متصل',
          style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _DrivingCard extends StatelessWidget {
  const _DrivingCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.red,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: const SizedBox(
          height: 220,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_car_rounded, size: 56, color: Colors.white),
              SizedBox(height: 16),
              Text(
                'وضع القيادة',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'فعّل الحماية قبل أن تنطلق',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallCard extends StatelessWidget {
  const _SmallCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: AppColors.teal),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
