import 'dart:typed_data';

/// Hasil thumbnail peta untuk satu koordinat: gambar (sudah termasuk marker
/// lokasi) plus teks attribution yang wajib ditampilkan bersamanya.
class MapSnapshot {
  const MapSnapshot({required this.imageBytes, required this.attributionText});

  /// Bytes gambar PNG thumbnail, siap dikomposisikan ke watermark.
  final Uint8List imageBytes;

  /// Teks attribution provider peta (wajib tetap terlihat di watermark).
  final String attributionText;
}
