import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_keys.dart';
import 'geocoding_provider.dart';
import 'models/address_snapshot.dart';

/// Implementasi [GeocodingProvider] menggunakan LocationIQ
/// (https://locationiq.com), layanan reverse geocoding berbasis data OSM
/// yang memang didesain untuk dipakai aplikasi (butuh API key gratis).
/// Dipilih setelah Nominatim publik terbukti memblokir traffic aplikasi ini
/// (HTTP 403, lihat agents/tasklist.md untuk detail bukti).
class LocationIqGeocodingProvider implements GeocodingProvider {
  LocationIqGeocodingProvider({http.Client? client}) : _client = client ?? http.Client();

  static const _endpoint = 'https://us1.locationiq.com/v1/reverse';

  final http.Client _client;

  /// Ambil alamat dari LocationIQ untuk satu koordinat. Kembalikan null
  /// tanpa mencoba request jika API key belum di-set (lihat
  /// [locationIqApiKey]), atau jika terjadi error/timeout apa pun, supaya
  /// capture tidak pernah terhalang.
  @override
  Future<AddressSnapshot?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    if (locationIqApiKey.isEmpty) {
      debugPrint('[LocationIqGeocodingProvider] API key kosong, lewati request.');
      return null;
    }

    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'key': locationIqApiKey,
      'lat': latitude.toStringAsFixed(6),
      'lon': longitude.toStringAsFixed(6),
      'format': 'json',
      'addressdetails': '1',
      'accept-language': 'id',
    });

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        debugPrint(
          '[LocationIqGeocodingProvider] Gagal, status=${response.statusCode}, '
          'body="${_shortSnippet(response.body)}"',
        );
        return null;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final address = decoded['address'] as Map<String, dynamic>?;
      if (address == null) {
        debugPrint('[LocationIqGeocodingProvider] Response 200 tapi tidak ada field "address".');
        return null;
      }

      return _mapToSnapshot(address);
    } catch (e) {
      debugPrint('[LocationIqGeocodingProvider] Exception: $e');
      return null;
    }
  }

  /// Petakan field address LocationIQ (format kompatibel Nominatim) ke
  /// struktur administrasi Indonesia yang dipakai aplikasi. Field yang
  /// tidak ada pada response tetap null, tidak dikarang.
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

  /// Potong teks diagnostik supaya log tidak kebanjiran.
  String _shortSnippet(String text) {
    return text.length <= 200 ? text : '${text.substring(0, 200)}...';
  }
}
