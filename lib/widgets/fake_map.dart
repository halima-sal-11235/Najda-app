import 'package:flutter/material.dart';

/// A drawn "map" (no API key needed). Replace later with google_maps_flutter
/// or flutter_map. Pins use fractions: x,y in 0..1.
class MapPin {
  const MapPin(this.x, this.y, this.icon, this.color, {this.size = 34});
  final double x;
  final double y;
  final IconData icon;
  final Color color;
  final double size;
}

class FakeMap extends StatelessWidget {
  const FakeMap({super.key, this.pins = const []});
  final List<MapPin> pins;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final h = box.maxHeight;
      return ClipRect(
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _MapPainter())),
            for (final p in pins)
              Positioned(
                left: p.x * w - p.size / 2,
                top: p.y * h - p.size,
                child: Icon(p.icon, color: p.color, size: p.size),
              ),
          ],
        ),
      );
    });
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFE9EEF2));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.05, s.height * 0.62, s.width * 0.28, s.height * 0.26),
        const Radius.circular(14),
      ),
      Paint()..color = const Color(0xFFD5E8D4),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s.width * 0.68, s.height * 0.06, s.width * 0.26, s.height * 0.2),
        const Radius.circular(14),
      ),
      Paint()..color = const Color(0xFFCFE3F1),
    );
    final big = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final small = Paint()
      ..color = Colors.white
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, s.height * 0.35), Offset(s.width, s.height * 0.5), big);
    canvas.drawLine(Offset(s.width * 0.4, 0), Offset(s.width * 0.55, s.height), big);
    canvas.drawLine(Offset(0, s.height * 0.8), Offset(s.width, s.height * 0.7), small);
    canvas.drawLine(Offset(s.width * 0.15, 0), Offset(s.width * 0.1, s.height), small);
    canvas.drawLine(Offset(s.width * 0.85, 0), Offset(s.width * 0.8, s.height), small);
    canvas.drawLine(Offset(0, s.height * 0.12), Offset(s.width, s.height * 0.2), small);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
