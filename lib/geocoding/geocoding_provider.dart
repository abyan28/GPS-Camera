import 'models/address_snapshot.dart';

/// Abstraksi reverse geocoding. Core capture/watermark tidak boleh
/// bergantung pada provider tertentu (mis. Nominatim), hanya pada interface
/// ini, supaya provider dapat diganti tanpa mengubah domain lain.
abstract class GeocodingProvider {
  /// Kembalikan alamat untuk satu koordinat, atau `null` jika gagal/tidak
  /// ditemukan. Tidak boleh melempar exception ke pemanggil untuk kegagalan
  /// jaringan biasa (timeout, offline, rate limit): kembalikan `null` saja.
  Future<AddressSnapshot?> reverseGeocode({
    required double latitude,
    required double longitude,
  });
}
