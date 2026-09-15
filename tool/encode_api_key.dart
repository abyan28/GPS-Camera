// Sandikan API key LocationIQ sebelum ditanam ke build rilis publik, supaya
// tidak tersimpan sebagai string polos di APK — lihat penjelasan lengkap di
// `lib/core/config/api_keys.dart` dan README.md.
//
// Cara pakai:
//   dart run tool/encode_api_key.dart <API_KEY_ASLI>
//
// Hasilnya dipakai lewat:
//   flutter build apk --dart-define=LOCATIONIQ_API_KEY_ENCODED=<hasil>
//
// PENTING: algoritma di sini harus identik dengan `_decodeApiKey` di
// `lib/core/config/api_keys.dart` (XOR + base64), kalau salah satu diubah,
// yang lain wajib ikut diubah.

import 'dart:convert';
import 'dart:io';

const _obfuscationPassphrase = 'GeoPatriot-2026-watermark-camera';

String _encode(String plainText, String passphrase) {
  final bytes = utf8.encode(plainText);
  final keyBytes = utf8.encode(passphrase);
  final encoded = List<int>.generate(
    bytes.length,
    (i) => bytes[i] ^ keyBytes[i % keyBytes.length],
  );
  return base64.encode(encoded);
}

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Pemakaian: dart run tool/encode_api_key.dart <API_KEY_ASLI>');
    exit(1);
  }

  final encoded = _encode(args.first, _obfuscationPassphrase);
  // ignore: avoid_print
  print(encoded);
}
