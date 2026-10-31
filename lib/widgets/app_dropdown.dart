import 'package:flutter/material.dart';

class AppDropdown extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.required = true,
  });

  final String label;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: onChanged,
        validator: required ? (v) => v == null ? 'هذا الحقل مطلوب' : null : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
