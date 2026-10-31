import 'package:najda/data/constants.dart';

/// "12345-123-16" -> "16 - الجزائر" (null if plate incomplete/unknown)
String? wilayaFromPlate(String plate) {
  final parts = plate.split('-');
  if (parts.length != 3 || parts[2].length != 2) return null;
  final code = int.tryParse(parts[2]);
  if (code == null || !wilayas.containsKey(code)) return null;
  return '${parts[2]} - ${wilayas[code]}';
}

bool isGplFuel(String? fuel) => fuel != null && fuel.contains('GPL');
