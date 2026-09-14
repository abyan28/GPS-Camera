import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

/// Titik masuk aplikasi: siapkan binding Flutter dan data locale Indonesia
/// sebelum menjalankan widget tree.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(const GeotagCameraApp());
}
