import 'dart:io';

import 'package:camera/camera.dart';

class CameraBurstService {
  /// Back camera first, whatever its numeric id is
  static Future<CameraDescription> _backCamera() async {
    final cameras = await availableCameras();
    return cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
  }

  /// Call once when driving mode starts: triggers the camera permission prompt
  static Future<void> warmUp() async {
    final c = CameraController(await _backCamera(), ResolutionPreset.low,
        enableAudio: false);
    try {
      await c.initialize();
    } finally {
      await c.dispose();
    }
  }

  /// Takes [count] photos with the back camera, [gap] apart
  static Future<List<File>> captureBurst({
    int count = 4,
    Duration gap = const Duration(milliseconds: 700),
    ResolutionPreset preset = ResolutionPreset.high,
  }) async {
    final controller =
        CameraController(await _backCamera(), preset, enableAudio: false);
    final files = <File>[];
    try {
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      for (var i = 0; i < count; i++) {
        final shot = await controller.takePicture();
        files.add(File(shot.path));
        if (i < count - 1) await Future.delayed(gap);
      }
    } finally {
      await controller.dispose();
    }
    return files;
  }
}