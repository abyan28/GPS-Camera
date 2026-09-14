import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import 'map_thumbnail_provider.dart';
import 'models/map_snapshot.dart';

/// Implementasi [MapThumbnailProvider] dengan menyusun raster tile dari
/// `tile.openstreetmap.org` (slippy map standar) menjadi satu thumbnail
/// kecil dengan marker di tengah.
///
/// PENTING (lihat agents/rules-free-first.md §12): `tile.openstreetmap.org`
/// adalah server utama OSMF dengan usage policy ketat (tidak untuk trafik
/// produksi berskala besar, wajib User-Agent jelas, wajib cache, dilarang
/// bulk download). Implementasi ini cocok untuk pengembangan/skala kecil.
/// Sebelum rilis dengan basis pengguna besar, ganti dengan provider raster
/// OSM-derived yang memang menyediakan layanan aplikasi (mis. layanan tile
/// komersial berbasis OSM), tanpa mengubah kode di luar kelas ini karena
/// sudah berada di balik [MapThumbnailProvider].
class OsmRasterMapThumbnailProvider implements MapThumbnailProvider {
  OsmRasterMapThumbnailProvider({http.Client? client, this.thumbnailSizePx = 240})
      : _client = client ?? http.Client();

  static const _tileSize = 256;
  static const _userAgent = 'GPSCamera/1.0 (contact: set-your-contact-email@example.com)';
  static const _attribution = '© OpenStreetMap contributors';

  final http.Client _client;

  /// Ukuran sisi thumbnail persegi yang dihasilkan, dalam pixel.
  final int thumbnailSizePx;

  /// Ambil tile-tile di sekitar koordinat, susun jadi satu gambar, potong
  /// pas di tengah koordinat, lalu gambar marker. Gagal secara diam
  /// (return null) untuk error jaringan apa pun.
  @override
  Future<MapSnapshot?> fetchThumbnail({
    required double latitude,
    required double longitude,
    int zoom = 16,
  }) async {
    try {
      final globalPixel = _globalPixelFor(latitude, longitude, zoom);
      final centerTileX = (globalPixel.dx / _tileSize).floor();
      final centerTileY = (globalPixel.dy / _tileSize).floor();
      final maxTileIndex = (1 << zoom) - 1;

      // Ambil grid 3x3 tile di sekitar titik pusat, cukup untuk memotong
      // thumbnail berapa pun ukurannya sampai sekitar 2x lebar satu tile.
      final composite = img.Image(width: _tileSize * 3, height: _tileSize * 3);
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          final tileX = (centerTileX + dx).clamp(0, maxTileIndex);
          final tileY = (centerTileY + dy).clamp(0, maxTileIndex);
          final tile = await _fetchTile(tileX, tileY, zoom);
          if (tile == null) continue;
          img.compositeImage(
            composite,
            tile,
            dstX: (dx + 1) * _tileSize,
            dstY: (dy + 1) * _tileSize,
          );
        }
      }

      final centerXInComposite = _tileSize + (globalPixel.dx - centerTileX * _tileSize);
      final centerYInComposite = _tileSize + (globalPixel.dy - centerTileY * _tileSize);

      final half = thumbnailSizePx ~/ 2;
      final cropped = img.copyCrop(
        composite,
        x: (centerXInComposite - half).round(),
        y: (centerYInComposite - half).round(),
        width: thumbnailSizePx,
        height: thumbnailSizePx,
      );

      _drawMarker(cropped);

      return MapSnapshot(
        imageBytes: Uint8List.fromList(img.encodePng(cropped)),
        attributionText: _attribution,
      );
    } catch (_) {
      return null;
    }
  }

  /// Unduh satu raster tile PNG. Kembalikan null jika request gagal supaya
  /// pemanggil cukup melewati tile tersebut (thumbnail tetap terbentuk
  /// dengan area kosong daripada gagal total).
  Future<img.Image?> _fetchTile(int tileX, int tileY, int zoom) async {
    final uri = Uri.parse('https://tile.openstreetmap.org/$zoom/$tileX/$tileY.png');
    final response = await _client
        .get(uri, headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    return img.decodePng(response.bodyBytes);
  }

  /// Hitung posisi pixel global (di seluruh peta pada level zoom tertentu)
  /// untuk satu koordinat, menggunakan proyeksi Web Mercator standar.
  ({double dx, double dy}) _globalPixelFor(double latitude, double longitude, int zoom) {
    final scale = (_tileSize * (1 << zoom)).toDouble();
    final x = (longitude + 180.0) / 360.0 * scale;
    final latRad = latitude * pi / 180.0;
    final y = (1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / pi) / 2.0 * scale;
    return (dx: x, dy: y);
  }

  /// Gambar marker lokasi (lingkaran merah dengan inti putih) tepat di
  /// tengah thumbnail.
  void _drawMarker(img.Image image) {
    final cx = image.width ~/ 2;
    final cy = image.height ~/ 2;
    img.fillCircle(image, x: cx, y: cy, radius: 7, color: img.ColorRgba8(211, 47, 47, 255));
    img.fillCircle(image, x: cx, y: cy, radius: 3, color: img.ColorRgba8(255, 255, 255, 255));
  }
}
