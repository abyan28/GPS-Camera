import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geotag_camera/camera/widgets/camera_bottom_bar.dart';

void main() {
  group('CameraBottomBar', () {
    testWidgets('merender tata letak horizontal stabil pada portrait (quarterTurns = 0)', (tester) async {
      var shutterPressed = false;
      var switchCameraPressed = false;
      var openGalleryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraBottomBar(
              cameraReady: true,
              busy: false,
              hasMultipleCameras: true,
              lastCapturedFile: null,
              quarterTurns: 0,
              onShutterPressed: () => shutterPressed = true,
              onSwitchCamera: () => switchCameraPressed = true,
              onOpenGallery: () => openGalleryPressed = true,
            ),
          ),
        ),
      );

      // Verifikasi komponen dirender
      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget); // Switch camera
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
      expect(find.byIcon(Icons.cameraswitch_outlined), findsOneWidget);

      // Verifikasi callback tombol
      await tester.tap(find.bySemanticsLabel('Ambil foto'));
      expect(shutterPressed, isTrue);

      await tester.tap(find.byTooltip('Ganti kamera'));
      expect(switchCameraPressed, isTrue);

      await tester.tap(find.byIcon(Icons.photo_library_outlined));
      expect(openGalleryPressed, isTrue);
    });

    testWidgets('pada landscape (quarterTurns = 1/3), kontainer baris TIDAK diputar vertikal dan ikon berputar in-place', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraBottomBar(
              cameraReady: true,
              busy: false,
              hasMultipleCameras: true,
              lastCapturedFile: null,
              quarterTurns: 1, // Landscape 90 derajat
              onShutterPressed: () {},
              onSwitchCamera: () {},
              onOpenGallery: () {},
            ),
          ),
        ),
      );

      // Kontainer utama tetap merupakan Row horizontal (bukan dibungkus RotatedBox)
      final rowWidget = tester.widget<Row>(find.byType(Row));
      expect(rowWidget.children.length, equals(3));

      // Ikon di dalam tombol galeri dan tombol switch kamera berputar dengan RotatedBox(quarterTurns: 1)
      final rotatedBoxes = tester.widgetList<RotatedBox>(find.byType(RotatedBox)).toList();
      expect(rotatedBoxes.isNotEmpty, isTrue);
      for (final rb in rotatedBoxes) {
        expect(rb.quarterTurns, equals(1));
      }
    });

    testWidgets('menonaktifkan shutter dan menampilkan indikator loading saat busy', (tester) async {
      var shutterPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraBottomBar(
              cameraReady: true,
              busy: true,
              hasMultipleCameras: true,
              lastCapturedFile: null,
              quarterTurns: 0,
              onShutterPressed: () => shutterPressed = true,
              onSwitchCamera: () {},
              onOpenGallery: () {},
            ),
          ),
        ),
      );

      // Menampilkan CircularProgressIndicator saat busy
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Sedang memproses foto'), findsOneWidget);

      // Tap tidak memicu callback saat busy
      await tester.tap(find.bySemanticsLabel('Sedang memproses foto'));
      expect(shutterPressed, isFalse);
    });

    testWidgets('menyembunyikan tombol ganti kamera jika hanya satu kamera', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraBottomBar(
              cameraReady: true,
              busy: false,
              hasMultipleCameras: false,
              lastCapturedFile: null,
              quarterTurns: 0,
              onShutterPressed: () {},
              onSwitchCamera: () {},
              onOpenGallery: () {},
            ),
          ),
        ),
      );

      expect(find.byTooltip('Ganti kamera'), findsNothing);
      expect(find.byIcon(Icons.cameraswitch_outlined), findsNothing);
    });
  });
}
