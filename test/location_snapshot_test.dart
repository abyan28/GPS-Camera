import 'package:flutter_test/flutter_test.dart';
import 'package:geotag_camera/location/models/location_snapshot.dart';

void main() {
  group('AccuracyCategory.fromMeters', () {
    test('kategori sesuai ambang batas prd', () {
      expect(AccuracyCategory.fromMeters(4.9), AccuracyCategory.excellent);
      expect(AccuracyCategory.fromMeters(5), AccuracyCategory.good);
      expect(AccuracyCategory.fromMeters(14.9), AccuracyCategory.good);
      expect(AccuracyCategory.fromMeters(15), AccuracyCategory.fair);
      expect(AccuracyCategory.fromMeters(49.9), AccuracyCategory.fair);
      expect(AccuracyCategory.fromMeters(50), AccuracyCategory.poor);
      expect(AccuracyCategory.fromMeters(null), AccuracyCategory.unknown);
    });
  });

  test('LocationSnapshot menyimpan nilai apa adanya tanpa mengarang data', () {
    final snapshot = LocationSnapshot(
      latitude: -6.200000,
      longitude: 106.816666,
      accuracy: 12.5,
      altitude: 45.0,
      capturedAt: DateTime(2026, 1, 1, 8, 30),
      isStale: true,
    );

    expect(snapshot.latitude, -6.200000);
    expect(snapshot.longitude, 106.816666);
    expect(snapshot.accuracyCategory, AccuracyCategory.good);
    expect(snapshot.isStale, isTrue);
  });
}
