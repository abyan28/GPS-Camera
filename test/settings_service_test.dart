import 'package:flutter_test/flutter_test.dart';
import 'package:geotag_camera/settings/models/app_settings.dart';
import 'package:geotag_camera/settings/settings_service.dart';
import 'package:geotag_camera/watermark/models/watermark_position.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('load() mengembalikan default jika belum pernah disimpan', () async {
    final service = SettingsService();

    final settings = await service.load();

    expect(settings.saveOriginal, isTrue);
    expect(settings.watermark.position, WatermarkPosition.bottom);
  });

  test('save() lalu load() mengembalikan nilai yang sama persis', () async {
    final service = SettingsService();
    final original = AppSettings.defaults().copyWith(
      saveOriginal: false,
      watermark: AppSettings.defaults().watermark.copyWith(
            showAltitude: true,
            position: WatermarkPosition.topRight,
            opacity: 0.8,
          ),
    );

    await service.save(original);
    final loaded = await service.load();

    expect(loaded.saveOriginal, isFalse);
    expect(loaded.watermark.showAltitude, isTrue);
    expect(loaded.watermark.position, WatermarkPosition.topRight);
    expect(loaded.watermark.opacity, 0.8);
  });

  test('data rusak di storage tidak menyebabkan crash, jatuh ke default', () async {
    SharedPreferences.setMockInitialValues({'app_settings_json': 'bukan json valid'});
    final service = SettingsService();

    final settings = await service.load();

    expect(settings.saveOriginal, isTrue);
  });
}
