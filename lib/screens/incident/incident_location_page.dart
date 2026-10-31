import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:najda/globals.dart';
import 'ai_analysis_page.dart';
import 'package:najda/widgets/app_bar.dart';
import 'package:najda/widgets/app_button.dart';
import 'package:najda/widgets/app_card.dart';
import 'package:najda/widgets/fake_map.dart';

class IncidentLocationPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double impactG;
  final double speedKmh;
  final File? imageFile;
  final Map<String, dynamic>? aiData;

  const IncidentLocationPage({
    super.key,
    this.latitude = 36.7538,
    this.longitude = 3.0588,
    this.impactG = 6.8,
    this.speedKmh = 75.0,
    this.imageFile,
    this.aiData,
  });

  @override
  State<IncidentLocationPage> createState() => _IncidentLocationPageState();
}

class _IncidentLocationPageState extends State<IncidentLocationPage> {
  late double _lat;
  late double _lng;
  bool _isLoadingGps = false;

  @override
  void initState() {
    super.initState();
    _lat = widget.latitude;
    _lng = widget.longitude;
    _fetchLiveGps();
  }

  Future<void> _fetchLiveGps() async {
    try {
      setState(() => _isLoadingGps = true);
      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
          _isLoadingGps = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarOf('موقع الحادث', actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchLiveGps),
      ]),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                const FakeMap(pins: [
                  MapPin(0.5, 0.52, Icons.location_on, emergencyColor, size: 54),
                ]),
                Align(
                  alignment: const Alignment(0, -0.45),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(blurRadius: 8, color: Colors.black12)
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'موقع الحادث المؤكد',
                          style: TextStyle(
                            color: emergencyColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            _isLoadingGps
                                ? 'جاري تحديث الموقع...'
                                : '${_lat.toStringAsFixed(4)}° N, ${_lng.toStringAsFixed(4)}° E',
                            style: const TextStyle(color: mutedColor, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.imageFile != null && widget.imageFile!.existsSync()) ...[
                    const Text(
                      'الصورة الملتقطة للحادث',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        widget.imageFile!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'معلومات الحادث الحالية',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Column(
                      children: [
                        InfoRow('قوة الاصطدام', '${widget.impactG.toStringAsFixed(1)} G'),
                        InfoRow('السرعة قبل الحادث', '${widget.speedKmh.toStringAsFixed(0)} كم/س'),
                        const InfoRow('حالة الاستجابة', 'تم التنبيه والتصوير بنجاح'),
                        const InfoRow('حالة الطريق', 'جاري التحقق', valueColor: secondaryColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'عرض تحليل الذكاء الاصطناعي',
                    color: secondaryColor,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AiAnalysisPage(
                          aiData: widget.aiData,
                          localImageFile: widget.imageFile,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}