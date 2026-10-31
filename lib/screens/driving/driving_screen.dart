import 'dart:math';
import 'package:flutter/material.dart';
import 'package:najda/main.dart';
import 'package:najda/services/detection_service.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../services/alert_service.dart';
import 'crash_alert_page.dart'; // CrashAlertPage asks the driver if they are okay

/// Hidden demo trigger. Set to false for production.
const bool kDemoTools = true;

class CrashPhysicsEvaluator {
  // Threshold constants based on automotive crash testing standards
  static const double minImpactG = 3.5; // Force exceeding 3.5G (~34 m/s²)
  static const double minGyroRate = 120.0; // High angular spin rate (deg/s)
  static const double minSpeedDropKmh = 15.0; // Speed loss within 1 second

  double previousSpeedKmh = 0.0;

  /// Evaluate using raw 3D sensor vectors
  bool isCrashDetected({
    required double accelX,
    required double accelY,
    required double accelZ,
    required double gyroX,
    required double gyroY,
    required double gyroZ,
    required double currentSpeedKmh,
  }) {
    final double rawAccelMagnitude = sqrt(
      (accelX * accelX) + (accelY * accelY) + (accelZ * accelZ),
    );
    final double gForce = rawAccelMagnitude / 9.81;

    final double gyroMagnitude = sqrt(
      (gyroX * gyroX) + (gyroY * gyroY) + (gyroZ * gyroZ),
    );

    return isCrashDetectedFromMagnitude(
      accG: gForce,
      gyro: gyroMagnitude,
      currentSpeedKmh: currentSpeedKmh,
    );
  }

  /// Evaluate using calculated LiveReading magnitudes
  bool isCrashDetectedFromMagnitude({
    required double accG,
    required double gyro,
    required double currentSpeedKmh,
  }) {
    final double speedDrop = previousSpeedKmh - currentSpeedKmh;
    previousSpeedKmh = currentSpeedKmh;

    final bool hasHighImpact = accG >= minImpactG;
    final bool hasVehicleMotionChange =
        (speedDrop >= minSpeedDropKmh) || (gyro >= minGyroRate);

    final bool isMovingVehicle =
        currentSpeedKmh > 10.0 || previousSpeedKmh > 10.0;

    return hasHighImpact && hasVehicleMotionChange && isMovingVehicle;
  }
}

class DrivingScreen extends StatefulWidget {
  const DrivingScreen({super.key});

  @override
  State<DrivingScreen> createState() => _DrivingScreenState();
}

class _DrivingScreenState extends State<DrivingScreen> {
  bool _isDriver = true;
  bool _isAlertActive = false; // Flag to prevent multiple route pushes
  final CrashPhysicsEvaluator _evaluator = CrashPhysicsEvaluator();

  @override
  void initState() {
    super.initState();
    _startProtection();
    // Listen to live sensor readings from DetectionService
    DetectionService.instance.live.addListener(_onSensorReadingChanged);
  }

  @override
  void dispose() {
    DetectionService.instance.live.removeListener(_onSensorReadingChanged);
    super.dispose();
  }

  Future<void> _startProtection() async {
    try {
      await getCurrentPosition(); // Asks for location permission
      await DetectionService.instance.start();
    } catch (e) {
      if (mounted) _snack(errorText(e));
    }
  }

  /// Evaluates each high-frequency sensor tick from DetectionService
  void _onSensorReadingChanged() {
    if (_isAlertActive) return;

    final reading = DetectionService.instance.live.value;

    final bool crashDetected = _evaluator.isCrashDetectedFromMagnitude(
      accG: reading.accG,
      gyro: reading.gyro,
      currentSpeedKmh: reading.speedKmh,
    );

    if (crashDetected) {
      _triggerCrashAlert();
    }
  }

