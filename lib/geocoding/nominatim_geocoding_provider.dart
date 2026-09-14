import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'geocoding_provider.dart';
import 'models/address_snapshot.dart';

/// Implementasi [GeocodingProvider] menggunakan public Nominatim
/// (https://nominatim.openstreetmap.org). Ini adalah layanan publik dengan
/// policy penggunaan ketat: maksimal 1 request/detik, User-Agent yang jelas,
/// dan tidak untuk trafik besar. Sebelum rilis produksi dengan basis
/// pengguna besar, ganti dengan instance Nominatim sendiri atau provider
/// OSM-compatible lain (lihat agents/rules-free-first.md §11).
///
/// PENTING: ganti [_userAgent] dengan identitas aplikasi/kontak nyata
/// sebelum rilis, sesuai wajib policy Nominatim.
class NominatimGeocodingProvider implements GeocodingProvider {
  NominatimGeocodingProvider({http.Client? client}) : _client = client ?? http.Client();

  static const _endpoint = 'https://nominatim.openstreetmap.org/reverse';
  static const _userAgent = 'GPSCamera/1.0 (contact: set-your-contact-email@example.com)';
  static const _minRequestGap = Duration(seconds: 1);

  final http.Client _client;
  static DateTime? _lastRequestAt;

  /// Ambil alamat dari Nominatim untuk satu koordinat. Menghormati rate
  /// limit publik (1 request/detik), timeout 8 detik, dan gagal secara diam
  /// (return null) jika terjadi error apa pun supaya capture tidak terhalang.
  @override
  Future<AddressSnapshot?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    await _respectRateLimit();

    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'format': 'jsonv2',
      'lat': latitude.toStringAsFixed(6),
      'lon': longitude.toStringAsFixed(6),
      'zoom': '18',
      'addressdetails': '1',
    });

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        debugPrint(
          '[NominatimGeocodingProvider] Gagal, status=${response.statusCode}, '
          'body="${_shortSnippet(response.body)}"',
        );
        return null;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final address = decoded['address'] as Map<String, dynamic>?;
      if (address == null) {
        debugPrint(
          '[NominatimGeocodingProvider] Response 200 tapi tidak ada field '
          '"address", body="${_shortSnippet(response.body)}"',
        );
        return null;
      }

      return _mapToSnapshot(address);
    } catch (e) {
      debugPrint('[NominatimGeocodingProvider] Exception: $e');
      return null;
    }
  }

  /// Potong teks diagnostik supaya log tidak kebanjiran, cukup untuk
  /// membaca pesan error tanpa mencatat body lengkap.
  String _shortSnippet(String text) {
    return text.length <= 200 ? text : '${text.substring(0, 200)}...';
  }

  /// Petakan field address Nominatim (yang bervariasi antar wilayah) ke
  /// struktur administrasi Indonesia yang dipakai aplikasi. Field yang tidak
  /// ada pada response tetap null, tidak dikarang.
  AddressSnapshot _mapToSnapshot(Map<String, dynamic> address) {
    String? asString(String key) => address[key] as String?;

    return AddressSnapshot(
      street: asString('road'),
      village: asString('village') ?? asString('suburb') ?? asString('hamlet'),
      district: asString('city_district') ?? asString('suburb'),
      regency: asString('county') ?? asString('city') ?? asString('state_district'),
      province: asString('state'),
      country: asString('country'),
    );
  }

  /// Tunggu bila perlu supaya jeda antar request ke public Nominatim tidak
  /// kurang dari 1 detik, sesuai kewajiban policy-nya.
  Future<void> _respectRateLimit() async {
    final lastRequest = _lastRequestAt;
    if (lastRequest != null) {
      final elapsed = DateTime.now().difference(lastRequest);
      if (elapsed < _minRequestGap) {
        await Future.delayed(_minRequestGap - elapsed);
      }
    }
    _lastRequestAt = DateTime.now();
  }
}
