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

  /// Deteksi template aktif berdasarkan kecocokan konfigurasi field data watermark saat ini.
  WatermarkTemplate? get activeTemplate {
    for (final template in WatermarkTemplate.values) {
      final config = template.configuration;
      if (settings.watermark.showLocationName == config.showLocationName &&
          settings.watermark.showAddress == config.showAddress &&
          settings.watermark.showCoordinates == config.showCoordinates &&
          settings.watermark.showDate == config.showDate &&
          settings.watermark.showTime == config.showTime &&
          settings.watermark.showTimezone == config.showTimezone &&
          settings.watermark.showAccuracy == config.showAccuracy &&
          settings.watermark.showAltitude == config.showAltitude &&
          settings.watermark.showMapThumbnail == config.showMapThumbnail) {
        return template;
      }
    }
    return null;
  }

  /// Kembalikan seluruh pengaturan ke setelan awal default pabrik.
  Future<void> resetToDefaults() async {
    await _update(AppSettings.defaults());
  }

  Future<void> _update(AppSettings updated) async {
    settings = updated;
    notifyListeners();
    await _service.save(updated);
  }
}
