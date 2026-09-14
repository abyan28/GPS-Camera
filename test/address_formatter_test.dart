import 'package:flutter_test/flutter_test.dart';
import 'package:geotag_camera/geocoding/address_formatter.dart';
import 'package:geotag_camera/geocoding/models/address_snapshot.dart';

void main() {
  final formatter = AddressFormatter();

  test('format alamat lengkap sesuai urutan Indonesia', () {
    const address = AddressSnapshot(
      village: 'Cipadung',
      district: 'Cibiru',
      regency: 'Kota Bandung',
      province: 'Jawa Barat',
      country: 'Indonesia',
    );

    expect(
      formatter.format(address),
      'Cipadung, Kecamatan Cibiru, Kota Bandung, Jawa Barat, Indonesia',
    );
  });

  test('field yang hilang dilewati, tidak mengarang komponen', () {
    const address = AddressSnapshot(village: 'Cipadung', province: 'Jawa Barat');

    expect(formatter.format(address), 'Cipadung, Jawa Barat, Indonesia');
  });

  test('tidak menduplikasi komponen dengan nama sama', () {
    const address = AddressSnapshot(village: 'Bandung', regency: 'Bandung', province: 'Jawa Barat');

    expect(formatter.format(address), 'Bandung, Jawa Barat, Indonesia');
  });

  test('district yang sudah mengandung awalan Kecamatan tidak diduplikasi', () {
    const address = AddressSnapshot(district: 'Kecamatan Cibiru', regency: 'Kota Bandung');

    expect(formatter.format(address), 'Kecamatan Cibiru, Kota Bandung, Indonesia');
  });

  test('alamat kosong menghasilkan string kosong, bukan placeholder karangan', () {
    const address = AddressSnapshot();

    expect(formatter.format(address), '');
  });

  test('alamat yang sangat panjang dipotong sesuai maxLength', () {
    const address = AddressSnapshot(
      village: 'Kelurahan Dengan Nama Yang Sangat Panjang Sekali Sekali',
      district: 'Kecamatan Panjang',
      regency: 'Kabupaten Dengan Nama Panjang Juga',
      province: 'Provinsi Dengan Nama Yang Tidak Kalah Panjang',
      country: 'Indonesia',
    );

    final result = formatter.format(address, maxLength: 40);
    expect(result.length, lessThanOrEqualTo(41)); // +1 untuk karakter elipsis
  });

  test('includeStreet menyertakan jalan hanya jika diminta', () {
    const address = AddressSnapshot(street: 'Jalan Merdeka', village: 'Cipadung');

    expect(formatter.format(address, includeStreet: false), 'Cipadung, Indonesia');
    expect(formatter.format(address, includeStreet: true), 'Jalan Merdeka, Cipadung, Indonesia');
  });
}
