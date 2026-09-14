// ignore_for_file: prefer_initializing_formals
// Nama parameter publik sengaja berbeda dari nama field private, sehingga
// initializing formal (this._field) tidak dapat dipakai lintas file.

import 'package:flutter/foundation.dart';

import '../camera/camera_controller_service.dart';
import '../location/location_service.dart';
import '../storage/photo_storage_service.dart';
import 'models/capture_session.dart';

enum CaptureStatus { idle, capturing, success, error }

/// Orchestrate satu capture: ambil foto + bekukan lokasi + timestamp menjadi
/// satu [CaptureSession]. Tidak boleh membaca ulang GPS/waktu terpisah
/// setelah snapshot dibuat.
class CaptureController extends ChangeNotifier {
  CaptureController({
    required LocationService locationService,
    required CameraControllerService cameraService,
    required PhotoStorageService storageService,
  })  : _locationService = locationService,
        _cameraService = cameraService,
        _storageService = storageService;

  final LocationService _locationService;
  final CameraControllerService _cameraService;
  final PhotoStorageService _storageService;

  CaptureStatus status = CaptureStatus.idle;
  CaptureSession? lastSession;
  String? errorMessage;

  /// Jalankan satu siklus capture penuh: bekukan waktu, bekukan lokasi,
  /// ambil foto, simpan ke storage, lalu gabungkan semuanya jadi satu
  /// [CaptureSession]. Kegagalan location/camera/storage ditangkap dan
  /// diterjemahkan ke pesan error yang ramah pengguna.
  Future<void> capture() async {
    status = CaptureStatus.capturing;
    errorMessage = null;
    notifyListeners();

    try {
      final timestamp = DateTime.now();
      final location = await _locationService.freezeSnapshot();
      final photo = await _cameraService.takePicture();
      final savedFile = await _storageService.saveOriginal(photo.path, capturedAt: timestamp);

      lastSession = CaptureSession(
        imageFile: savedFile,
        location: location,
        timestamp: timestamp,
        timeZoneName: timestamp.timeZoneName,
      );
      status = CaptureStatus.success;
    } on LocationAccessException catch (e) {
      errorMessage = e.userMessage;
      status = CaptureStatus.error;
    } catch (_) {
      errorMessage = 'Gagal mengambil foto. Coba lagi.';
      status = CaptureStatus.error;
    }

    notifyListeners();
  }
}
