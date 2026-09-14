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
}
