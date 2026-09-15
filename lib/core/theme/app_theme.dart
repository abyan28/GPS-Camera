import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  /// Tema terang default aplikasi. Warna netral/fungsional untuk aplikasi
  /// utilitas, bukan branding akhir.
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }

  /// Tema gelap, dipakai otomatis saat HP pengguna dalam mode gelap
  /// (lihat `themeMode: ThemeMode.system` di `app.dart`) — mis. panel info
  /// detail foto di Riwayat ikut jadi gelap, bukan selalu putih.
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }
}
