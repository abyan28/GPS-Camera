import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_keys.dart';
import 'map_thumbnail_provider.dart';
import 'models/map_snapshot.dart';

/// Implementasi [MapThumbnailProvider] menggunakan static map image dari
/// LocationIQ (https://locationiq.com), sudah termasuk marker lokasi dalam
/// satu response gambar (tidak perlu stitching tile manual). Dipilih
/// setelah tile.openstreetmap.org publik terbukti membalas gambar
/// "diblokir" pengganti alih-alih peta asli (lihat agents/tasklist.md).
class LocationIqMapThumbnailProvider implements MapThumbnailProvider {
  LocationIqMapThumbnailProvider({http.Client? client, this.thumbnailSizePx = 240})
      : _client = client ?? http.Client();

  static const _endpoint = 'https://maps.locationiq.com/v3/staticmap';
  // Tanpa simbol "©": bitmap font watermark tidak punya glyph untuk
  // karakter itu (dirender kosong tapi tetap makan lebar, menyebabkan
  // celah aneh sebelum "LocationIQ"). Kredit tetap wajib ada sesuai ToS.
  static const _attribution = 'LocationIQ, OpenStreetMap contributors';

  final http.Client _client;

  /// Ukuran sisi thumbnail persegi yang dihasilkan, dalam pixel.
  final int thumbnailSizePx;

  /// Minta satu gambar static map berpusat pada koordinat, sudah dengan
  /// marker. Kembalikan null tanpa mencoba request jika API key belum
  /// di-set, atau jika terjadi error/timeout apa pun.
  @override
  Future<MapSnapshot?> fetchThumbnail({
    required double latitude,
    required double longitude,
    int zoom = 16,
  }) async {
    if (locationIqApiKey.isEmpty) {
      debugPrint('[LocationIqMapThumbnailProvider] API key kosong, lewati request.');
      return null;
    }

    final center = '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'key': locationIqApiKey,
      'center': center,
      'zoom': '$zoom',
      'size': '${thumbnailSizePx}x$thumbnailSizePx',
      'format': 'png',
      'markers': 'icon:small-red-cutout|$center',
    });

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      debugPrint(
        '[LocationIqMapThumbnailProvider] status=${response.statusCode} bytes=${response.bodyBytes.length}',
      );
      if (response.statusCode != 200) return null;

      return MapSnapshot(imageBytes: response.bodyBytes, attributionText: _attribution);
    } catch (e) {
      debugPrint('[LocationIqMapThumbnailProvider] Exception: $e');
      return null;
    }
  }
}
