import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

/// Titik masuk aplikasi: siapkan binding Flutter, kunci orientasi UI ke
/// portrait (standar aplikasi kamera; orientasi sensor tetap dipakai
/// terpisah untuk menandai rotasi foto hasil, lihat
/// CameraControllerService), dan siapkan data locale Indonesia sebelum
/// menjalankan widget tree.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initializeDateFormatting('id_ID');
  runApp(const GeotagCameraApp());
}
