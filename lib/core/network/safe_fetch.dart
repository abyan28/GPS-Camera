/// Jalankan [action] dengan batas waktu [timeout]; kembalikan `null` untuk
/// exception maupun timeout apa pun, tidak pernah melempar ke pemanggil.
/// Dipakai untuk semua layanan online opsional (geocoding, map thumbnail)
/// supaya kegagalan jaringan tidak pernah menghalangi capture
/// (rules-free-first.md §15-16: dilarang infinite loading/menunggu tanpa batas).
Future<T?> fetchSafely<T>(
  Future<T?> Function() action, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  try {
    return await action().timeout(timeout);
  } catch (_) {
    return null;
  }
}
