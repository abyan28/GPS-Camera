import 'models/address_snapshot.dart';

/// Mengubah [AddressSnapshot] menjadi satu baris teks alamat siap tampil,
/// mengikuti format default Indonesia: `[Jalan], [Desa/Kelurahan],
/// [Kecamatan], [Kabupaten/Kota], [Provinsi], [Negara]`. Tidak pernah
/// mengarang komponen yang tidak ada; komponen kosong dilewati begitu saja.
class AddressFormatter {
  /// Susun alamat dari komponen yang tersedia, dengan panjang maksimum
  /// [maxLength] karakter supaya tidak merusak layout watermark. Sertakan
  /// nama jalan hanya jika [includeStreet] true (format ringkas biasanya
  /// tidak menampilkannya).
  String format(
    AddressSnapshot address, {
    bool includeStreet = false,
    int maxLength = 120,
  }) {
    final components = <String>[];

    void addIfNew(String? value) {
      if (value == null) return;
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      final alreadyPresent = components.any(
        (existing) => existing.toLowerCase() == trimmed.toLowerCase(),
      );
      if (!alreadyPresent) components.add(trimmed);
    }

    if (includeStreet) addIfNew(address.street);
    addIfNew(address.village);
    addIfNew(_withPrefix(address.district, 'Kecamatan'));
    addIfNew(address.regency);
    addIfNew(address.province);
    addIfNew(address.country ?? (components.isNotEmpty ? 'Indonesia' : null));

    if (components.isEmpty) return '';

    final joined = components.join(', ');
    return _truncate(joined, maxLength);
  }

  /// Tambahkan awalan (mis. "Kecamatan") hanya jika nilainya belum
  /// mengandung awalan tersebut, supaya tidak menjadi "Kecamatan Kecamatan X".
  String? _withPrefix(String? value, String prefix) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.toLowerCase().startsWith(prefix.toLowerCase())) return trimmed;
    return '$prefix $trimmed';
  }

  /// Potong teks yang melebihi [maxLength], memutus pada batas koma
  /// terdekat jika memungkinkan supaya komponen alamat tidak terpotong
  /// setengah kata.
  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    final cut = text.substring(0, maxLength);
    final lastComma = cut.lastIndexOf(',');
    final safeCut = lastComma > maxLength ~/ 2 ? cut.substring(0, lastComma) : cut;
    return '$safeCut…';
  }
}
