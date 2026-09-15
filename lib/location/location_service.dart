import 'package:geolocator/geolocator.dart';

import 'models/location_snapshot.dart';

enum LocationAccessProblem {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

class LocationAccessException implements Exception {
  LocationAccessException(this.problem);

  final LocationAccessProblem problem;

  String get userMessage {
    switch (problem) {
      case LocationAccessProblem.serviceDisabled:
        return 'Lokasi belum tersedia. Pastikan GPS aktif lalu coba lagi.';
      case LocationAccessProblem.permissionDenied:
        return 'Izin lokasi ditolak. Aplikasi membutuhkan lokasi untuk menandai foto.';
      case LocationAccessProblem.permissionDeniedForever:
        return 'Izin lokasi diblokir permanen. Buka Pengaturan untuk mengaktifkannya.';
    }
  }
}

/// Membungkus `geolocator` supaya layer lain (UI, capture) tidak bergantung
/// langsung pada tipe/plugin lokasi tertentu.
class LocationService {
  /// Pastikan GPS aktif dan izin lokasi sudah diberikan. Melempar
  /// [LocationAccessException] dengan pesan yang jujur ke pengguna jika
  /// salah satu syarat tidak terpenuhi.
  Future<void> ensureAccessible() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationAccessException(LocationAccessProblem.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationAccessException(LocationAccessProblem.permissionDenied);
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationAccessException(LocationAccessProblem.permissionDeniedForever);
    }
  }

  /// Stream lokasi live untuk ditampilkan di camera screen. Pemanggil harus
  /// menangani error (mis. GPS mati) dan tetap membiarkan shutter aktif.
  Stream<LocationSnapshot> watchSnapshot() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).map((position) => _toSnapshot(position, isStale: false));
  }

  /// Ambil satu posisi untuk dibekukan sebagai [LocationSnapshot] saat shutter
  /// ditekan. Timeout dibatasi agar capture tidak menunggu GPS tanpa batas;
  /// jika timeout, fallback ke [lastKnown] dan tandai sebagai stale.
  Future<LocationSnapshot> freezeSnapshot({
    Position? lastKnown,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await ensureAccessible();

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(timeout);
      return _toSnapshot(position, isStale: false);
    } on Exception {
      final fallback = lastKnown ?? await Geolocator.getLastKnownPosition();
      if (fallback != null) {
        return _toSnapshot(fallback, isStale: true);
      }
      return LocationSnapshot(
        latitude: 0.0,
        longitude: 0.0,
        accuracy: null,
        capturedAt: DateTime.now(),
        isStale: true,
      );
    }
  }

  /// Konversi [Position] dari geolocator menjadi [LocationSnapshot] internal
  /// aplikasi, supaya layer lain tidak bergantung pada tipe plugin GPS.
  LocationSnapshot _toSnapshot(Position position, {required bool isStale}) {
    return LocationSnapshot(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      capturedAt: position.timestamp,
      isStale: isStale,
    );
  }
}
