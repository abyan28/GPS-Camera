import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geotag_camera/capture/models/capture_session.dart';
import 'package:geotag_camera/location/models/location_snapshot.dart';

void main() {
  test('CaptureSession menggabungkan image, location, dan timestamp dari momen yang sama', () {
    final timestamp = DateTime(2026, 3, 5, 14, 0);
    final location = LocationSnapshot(
      latitude: -6.9,
      longitude: 107.6,
      accuracy: 8,
      capturedAt: timestamp,
    );
    final session = CaptureSession(
      originalImageFile: File('dummy_original.jpg'),
      processedImageFile: File('dummy_processed.jpg'),
      location: location,
      timestamp: timestamp,
      timeZoneName: timestamp.timeZoneName,
    );

    expect(session.location, same(location));
    expect(session.timestamp, timestamp);
    expect(session.originalImageFile.path, 'dummy_original.jpg');
    expect(session.processedImageFile.path, 'dummy_processed.jpg');
    expect(session.address, isNull);
    expect(session.map, isNull);
  });
}
