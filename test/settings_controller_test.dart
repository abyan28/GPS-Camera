import 'package:flutter_test/flutter_test.dart';
import 'package:geotag_camera/settings/settings_controller.dart';
import 'package:geotag_camera/settings/settings_service.dart';
import 'package:geotag_camera/watermark/models/watermark_template.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('SettingsController mendeteksi template aktif dan bisa applyTemplate', () async {
    final controller = SettingsController(service: SettingsService());
    // Tunggu asynchronous load dari disk
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Default template saat awal
    expect(controller.activeTemplate, WatermarkTemplate.defaultTemplate);

    // Terapkan template ringkas (compact)
    await controller.applyTemplate(WatermarkTemplate.compact);
    expect(controller.activeTemplate, WatermarkTemplate.compact);
    expect(controller.settings.watermark.showLocationName, isFalse);
    expect(controller.settings.watermark.showMapThumbnail, isFalse);

    // Terapkan template detail
    await controller.applyTemplate(WatermarkTemplate.detail);
    expect(controller.activeTemplate, WatermarkTemplate.detail);
    expect(controller.settings.watermark.showAltitude, isTrue);
  });

  test('SettingsController.resetToDefaults mengembalikan ke setelan awal', () async {
    final controller = SettingsController(service: SettingsService());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Ubah sebagian konfigurasi
    await controller.setSaveOriginal(true);
    await controller.applyTemplate(WatermarkTemplate.compact);
    expect(controller.settings.saveOriginal, isTrue);
    expect(controller.activeTemplate, WatermarkTemplate.compact);

    // Reset ke default
    await controller.resetToDefaults();
    expect(controller.settings.saveOriginal, isFalse);
    expect(controller.activeTemplate, WatermarkTemplate.defaultTemplate);
  });
}
