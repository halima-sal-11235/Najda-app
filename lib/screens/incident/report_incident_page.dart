import 'package:flutter/material.dart';
import 'package:najda/globals.dart';
import 'package:najda/widgets/app_bar.dart';
import 'package:najda/widgets/app_button.dart';
import 'package:najda/widgets/app_card.dart';

/// Screen 9 - witness / party form
class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({super.key});

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  bool _witness = true;
  String? _type;
  int _cars = 1;
  String _injuries = 'لا أعرف';

  static const _types = [
    'حادث مروري',
    'مركبة معطلة',
    'حريق مركبة',
    'طريق مغلق',
    'أخرى',
  ];

  Widget _seg(String label, bool selected, VoidCallback onTap) => Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : textColor)),
            ),
          ),
        ),
      );

  Widget _radio(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(
          onTap: onTap,
          child: Row(
            children: [
              Expanded(child: Text(label)),
              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: secondaryColor),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarOf('الإبلاغ عن حادث'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE3EAF0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _seg('شاهد', _witness, () => setState(() => _witness = true)),
                _seg('طرف في حادث', !_witness, () => setState(() => _witness = false)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('ما هي صفتك؟', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _radio('شاهد حادث', _witness, () => setState(() => _witness = true)),
          _radio('أحد أطراف الحادث', !_witness, () => setState(() => _witness = false)),
          const SizedBox(height: 8),
          const Text('معلومات الحادث',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _type,
            isExpanded: true,
            hint: const Text('اختر نوع الحادث'),
            items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _type = v),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('عدد المركبات المتضررة'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => setState(() => _cars = (_cars - 1).clamp(1, 20)),
                ),
                Text('$_cars',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => _cars = (_cars + 1).clamp(1, 20)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('هل توجد إصابات؟'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['نعم', 'لا', 'لا أعرف']
                .map((o) => ChoiceChip(
                      label: Text(o),
                      selected: _injuries == o,
                      selectedColor: secondaryColor.withValues(alpha: 0.2),
                      onSelected: (_) => setState(() => _injuries = o),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'إرسال البلاغ',
            color: secondaryColor,
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('تم إرسال البلاغ ✅')),
              );
            },
          ),
        ],
      ),
    );
  }
}
