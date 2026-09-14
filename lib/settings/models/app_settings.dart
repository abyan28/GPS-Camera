import '../../watermark/models/watermark_configuration.dart';

/// Seluruh pengaturan aplikasi yang dipersist secara lokal: konfigurasi
/// watermark plus opsi penyimpanan foto original.
class AppSettings {
  const AppSettings({required this.watermark, required this.saveOriginal});

  final WatermarkConfiguration watermark;

  /// Default ON sesuai PRD §14: original tidak boleh hilang secara diam-diam.
  final bool saveOriginal;

  factory AppSettings.defaults() => AppSettings(
        watermark: WatermarkConfiguration.defaultTemplate(),
        saveOriginal: true,
      );

  AppSettings copyWith({WatermarkConfiguration? watermark, bool? saveOriginal}) {
    return AppSettings(
      watermark: watermark ?? this.watermark,
      saveOriginal: saveOriginal ?? this.saveOriginal,
    );
  }

  Map<String, dynamic> toJson() => {
        'watermark': watermark.toJson(),
        'saveOriginal': saveOriginal,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final watermarkJson = json['watermark'] as Map<String, dynamic>?;
    return AppSettings(
      watermark: watermarkJson != null
          ? WatermarkConfiguration.fromJson(watermarkJson)
          : WatermarkConfiguration.defaultTemplate(),
      saveOriginal: json['saveOriginal'] as bool? ?? true,
    );
  }
}
