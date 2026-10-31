import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:najda/screens/incident/incident_location_page.dart';
import 'package:najda/services/alert_api_service.dart';
import 'package:najda/services/voice_help_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CrashAlertPage extends StatefulWidget {
  final double impactG;
  final double speedKmh;

  const CrashAlertPage({
    super.key,
    this.impactG = 6.8,
    this.speedKmh = 75.0,
  });

  @override
  State<CrashAlertPage> createState() => _CrashAlertPageState();
}

class _CrashAlertPageState extends State<CrashAlertPage> {
  static const int _countdownSeconds = 15;
  // The first alert leaves after this delay (so a tiny bump you answer fast
  // creates nothing). Then the page updates that same alert.
  static const int _preAlertAfterSeconds = 5;

  int _secondsLeft = _countdownSeconds;
  Timer? _timer;

  // Camera: opened now, used for the burst later
  CameraController? _camera;
  Future<void>? _cameraInit;
  Future<List<File>>? _photosFuture;

  // Voice
  final _voice = VoiceHelpService();
  bool _voiceHelp = false;
  String _voiceText = '';

  // Position at the moment of the crash (never invented)
  double? _lat;
  double? _lng;

  // Alert state
  String? _alertId;
  Future<void>? _preAlertFuture;
  bool _preAlertSent = false;
  bool _finished = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _cameraInit = _initCamera();
    _fetchPosition();
    _startVoice();
    _startTimer();
  }

  // ------------------------------------------------------------------ setup
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false, // the microphone stays free for the voice
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      _camera = controller;
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _fetchPosition() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        _lat = last.latitude;
        _lng = last.longitude;
      }
      final now = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      _lat = now.latitude;
      _lng = now.longitude;
    } catch (e) {
      debugPrint('Position error: $e');
    }
  }

  Future<void> _startVoice() async {
    try {
      if (!await _voice.init()) return; // no voice: the buttons still work
      await _voice.start(
        onText: (t) {
          if (mounted) setState(() => _voiceText = t);
        },
        onHelp: (t) {
          if (_finished) return;
          _voiceHelp = true;
          _voiceText = t;
          _finish('new'); // someone calling for help: top priority
        },
      );
    } catch (e) {
      debugPrint('Voice start failed: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _finished) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      final elapsed = _countdownSeconds - _secondsLeft;

      if (elapsed == _preAlertAfterSeconds) {
        _preAlertFuture ??= _doPreAlert();
      }
      if (_secondsLeft <= 0) {
        t.cancel();
        _finish('no_response');
      }
    });
  }

  // -------------------------------------------------------------- the alert
  /// Sends the alert WITHOUT photos and starts the camera at the same time
  Future<void> _doPreAlert() async {
    _photosFuture ??= _takeBurst();

    final r = await AlertApiService.sendCrashAlert(
      lat: _lat ?? 0, // 0,0 = unknown: the dashboard must say "call the user"
      lng: _lng ?? 0,
      impactG: widget.impactG,
      speedBeforeKmh: widget.speedKmh,
      source: 'app',
      voiceHelp: _voiceHelp,
      voiceText: _voiceText,
    );
    _alertId = r?['alert_id'] as String?;
    if (_alertId != null && mounted) setState(() => _preAlertSent = true);
  }

  Future<List<File>> _takeBurst({int count = 4}) async {
    final files = <File>[];
    try {
      await _cameraInit;
      final c = _camera;
      if (c == null || !c.value.isInitialized) return files;
      for (var i = 0; i < count; i++) {
        final shot = await c.takePicture();
        files.add(File(shot.path));
        if (i < count - 1) {
          await Future.delayed(const Duration(milliseconds: 700));
        }
      }
    } catch (e) {
      debugPrint('Burst failed (keeping ${files.length} photos): $e');
    }
    return files;
  }

  /// Updates the existing alert directly in Supabase
  Future<void> _updateAlert(Map<String, dynamic> data) async {
    final id = _alertId;
    if (id == null) return;
    try {
      await Supabase.instance.client.from('alerts').update(data).eq('id', id);
    } catch (e) {
      debugPrint('Alert update failed: $e');
    }
  }

  /// status: 'cancelled' | 'no_response' | 'new'
  Future<void> _finish(String status) async {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    await _voice.stop();

    // The person is fine: withdraw the alert if it already left
    if (status == 'cancelled') {
      await _preAlertFuture;
      await _updateAlert({'status': 'cancelled'});
      if (mounted) Navigator.pop(context);
      return;
    }

    if (mounted) setState(() => _processing = true);

    // Manual SOS or voice before the 5 s mark: create the alert now
    _preAlertFuture ??= _doPreAlert();
    await _preAlertFuture;

    final photos = await (_photosFuture ?? Future.value(<File>[]));

    Map<String, dynamic>? aiData;
    if (_alertId != null) {
      await _updateAlert({
        'status': status,
        if (_voiceHelp) 'voice_help': true,
        if (_voiceHelp) 'voice_text': _voiceText,
      });
      if (photos.isNotEmpty) {
        aiData = await AlertApiService.attachImages(
          alertId: _alertId!,
          images: photos,
        );
      }
    } else {
      // The first alert failed (no network?): one request with everything
      final all = await AlertApiService.sendCrashAlert(
        lat: _lat ?? 0,
        lng: _lng ?? 0,
        impactG: widget.impactG,
        speedBeforeKmh: widget.speedKmh,
        source: 'app',
        voiceHelp: _voiceHelp,
        voiceText: _voiceText,
        images: photos,
      );
      _alertId = all?['alert_id'] as String?;
      aiData = all;
      await _updateAlert({'status': status});
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => IncidentLocationPage(
          latitude: _lat ?? 0,
          longitude: _lng ?? 0,
          impactG: widget.impactG,
          speedKmh: widget.speedKmh,
          imageFile: photos.isEmpty ? null : photos.first,
          aiData: aiData,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _voice.stop();
    _camera?.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------- UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10283F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_rounded,
                  size: 90, color: Colors.redAccent),
              const SizedBox(height: 24),
              const Text(
                'هل أنت بخير؟',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                _processing
                    ? 'جاري إرسال البلاغ وتحليل الصور...'
                    : 'سيتم إرسال نداء استغاثة تلقائي خلال $_secondsLeft ثانية',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
              if (_preAlertSent) ...[
                const SizedBox(height: 8),
                const Text(
                  'تم إرسال إنذار مبدئي إلى فريق الإسعاف',
                  style: TextStyle(color: Colors.greenAccent),
                ),
              ],
              if (_voiceText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'سمعنا: $_voiceText',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _finished ? null : () => _finish('new'),
                  child: const Text(
                    'أحتاج مساعدة! (لست بخير)',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _finished ? null : () => _finish('cancelled'),
                  child: const Text(
                    'أنا بخير (إلغاء الإنذار)',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}