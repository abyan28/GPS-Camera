import 'package:flutter_test/flutter_test.dart';
import 'package:geotag_camera/core/network/safe_fetch.dart';

void main() {
  test('mengembalikan hasil normal jika action berhasil', () async {
    final result = await fetchSafely<String>(() async => 'alamat ditemukan');

    expect(result, 'alamat ditemukan');
  });

  test('mengembalikan null jika action melempar exception (mis. offline)', () async {
    final result = await fetchSafely<String>(() async => throw Exception('tidak ada internet'));

    expect(result, isNull);
  });

  test('mengembalikan null jika action melebihi batas waktu, bukan menunggu tanpa batas', () async {
    final result = await fetchSafely<String>(
      () => Future.delayed(const Duration(seconds: 2), () => 'terlalu lambat'),
      timeout: const Duration(milliseconds: 50),
    );

    expect(result, isNull);
  });
}
