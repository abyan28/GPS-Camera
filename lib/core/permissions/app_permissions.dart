import 'package:permission_handler/permission_handler.dart';

enum AppPermissionState { granted, denied, permanentlyDenied }

class AppPermissionsSummary {
  const AppPermissionsSummary({required this.camera, required this.location});

  final AppPermissionState camera;
  final AppPermissionState location;

  bool get allGranted =>
      camera == AppPermissionState.granted && location == AppPermissionState.granted;
}

/// Titik akses tunggal untuk cek/minta izin camera & location, supaya UI
/// tidak bergantung langsung pada tipe `permission_handler`.
class AppPermissions {
  /// Cek status izin kamera dan lokasi sekaligus, dipakai saat layar dibuka
  /// untuk menentukan apakah perlu menampilkan permission gate.
  Future<AppPermissionsSummary> checkAll() async {
    final camera = await _toState(await Permission.camera.status);
    final location = await _toState(await Permission.location.status);
    return AppPermissionsSummary(camera: camera, location: location);
  }

  /// Minta izin kamera ke pengguna dan kembalikan status hasilnya.
  Future<AppPermissionState> requestCamera() async {
    return _toState(await Permission.camera.request());
  }

  /// Minta izin lokasi ke pengguna dan kembalikan status hasilnya.
  Future<AppPermissionState> requestLocation() async {
    return _toState(await Permission.location.request());
  }

  /// Buka halaman pengaturan aplikasi di sistem, dipakai ketika izin
  /// ditolak permanen dan hanya bisa diaktifkan lewat Settings.
  Future<void> openSettings() => openAppSettings();

  /// Ubah status izin milik `permission_handler` menjadi status internal
  /// aplikasi, supaya layer lain tidak perlu tahu tipe plugin ini.
  Future<AppPermissionState> _toState(PermissionStatus status) async {
    if (status.isGranted || status.isLimited) return AppPermissionState.granted;
    if (status.isPermanentlyDenied) return AppPermissionState.permanentlyDenied;
    return AppPermissionState.denied;
  }
}
