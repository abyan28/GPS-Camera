import '../core/cache/coordinate_cache.dart';
import 'map_thumbnail_provider.dart';
import 'models/map_snapshot.dart';

/// Bungkus [MapThumbnailProvider] apa pun dengan cache berbasis koordinat,
/// supaya lokasi yang praktis sama tidak memicu request tile berulang.
class CachedMapThumbnailProvider implements MapThumbnailProvider {
  CachedMapThumbnailProvider(this._inner, {CoordinateCache<MapSnapshot>? cache})
      : _cache = cache ?? CoordinateCache<MapSnapshot>();

  final MapThumbnailProvider _inner;
  final CoordinateCache<MapSnapshot> _cache;

  /// Kembalikan thumbnail dari cache jika tersedia; jika tidak, minta ke
  /// provider asli lalu simpan hasilnya ke cache.
  @override
  Future<MapSnapshot?> fetchThumbnail({
    required double latitude,
    required double longitude,
    int zoom = 16,
  }) async {
    final cached = _cache.get(latitude, longitude);
    if (cached != null) return cached;

    final result = await _inner.fetchThumbnail(latitude: latitude, longitude: longitude, zoom: zoom);
    if (result != null) {
      _cache.set(latitude, longitude, result);
    }
    return result;
  }

  /// Bersihkan cache thumbnail (dipakai untuk fitur "clear cache" di privacy).
  void clearCache() => _cache.clear();
}