  /// Navigates to the CrashAlertPage
  Future<void> _triggerCrashAlert() async {
    if (_isAlertActive || !mounted) return;

    setState(() {
      _isAlertActive = true;
    });

    // Optionally notify backend initial impact
    try {
      final reading = DetectionService.instance.live.value;
      await createAlert(
        impactG: reading.accG > 0 ? reading.accG : 6.2,
        speedBeforeKmh: reading.speedKmh > 0 ? reading.speedKmh : 70,
      );
    } catch (_) {}

    if (!mounted) return;

    // Push the "Are You OK?" screen
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CrashAlertPage()),
    );

    // Reset flag when user returns from alert flow
    if (mounted) {
      setState(() {
        _isAlertActive = false;
      });
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Injects simulated crash telemetry tick-by-tick into the live stream
  Future<void> simulateCrashDataStream() async {
    final mockReadings = [
      // 1. Normal driving at 60 km/h
      LiveReading(accG: 1.0, gyro: 5.0, speedKmh: 60.0, gpsAccuracy: 5.0),
      // 2. Sudden deceleration
      LiveReading(accG: 1.5, gyro: 20.0, speedKmh: 45.0, gpsAccuracy: 5.0),
      // 3. High impact spike (6.8G, spin, speed drops to 5 km/h)
      LiveReading(accG: 6.8, gyro: 180.0, speedKmh: 5.0, gpsAccuracy: 5.0),
    ];

    for (var reading in mockReadings) {
      // Inject reading directly into DetectionService stream listener
      DetectionService.instance.live.value = reading;

      // Wait 300ms between ticks to mimic rapid sensor events
      await Future.delayed(const Duration(milliseconds: 3000));
    }
  }

 /// Direct, reliable simulation trigger for testing UI & backend alerts
  Future<void> _simulateCrash() async {
    _snack('جاري إطلاق محاكاة الحادث...');

    // 1. Set mock values to live reading display
    DetectionService.instance.live.value = LiveReading(
      accG: 6.8,
      gyro: 180.0,
      speedKmh: 75.0,
      gpsAccuracy: 3.0,
    );

    // 2. Trigger the crash alert directly
    await _triggerCrashAlert();
  }

  /// Navigates to CrashAlertPage immediately
  // Future<void> _triggerCrashAlert() async {
  //   if (_isAlertActive || !mounted) return;

  //   setState(() {
  //     _isAlertActive = true;
  //   });

  //   final reading = DetectionService.instance.live.value;

  //   // Send initial network alert asynchronously (non-blocking)
  //   createAlert(
  //     impactG: reading.accG > 0 ? reading.accG : 6.8,
  //     speedBeforeKmh: reading.speedKmh > 0 ? reading.speedKmh : 70,
  //   ).catchError((e) {
  //     debugPrint('Failed to send initial alert log: $e');
  //   });

  //   // Push the CrashAlertPage immediately
  //   await Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => const CrashAlertPage()),
  //   );

  //   // Reset flag when driver returns from alert screen
  //   if (mounted) {
  //     setState(() {
  //       _isAlertActive = false;
  //     });
  //   }
  // }

  Future<void> _stop() async {
    await DetectionService.instance.stop();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _RoleToggle(
                isDriver: _isDriver,
                onChanged: (v) => setState(() => _isDriver = v),
              ),
              const Spacer(),

              // Protection Status Circle
              Container(
                width: 230,
                height: 230,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.tealLight,
                ),
                child: Center(
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppColors.teal, width: 6),
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      size: 80,
                      color: AppColors.teal,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              const Text(
                'الحماية مفعّلة',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'حساسات الحركة والموقع تعمل في الخلفية',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
              const Spacer(),

              // Live Sensor Debug Values
              if (kDemoTools)
                ValueListenableBuilder<LiveReading>(
                  valueListenable: DetectionService.instance.live,
                  builder: (context, r, _) => Text(
                    'acc ${r.accG.toStringAsFixed(2)} g   '
                    'gyro ${r.gyro.toStringAsFixed(1)}   '
                    'speed ${r.speedKmh.toStringAsFixed(0)} km/h   '
                    'gps ±${r.gpsAccuracy.toStringAsFixed(0)} m',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Dedicated Crash Simulation Button (Red)
              if (kDemoTools)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _simulateCrash,
                    icon: const Icon(Icons.warning_amber_rounded),
                    label: const Text(
                      'محاكاة حادث (اختبار)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Stop Protection Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.navy, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _snack('اضغط مطولاً للإيقاف'),
                  onLongPress: _stop,
                  child: const Text(
                    'إيقاف (اضغط مطولاً)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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

class _RoleToggle extends StatelessWidget {
  const _RoleToggle({required this.isDriver, required this.onChanged});
  final bool isDriver;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Segment(
            label: 'سائق',
            selected: isDriver,
            onTap: () => onChanged(true),
          ),
          _Segment(
            label: 'راكب',
            selected: !isDriver,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}