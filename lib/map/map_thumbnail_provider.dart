import 'models/map_snapshot.dart';

/// Abstraksi penyedia thumbnail peta. Core capture/watermark tidak boleh
/// bergantung pada provider tertentu, hanya pada interface ini, supaya
/// provider peta dapat diganti tanpa mengubah domain lain.
abstract class MapThumbnailProvider {
  /// Kembalikan thumbnail peta berpusat pada koordinat ini, atau `null`
  /// jika gagal/tidak tersedia. Tidak boleh melempar exception untuk
  /// kegagalan jaringan biasa (timeout, offline): kembalikan `null` saja.
  Future<MapSnapshot?> fetchThumbnail({
    required double latitude,
    required double longitude,
    int zoom = 16,
  });
}
