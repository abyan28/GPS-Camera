/// Cache in-memory generik berbasis koordinat, dipakai untuk hasil
/// reverse geocoding dan map thumbnail. Precision pembulatan koordinat
/// mencegah perubahan lokasi beberapa sentimeter dianggap sebagai lokasi
/// berbeda. Cache habis sendiri saat app ditutup (bukan sumber kebenaran
/// permanen), dan bisa dibersihkan manual lewat [clear].
class CoordinateCache<T> {
  CoordinateCache({
    this.ttl = const Duration(hours: 24),
    this.precisionDecimals = 4,
  });

  /// Berapa lama satu entri cache dianggap masih valid.
  final Duration ttl;

  /// Jumlah digit desimal untuk pembulatan koordinat sebagai cache key.
  /// 4 digit ≈ 11 meter, cukup untuk menganggap lokasi "praktis sama".
  final int precisionDecimals;

  final Map<String, _CacheEntry<T>> _store = {};

  /// Buat cache key dari koordinat yang dibulatkan ke [precisionDecimals].
  /// [extra] opsional ikut jadi bagian key — dipakai saat hasil yang
  /// di-cache juga bergantung pada parameter lain selain koordinat (mis.
  /// level zoom untuk thumbnail peta), supaya kombinasi yang berbeda tidak
  /// dianggap cache hit yang sama.
  String keyFor(double latitude, double longitude, {String extra = ''}) {
    final base = '${latitude.toStringAsFixed(precisionDecimals)},'
        '${longitude.toStringAsFixed(precisionDecimals)}';
    return extra.isEmpty ? base : '$base|$extra';
  }

  /// Ambil nilai tersimpan untuk koordinat ini, atau null jika belum ada
  /// atau sudah kedaluwarsa.
  T? get(double latitude, double longitude, {String extra = ''}) {
    final key = keyFor(latitude, longitude, extra: extra);
    final entry = _store[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.storedAt) > ttl) {
      _store.remove(key);
      return null;
    }
    return entry.value;
  }

  /// Simpan nilai baru untuk koordinat ini, menimpa entri lama jika ada.
  void set(double latitude, double longitude, T value, {String extra = ''}) {
    _store[keyFor(latitude, longitude, extra: extra)] = _CacheEntry(value, DateTime.now());
  }

  /// Bersihkan seluruh isi cache (dipakai untuk privacy: "cache lokal harus
  /// dapat dibersihkan").
  void clear() => _store.clear();
}

class _CacheEntry<T> {
  _CacheEntry(this.value, this.storedAt);

  final T value;
  final DateTime storedAt;
}
