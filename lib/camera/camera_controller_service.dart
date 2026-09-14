import 'package:camera/camera.dart';

/// Membungkus package `camera`: daftar kamera, inisialisasi controller, dan
/// switch kamera. Lifecycle (pause/resume saat app di-background) ditangani
/// oleh pemanggil lewat [pause] dan [resume], karena itu adalah concern
/// widget lifecycle, bukan tanggung jawab service ini.
class CameraControllerService {
  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;

  CameraController? get controller => _controller;

  bool get isInitialized => _controller?.value.isInitialized ?? false;

  bool get hasMultipleCameras => _cameras.length > 1;

  /// Ambil daftar kamera yang tersedia lalu buka kamera pertama.
  Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw StateError('Tidak ada kamera yang tersedia pada perangkat ini.');
    }
    await _openCamera(_selectedCameraIndex);
  }

  /// Pindah ke kamera berikutnya (mis. depan ke belakang) jika perangkat
  /// punya lebih dari satu kamera.
  Future<void> switchCamera() async {
    if (!hasMultipleCameras) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _openCamera(_selectedCameraIndex);
  }

  /// Atur mode flash kamera (mis. off/auto/torch) jika kamera sudah siap.
  Future<void> setFlashMode(FlashMode mode) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    await controller.setFlashMode(mode);
  }

  /// Ambil satu foto dari kamera yang sedang aktif.
  Future<XFile> takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw StateError('Kamera belum siap.');
    }
    return controller.takePicture();
  }

  /// Lepaskan resource kamera saat app masuk background. Controller akan
  /// dibuat ulang oleh [resume].
  Future<void> pause() async {
    await _controller?.dispose();
    _controller = null;
  }

  /// Buka kembali kamera setelah app kembali aktif dari background.
  Future<void> resume() async {
    if (_controller != null || _cameras.isEmpty) return;
    await _openCamera(_selectedCameraIndex);
  }

  /// Lepaskan semua resource kamera secara permanen (dipanggil saat screen
  /// ditutup, bukan sekadar pause).
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }

  /// Buat dan inisialisasi `CameraController` baru untuk kamera pada index
  /// tertentu, lalu lepaskan controller lama setelah yang baru siap.
  Future<void> _openCamera(int index) async {
    final previous = _controller;
    final newController = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
    );
    await newController.initialize();
    _controller = newController;
    await previous?.dispose();
  }
}
