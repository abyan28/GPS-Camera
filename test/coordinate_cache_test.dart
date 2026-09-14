import 'package:flutter_test/flutter_test.dart';
import 'package:geotag_camera/core/cache/coordinate_cache.dart';

void main() {
  test('koordinat yang praktis sama menggunakan cache key yang sama', () {
    final cache = CoordinateCache<String>(precisionDecimals: 4);
    cache.set(-6.914744, 107.609810, 'alamat A');

    // Beda beberapa sentimeter, masih dianggap lokasi sama pada presisi 4 digit.
    final hit = cache.get(-6.9147441, 107.6098099);

    expect(hit, 'alamat A');
  });

  test('koordinat yang jelas berbeda tidak mengenai cache', () {
    final cache = CoordinateCache<String>(precisionDecimals: 4);
    cache.set(-6.914744, 107.609810, 'alamat A');

    final miss = cache.get(-6.920000, 107.615000);

    expect(miss, isNull);
  });

  test('entri yang sudah melewati TTL dianggap tidak ada', () async {
    final cache = CoordinateCache<String>(ttl: const Duration(milliseconds: 10));
    cache.set(-6.914744, 107.609810, 'alamat A');

    await Future.delayed(const Duration(milliseconds: 30));

    expect(cache.get(-6.914744, 107.609810), isNull);
  });

  test('clear membersihkan seluruh isi cache', () {
    final cache = CoordinateCache<String>();
    cache.set(-6.914744, 107.609810, 'alamat A');

    cache.clear();

    expect(cache.get(-6.914744, 107.609810), isNull);
  });
}
