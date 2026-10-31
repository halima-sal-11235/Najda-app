import 'dart:io';

import 'alert_api_service.dart';
import 'camera_burst_service.dart';

class AlertResult {
  AlertResult({this.alertId, this.aiData, this.photos = const []});
  final String? alertId;
  final Map<String, dynamic>? aiData;
  final List<File> photos;
}

Future<AlertResult> sendAlertFlow({
  required double lat,
  required double lng,
  required double impactG,
  required double speedKmh,
  bool voiceHelp = false,
  String voiceText = '',
}) async {
  // 1) Start the camera and the pre-alert AT THE SAME TIME
  final photosFuture =
      CameraBurstService.captureBurst().catchError((_) => <File>[]);

  final pre = await AlertApiService.sendCrashAlert(
    lat: lat,
    lng: lng,
    impactG: impactG,
    speedBeforeKmh: speedKmh,
    source: 'app',
    voiceHelp: voiceHelp,
    voiceText: voiceText,
  );
  final alertId = pre?['alert_id'] as String?;

  // 2) Photos
  final photos = await photosFuture;
  if (photos.isEmpty) return AlertResult(alertId: alertId, aiData: pre);

  if (alertId != null) {
    final withAi =
        await AlertApiService.attachImages(alertId: alertId, images: photos);
    return AlertResult(
        alertId: alertId, aiData: withAi ?? pre, photos: photos);
  }

  // 3) The pre-alert failed (no network?): try everything in one request
  final all = await AlertApiService.sendCrashAlert(
    lat: lat,
    lng: lng,
    impactG: impactG,
    speedBeforeKmh: speedKmh,
    source: 'app',
    voiceHelp: voiceHelp,
    voiceText: voiceText,
    images: photos,
  );
  return AlertResult(
      alertId: all?['alert_id'] as String?, aiData: all, photos: photos);
}