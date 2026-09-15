import '../../watermark/models/watermark_configuration.dart';

/// Seluruh pengaturan aplikasi yang dipersist secara lokal: konfigurasi
/// watermark plus opsi penyimpanan foto original.
class AppSettings {
  const AppSettings({required this.watermark, required this.saveOriginal});

  final WatermarkConfiguration watermark;

  /// PRD §14 awalnya menyarankan default ON ("original tidak boleh hilang
  /// diam-diam"), tapi diubah jadi OFF atas permintaan eksplisit user
  /// (disetel mengikuti preferensi user sendiri yang sudah dicoba di device
  /// nyata) — foto original tetap bisa diaktifkan manual kapan saja lewat
  /// Pengaturan.
  final bool saveOriginal;

  factory AppSettings.defaults() => AppSettings(
        watermark: WatermarkConfiguration.defaultTemplate(),
        saveOriginal: false,
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
      saveOriginal: json['saveOriginal'] as bool? ?? false,
    );
  }
}
