import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'camera/camera_screen.dart';
import 'core/theme/app_theme.dart';
import 'history/history_screen.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_screen.dart';

class GeotagCameraApp extends StatelessWidget {
  const GeotagCameraApp({super.key});

  /// Bangun root widget aplikasi: provider pengaturan global, tema, route
  /// awal, dan daftar navigasi.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsController(),
      child: MaterialApp(
        title: 'Geotag Camera',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        initialRoute: '/',
        routes: {
          '/': (context) => const CameraScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/history': (context) => const HistoryScreen(),
        },
      ),
    );
  }
}
