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
      imageFile: File('dummy.jpg'),
      location: location,
      timestamp: timestamp,
      timeZoneName: timestamp.timeZoneName,
    );

    expect(session.location, same(location));
    expect(session.timestamp, timestamp);
    expect(session.imageFile.path, 'dummy.jpg');
  });
}
