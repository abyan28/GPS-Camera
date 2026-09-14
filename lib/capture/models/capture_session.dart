import 'dart:io';

import '../../location/models/location_snapshot.dart';

/// Seluruh informasi satu hasil capture, dibekukan pada momen yang sama.
/// Address dan map thumbnail akan ditambahkan sebagai field terpisah pada
/// fase geocoding/map (lihat workflow-free-first.md Fase 7-8), sengaja
/// belum ditambahkan di sini karena belum ada konsumennya.
class CaptureSession {
  const CaptureSession({
    required this.imageFile,
    required this.location,
    required this.timestamp,
    required this.timeZoneName,
  });

  final File imageFile;
  final LocationSnapshot location;
  final DateTime timestamp;
  final String timeZoneName;
}
