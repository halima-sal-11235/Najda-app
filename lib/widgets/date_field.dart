import 'package:flutter/material.dart';
import 'package:najda/utils/validators.dart';

/// Read-only field that opens a calendar. Writes yyyy/mm/dd in the controller.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.controller,
    required this.label,
    required this.firstDate,
    required this.lastDate,
    this.initialDate,
    this.icon = Icons.calendar_month,
  });

  final TextEditingController controller;
  final String label;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? initialDate;
  final IconData icon;

  Future<void> _pick(BuildContext context) async {
    final d = await showDatePicker(
      context: context,
      initialDate: initialDate ?? lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (d != null) {
      controller.text =
          '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        validator: Validators.required,
        onTap: () => _pick(context),
        decoration: InputDecoration(
          labelText: label,
          hintText: 'yyyy/mm/dd',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
