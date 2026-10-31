import 'package:flutter/material.dart';
import 'package:najda/globals.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = primaryColor,
    this.outlined = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool outlined;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    final text = Text(label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
    final child = icon == null
        ? text
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(icon, size: 20), const SizedBox(width: 8), text],
          );
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: outlined
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                backgroundColor: Colors.white,
                side: BorderSide(color: color, width: 1.5),
                shape: shape,
              ),
              onPressed: onPressed,
              child: child,
            )
          : FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: shape,
              ),
              onPressed: onPressed,
              child: child,
            ),
    );
  }
}
