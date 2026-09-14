import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/app_settings.dart';

/// Baca/tulis [AppSettings] ke penyimpanan lokal perangkat lewat
/// shared_preferences, supaya pengaturan bertahan setelah aplikasi ditutup.
class SettingsService {
  static const _key = 'app_settings_json';

  /// Muat pengaturan tersimpan, atau nilai default jika belum pernah
  /// disimpan atau datanya rusak.
  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return AppSettings.defaults();

    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings.defaults();
    }
  }

  /// Simpan pengaturan saat ini ke penyimpanan lokal.
  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
