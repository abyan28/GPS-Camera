/// API key pihak ketiga, dibaca dari `--dart-define` saat build/run, tidak
/// pernah di-hardcode atau di-commit ke source control. Kosong secara
/// default; provider yang membutuhkan key ini wajib mengembalikan `null`
/// dengan aman (bukan crash) jika key belum di-set.
///
/// Cara pakai: `flutter run --dart-define=LOCATIONIQ_API_KEY=xxxxx`
const locationIqApiKey = String.fromEnvironment('LOCATIONIQ_API_KEY');
