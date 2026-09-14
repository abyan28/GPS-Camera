import 'package:flutter/foundation.dart';

import '../watermark/models/watermark_configuration.dart';
import '../watermark/models/watermark_template.dart';
import 'models/app_settings.dart';
import 'settings_service.dart';

/// Sumber kebenaran tunggal untuk pengaturan aplikasi, dibagikan lewat
/// Provider ke Camera (baca konfigurasi watermark saat capture) dan
/// Settings (baca+ubah). Setiap perubahan langsung dipersist.
class SettingsController extends ChangeNotifier {
  SettingsController({SettingsService? service}) : _service = service ?? SettingsService() {
    _loadFromDisk();
  }

  final SettingsService _service;

  AppSettings settings = AppSettings.defaults();
  bool isLoaded = false;

  Future<void> _loadFromDisk() async {
    settings = await _service.load();
    isLoaded = true;
    notifyListeners();
  }

  /// Ganti seluruh konfigurasi watermark ke salah satu template siap pakai.
  Future<void> applyTemplate(WatermarkTemplate template) async {
    await _update(settings.copyWith(watermark: template.configuration));
  }

  /// Ubah sebagian field konfigurasi watermark (dipakai toggle/slider di
  /// layar Settings), mempertahankan field lain yang tidak diubah.
  Future<void> updateWatermark(WatermarkConfiguration Function(WatermarkConfiguration current) update) async {
    await _update(settings.copyWith(watermark: update(settings.watermark)));
  }

  /// Aktif/nonaktifkan penyimpanan foto original.
  Future<void> setSaveOriginal(bool value) async {
    await _update(settings.copyWith(saveOriginal: value));
  }

  Future<void> _update(AppSettings updated) async {
    settings = updated;
    notifyListeners();
    await _service.save(updated);
  }
}
