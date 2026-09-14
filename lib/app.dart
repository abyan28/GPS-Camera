import 'package:flutter/material.dart';

import 'camera/camera_screen.dart';
import 'core/theme/app_theme.dart';
import 'history/history_screen.dart';
import 'settings/settings_screen.dart';

class GeotagCameraApp extends StatelessWidget {
  const GeotagCameraApp({super.key});

  /// Bangun root widget aplikasi: tema, route awal, dan daftar navigasi.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geotag Camera',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: '/',
      routes: {
        '/': (context) => const CameraScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/history': (context) => const HistoryScreen(),
      },
    );
  }
}
