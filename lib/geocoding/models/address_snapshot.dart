/// Struktur alamat internal aplikasi, hasil pemetaan dari response provider
/// geocoding apa pun. UI dan watermark engine hanya boleh bergantung pada
/// model ini, tidak pernah pada response mentah provider.
class AddressSnapshot {
  const AddressSnapshot({
    this.street,
    this.village,
    this.district,
    this.regency,
    this.province,
    this.country,
    this.plusCode,
  });

  final String? street;
  final String? village;
  final String? district;
  final String? regency;
  final String? province;
  final String? country;
  final String? plusCode;

  /// true jika semua komponen kosong, artinya provider tidak mengembalikan
  /// informasi yang berguna sama sekali.
  bool get isEmpty =>
      street == null &&
      village == null &&
      district == null &&
      regency == null &&
      province == null &&
      country == null;
}
