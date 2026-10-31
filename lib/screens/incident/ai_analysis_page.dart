import 'dart:io';

import 'package:flutter/material.dart';
import 'package:najda/globals.dart';
import 'package:najda/widgets/app_bar.dart';
import 'package:najda/widgets/app_button.dart';
import 'package:najda/widgets/app_card.dart';
import 'package:najda/services/alert_api_service.dart';

class AiAnalysisPage extends StatelessWidget {
  final Map<String, dynamic>? aiData;
  final File? localImageFile;

  const AiAnalysisPage({
    super.key,
    this.aiData,
    this.localImageFile,
  });

  num? _num(String key) {
    final v = aiData?[key];
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Look at this line in the console once, then adapt the keys below
    debugPrint('AI data: $aiData');

    final score = _num('accident_score'); // between 0 and 1
    final vehicles = _num('vehicles_count');
    final people = _num('people_count');
    final hasAi = score != null || vehicles != null || people != null;
    final percent = score == null ? null : (score * 100).clamp(0, 100).round();

    return Scaffold(
      appBar: appBarOf('تحليل الذكاء الاصطناعي'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (localImageFile != null && localImageFile!.existsSync()) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  localImageFile!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'نتيجة التحليل',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            AppCard(
              child: !hasAi
    ? Padding(                                   // no "const" here
        padding: const EdgeInsets.all(8),
        child: Text(
          'تعذّر تحليل الصورة الآن.\n'
          '${AlertApiService.lastError ?? aiData.toString()}',
        ),
      )
                  : Column(
                      children: [
                        if (percent != null)
                          InfoRow(
                            'احتمال وجود حادث',
                            '$percent%',
                            valueColor:
                                percent >= 60 ? emergencyColor : secondaryColor,
                          ),
                        if (vehicles != null)
                          InfoRow('عدد المركبات', '${vehicles.toInt()}'),
                        if (people != null)
                          InfoRow('عدد الأشخاص', '${people.toInt()}'),
                      ],
                    ),
            ),
            if (score != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: score.toDouble().clamp(0.0, 1.0),
                minHeight: 10,
                borderRadius: BorderRadius.circular(8),
                color: score >= 0.6 ? emergencyColor : secondaryColor,
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'هذا تقدير مساعد فقط، والقرار النهائي يعود لفريق الإسعاف.',
              style: TextStyle(color: mutedColor, fontSize: 12),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'تم',
              color: secondaryColor,
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}