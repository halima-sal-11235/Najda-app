import 'dart:async';
import 'package:flutter/material.dart';
import 'package:najda/globals.dart';
import 'package:najda/screens/incident/ai_analysis_page.dart';
import 'package:najda/widgets/app_bar.dart';

/// Screen 7 - photo capture. Placeholder images for now.
/// Later: add `flutter pub add image_picker` and replace the boxes by real photos.
class PhotoCapturePage extends StatefulWidget {
  const PhotoCapturePage({super.key});

  @override
  State<PhotoCapturePage> createState() => _PhotoCapturePageState();
}

class _PhotoCapturePageState extends State<PhotoCapturePage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // pretend the AI is analysing, then go to the result screen
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AiAnalysisPage()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const box = Color(0xFF3B4A57);
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: appBarOf('التقاط الصور', bg: primaryColor, fg: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: box,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(Icons.car_crash, size: 90, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 70,
              child: Row(
                children: List.generate(
                  3,
                  (i) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                          color: box, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.photo, color: Colors.white38),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('...جاري تحليل الصور', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            const LinearProgressIndicator(
              color: secondaryColor,
              backgroundColor: Colors.white24,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
