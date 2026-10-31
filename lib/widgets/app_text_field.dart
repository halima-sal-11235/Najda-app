import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:najda/utils/validators.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.hint,
    this.keyboardType,
    this.validator,
    this.formatters,
    this.onChanged,
    this.maxLines = 1,
    this.required = true,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final bool required;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        onChanged: onChanged,
        maxLines: maxLines,
        obscureText: obscureText,
        validator: validator ?? (required ? Validators.required : null),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon == null ? null : Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
