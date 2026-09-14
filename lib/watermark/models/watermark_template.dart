import 'watermark_configuration.dart';

/// Pilihan template watermark siap pakai untuk layar Settings.
enum WatermarkTemplate {
  defaultTemplate,
  compact,
  detail;

  /// Label Indonesia untuk ditampilkan di UI pemilihan template.
  String get label {
    switch (this) {
      case WatermarkTemplate.defaultTemplate:
        return 'Default';
      case WatermarkTemplate.compact:
        return 'Ringkas';
      case WatermarkTemplate.detail:
        return 'Detail';
    }
  }

  /// Konfigurasi watermark bawaan untuk template ini.
  WatermarkConfiguration get configuration {
    switch (this) {
      case WatermarkTemplate.defaultTemplate:
        return WatermarkConfiguration.defaultTemplate();
      case WatermarkTemplate.compact:
        return WatermarkConfiguration.compact();
      case WatermarkTemplate.detail:
        return WatermarkConfiguration.detail();
    }
  }
}
