import 'package:flutter/material.dart';

/// Token desain semantik khusus antarmuka kamera (HUD), kontrol mengambang,
/// dan status akurasi GPS.
class CameraTokens {
  CameraTokens._();

  // --- Latar Belakang & Chrome HUD ---
  /// Latar belakang gelap semi-transparan untuk kontrol mengambang (pill, tombol bulat).
  static final Color hudBackground = Colors.black.withValues(alpha: 0.55);

  /// Warna batas halus pada kontrol mengambang untuk kontras terhadap preview terang.
  static final Color hudBorder = Colors.white.withValues(alpha: 0.20);

  /// Latar belakang canvas kamera murni gelap.
  static const Color canvasBlack = Colors.black;

  // --- Tombol Rana (Shutter) ---
  /// Cincin luar tombol rana saat kondisi normal.
  static const Color shutterRing = Colors.white;

  /// Warna inti dalam tombol rana saat kondisi normal.
  static const Color shutterInner = Colors.white;

  /// Warna aksen saat tombol rana ditekan/aktif.
  static const Color shutterPressed = Color(0xFFE0E0E0);

  // --- Status Akurasi GPS ---
  /// Akurasi sangat baik (< 5 meter) - Hijau terang.
  static const Color gpsExcellent = Color(0xFF00E676);

  /// Akurasi baik (5 - 15 meter) - Biru muda.
  static const Color gpsGood = Color(0xFF29B6F6);

  /// Akurasi cukup (15 - 50 meter) - Kuning/Amber.
  static const Color gpsFair = Color(0xFFFFCA28);

  /// Akurasi kurang (> 50 meter) - Merah.
  static const Color gpsPoor = Color(0xFFFF5252);

  /// Sedang mencari sinyal satelit / belum terkunci - Abu-abu netral.
  static const Color gpsSearching = Color(0xFFB0BEC5);

  // --- Tipografi & Teks HUD ---
  /// Teks berpenekanan tinggi (judul, angka koordinat).
  static const Color textHighEmphasis = Colors.white;

  /// Teks berpenekanan sedang (alamat, timestamp).
  static final Color textMediumEmphasis = Colors.white.withValues(alpha: 0.85);

  /// Teks berpenekanan rendah (label sekunder, watermark attribution).
  static final Color textLowEmphasis = Colors.white.withValues(alpha: 0.60);
}
