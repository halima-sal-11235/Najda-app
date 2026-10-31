import 'package:flutter/material.dart';
import 'package:najda/globals.dart';

class GplAlert extends StatelessWidget {
  const GplAlert({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warningColor.withValues(alpha: 0.12),
        border: Border.all(color: warningColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_fire_department, color: warningColor, size: 32),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'تنبيه خطر حريق (GPL): سيتم إبلاغ فرق الإنقاذ فورًا '
              'في لوحة المعلومات الطبية عند وقوع حادث.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
