import '../core/cache/coordinate_cache.dart';
import 'geocoding_provider.dart';
import 'models/address_snapshot.dart';

/// Bungkus [GeocodingProvider] apa pun dengan cache berbasis koordinat,
/// supaya lokasi yang praktis sama tidak memicu request berulang.
class CachedGeocodingProvider implements GeocodingProvider {
  CachedGeocodingProvider(this._inner, {CoordinateCache<AddressSnapshot>? cache})
      : _cache = cache ?? CoordinateCache<AddressSnapshot>();

  final GeocodingProvider _inner;
  final CoordinateCache<AddressSnapshot> _cache;

  /// Kembalikan alamat dari cache jika tersedia dan masih valid; jika
  /// tidak, minta ke provider asli lalu simpan hasilnya ke cache.
  @override
  Future<AddressSnapshot?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final cached = _cache.get(latitude, longitude);
    if (cached != null) return cached;

    final result = await _inner.reverseGeocode(latitude: latitude, longitude: longitude);
    if (result != null) {
      _cache.set(latitude, longitude, result);
    }
    return result;
  }

  /// Bersihkan cache alamat (dipakai untuk fitur "clear cache" di privacy).
  void clearCache() => _cache.clear();
}
