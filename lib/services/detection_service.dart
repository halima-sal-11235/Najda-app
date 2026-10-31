import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

const double _g = 9.80665;

class MotionSample {
  MotionSample(this.time, this.accG, this.gyro);
  final DateTime time;
  final double accG; // total acceleration in g (about 1.0 at rest)
  final double gyro; // total rotation in rad/s
}

class GpsSample {
  GpsSample({
    required this.time,
    required this.lat,
    required this.lng,
    required this.speedKmh,
    required this.heading,
    required this.accuracy,
  });
  final DateTime time;
  final double lat;
  final double lng;
  final double speedKmh;
  final double heading;
  final double accuracy;
}

/// Values shown in the debug panel
class LiveReading {
  const LiveReading({this.accG = 0, this.gyro = 0, this.speedKmh = 0, this.gpsAccuracy = 0});
  final double accG;
  final double gyro;
  final double speedKmh;
  final double gpsAccuracy;
}

class DetectionService {
  DetectionService._();
  static final instance = DetectionService._();

  static const _window = Duration(seconds: 10);

  final _motion = ListQueue<MotionSample>();
  final _gps = ListQueue<GpsSample>();
  double _lastGyro = 0;

  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<Position>? _gpsSub;
  Timer? _liveTimer;

  bool get isRunning => _accSub != null;
  final live = ValueNotifier<LiveReading>(const LiveReading());

  GpsSample? get lastGps => _gps.isEmpty ? null : _gps.last;

  // ---------------------------------------------------------------- start/stop
  Future<void> start() async {
    if (isRunning) return;

    // Accelerometer, about 50 readings per second
    _accSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((e) {
      final accG = sqrt(e.x * e.x + e.y * e.y + e.z * e.z) / _g;
      final now = DateTime.now();
      _motion.add(MotionSample(now, accG, _lastGyro));
      _trim(_motion, (s) => s.time, now);
      // Step 3: call the detection rule here
    });

    // Gyroscope: we only store the latest value, it is attached to the next sample
    _gyroSub = gyroscopeEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((e) {
      _lastGyro = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    });

    // GPS, about once per second
    _gpsSub = Geolocator.getPositionStream(locationSettings: _gpsSettings())
        .listen((p) {
      final now = DateTime.now();
      _gps.add(GpsSample(
        time: now,
        lat: p.latitude,
        lng: p.longitude,
        // speed can be negative or unreliable: clamp it
        speedKmh: p.speed < 0 ? 0 : p.speed * 3.6,
        heading: p.heading,
        accuracy: p.accuracy,
      ));
      _trim(_gps, (s) => s.time, now);
    });

    // Update the debug panel 5 times per second (not on every sensor event)
    _liveTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final m = _motion.isEmpty ? null : _motion.last;
      final g = lastGps;
      live.value = LiveReading(
        accG: m?.accG ?? 0,
        gyro: m?.gyro ?? 0,
        speedKmh: g?.speedKmh ?? 0,
        gpsAccuracy: g?.accuracy ?? 0,
      );
    });
  }

  Future<void> stop() async {
    await _accSub?.cancel();
    await _gyroSub?.cancel();
    await _gpsSub?.cancel();
    _liveTimer?.cancel();
    _accSub = _gyroSub = _gpsSub = null;
    _liveTimer = null;
    _motion.clear();
    _gps.clear();
  }

  // ------------------------------------------------------------ derived values
  /// Highest total acceleration (in g) during the last [last]
  double peakAccG(Duration last) =>
      _motion.where((s) => _within(s.time, last)).fold(0.0, (a, s) => max(a, s.accG));

  /// Lowest total acceleration (near 0 g = free fall)
  double minAccG(Duration last) {
    final w = _motion.where((s) => _within(s.time, last));
    return w.isEmpty ? 1.0 : w.map((s) => s.accG).reduce(min);
  }

  double peakGyro(Duration last) =>
      _motion.where((s) => _within(s.time, last)).fold(0.0, (a, s) => max(a, s.gyro));

  /// Highest speed during the last [last] (km/h)
  double maxSpeedKmh(Duration last) =>
      _gps.where((s) => _within(s.time, last)).fold(0.0, (a, s) => max(a, s.speedKmh));

  double get speedNowKmh => lastGps?.speedKmh ?? 0;

  /// True if the phone barely moved during the last [last]
  bool isStill(Duration last, {double tolerance = 0.08}) {
    final w = _motion.where((s) => _within(s.time, last)).toList();
    if (w.length < 5) return false;
    final values = w.map((s) => s.accG);
    return (values.reduce(max) - values.reduce(min)) < tolerance;
  }

  // ------------------------------------------------------------------- helpers
  bool _within(DateTime t, Duration last) =>
      DateTime.now().difference(t) <= last;

  void _trim<T>(ListQueue<T> q, DateTime Function(T) time, DateTime now) {
    while (q.isNotEmpty && now.difference(time(q.first)) > _window) {
      q.removeFirst();
    }
  }

  LocationSettings _gpsSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
        // Shows a notification and keeps GPS alive when the screen is off
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'نجدة',
          notificationText: 'الحماية مفعّلة',
          enableWakeLock: true,
        ),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
  }
}