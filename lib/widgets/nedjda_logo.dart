import 'package:flutter/material.dart';
import 'package:najda/globals.dart';

/// Placeholder logo built from icons. Later: replace with Image.asset(...).
class NedjdaLogo extends StatelessWidget {
  const NedjdaLogo({
    super.key,
    this.size = 80,
    this.showText = false,
    this.light = false,
    this.tagline = false,
  });

  final double size;
  final bool showText;
  final bool light; // white version for dark backgrounds
  final bool tagline;

  @override
  Widget build(BuildContext context) {
    final pin = light ? Colors.white : secondaryColor;
    final titleColor = light ? Colors.white : primaryColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.location_on, size: size, color: pin),
            Padding(
              padding: EdgeInsets.only(bottom: size * 0.18),
              child: Container(
                width: size * 0.42,
                height: size * 0.42,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: Icon(Icons.notifications_active,
                    size: size * 0.26, color: emergencyColor),
              ),
            ),
          ],
        ),
        if (showText) ...[
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: 'Nedjda ', style: TextStyle(color: titleColor)),
              TextSpan(
                  text: 'DZ',
                  style: TextStyle(color: light ? Colors.white : secondaryColor)),
            ]),
            style: TextStyle(fontSize: size * 0.34, fontWeight: FontWeight.w800),
          ),
        ],
        if (tagline)
          Text('Your safety. Our priority.',
              style: TextStyle(color: light ? Colors.white70 : mutedColor)),
      ],
    );
  }
}
