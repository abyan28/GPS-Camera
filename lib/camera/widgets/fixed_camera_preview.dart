import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Viewfinder preview kamera yang terkunci ke rasio aspek vertikal (portrait)
/// sesuai orientasi window aplikasi yang dikunci ke [DeviceOrientation.portraitUp].
///
/// **Latar Belakang Masalah:**
/// Widget [CameraPreview] bawaan package `camera` mengamati nilai
/// `controller.value.lockedCaptureOrientation`. Ketika [CameraController.lockCaptureOrientation]
/// dipanggil sesaat sebelum [CameraController.takePicture] pada mode landscape,
/// [CameraPreview] secara internal mengubah rasio aspek menjadi 16:9 (`controller.value.aspectRatio`)
/// dan membungkus tekstur preview dengan `RotatedBox`.
/// Karena orientasi Activity/window aplikasi kita dikunci ke portrait, perubahan tersebut
/// menyebabkan preview tiba-tiba menyusut menjadi kotak kecil di tengah layar (letterboxing)
/// dengan bidang hitam besar di atas/bawah dan memutar gambar kamera secara mendadak selama proses capture.
///
/// **Solusi:**
/// Widget ini mempertahankan rasio aspek preview tetap `1 / value.aspectRatio` (rasio vertikal)
/// secara stabil dan langsung menampilkan `controller.buildPreview()` tanpa rotasi buatan,
/// sehingga tampilan viewfinder tetap kokoh, mulus, dan tidak berkedip/berputar saat tombol shutter ditekan.
class FixedCameraPreview extends StatelessWidget {
  const FixedCameraPreview(this.controller, {super.key, this.child});

  final CameraController controller;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CameraValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (!value.isInitialized) {
          return const SizedBox.shrink();
        }

        Widget previewWidget;
        try {
          previewWidget = controller.buildPreview();
        } catch (_) {
          return const SizedBox.shrink();
        }

        return AspectRatio(
          aspectRatio: 1 / value.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              previewWidget,
              ?child,
            ],
          ),
        );
      },
    );
  }
}
