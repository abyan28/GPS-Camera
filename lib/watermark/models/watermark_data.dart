import '../../geocoding/models/address_snapshot.dart';
import '../../location/models/location_snapshot.dart';
import '../../map/models/map_snapshot.dart';

/// Seluruh data non-visual yang dibutuhkan watermark renderer untuk satu
/// foto. Renderer hanya menerima data lewat model ini, tidak pernah
/// mengambil GPS/HTTP sendiri.
class WatermarkData {
  const WatermarkData({
    required this.location,
    required this.timestamp,
    required this.timeZoneName,
    this.address,
    this.map,
  });

  final LocationSnapshot location;
  final DateTime timestamp;
  final String timeZoneName;

  /// Null jika reverse geocoding belum tersedia/gagal/offline.
  final AddressSnapshot? address;

  /// Null jika map thumbnail belum tersedia/gagal/offline.
  final MapSnapshot? map;
}
