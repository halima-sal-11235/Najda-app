import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertApiService {
  // With a physical phone: run `adb reverse tcp:8000 tcp:8000` first
  static const String _base = 'http://127.0.0.1:8000';

  /// Reason of the last failure (null if everything went fine)
  static String? lastError;

  /// Step 1: create the alert (with or without photos)
  static Future<Map<String, dynamic>?> sendCrashAlert({
    required double lat,
    required double lng,
    required double impactG,
    required double speedBeforeKmh,
    required String source,
    bool voiceHelp = false,
    String voiceText = '',
    List<File> images = const [],
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    final request =
        http.MultipartRequest('POST', Uri.parse('$_base/api/alerts/process'));
    request.fields['user_id'] = user?.id ?? 'anonymous';
    request.fields['lat'] = lat.toString();
    request.fields['lng'] = lng.toString();
    request.fields['impact_g'] = impactG.toString();
    request.fields['speed_before_kmh'] = speedBeforeKmh.toString();
    request.fields['source'] = source;
    request.fields['voice_help'] = voiceHelp.toString();
    request.fields['voice_text'] = voiceText;
    await _addImages(request, images);
    return _send(request);
  }

  /// Step 2: attach photos to an existing alert (the backend runs the AI)
  static Future<Map<String, dynamic>?> attachImages({
    required String alertId,
    required List<File> images,
  }) async {
    final request = http.MultipartRequest(
        'POST', Uri.parse('$_base/api/alerts/$alertId/images'));
    await _addImages(request, images);
    return _send(request);
  }

  static Future<void> _addImages(
      http.MultipartRequest request, List<File> images) async {
    for (final f in images) {
      if (await f.exists()) {
        // Same field name for every file: the backend receives a list
        request.files.add(await http.MultipartFile.fromPath('images', f.path));
      }
    }
  }

  static Future<Map<String, dynamic>?> _send(
      http.MultipartRequest request) async {
    lastError = null;
    try {
      final token =
          Supabase.instance.client.auth.currentSession?.accessToken;
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      final streamed =
          await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      lastError = 'HTTP ${response.statusCode}: ${response.body}';
    } on TimeoutException {
      lastError = 'Timeout: backend not answering';
    } catch (e) {
      lastError = 'Network: $e';
    }
    debugPrint(lastError);
    return null;
  }
}