import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../capture/capture_controller.dart';
import '../core/network/safe_fetch.dart';
import '../core/permissions/app_permissions.dart';
import '../geocoding/cached_geocoding_provider.dart';
import '../geocoding/locationiq_geocoding_provider.dart';
import '../geocoding/models/address_snapshot.dart';
import '../history/photo_history_service.dart';
import '../location/location_service.dart';
import '../location/models/location_snapshot.dart';
import '../map/cached_map_thumbnail_provider.dart';
import '../map/locationiq_map_thumbnail_provider.dart';
import '../map/models/map_snapshot.dart';
import '../settings/settings_controller.dart';
import '../storage/photo_storage_service.dart';
import 'camera_controller_service.dart';
import 'device_rotation_controller.dart';
import 'edge_anchored_rotated.dart';
import 'live_watermark_overlay.dart';

/// Berapa lama banner "Tersimpan" tetap tampil setelah capture sukses,
/// sebelum otomatis hilang sendiri.
const _savedBannerDuration = Duration(seconds: 2);

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  final _appPermissions = AppPermissions();
  final _cameraService = CameraControllerService();
  final _locationService = LocationService();

  // Instance yang sama dipakai live-preview dan CaptureController, supaya
  // cache geocoding/map terbagi (tidak dobel request ke LocationIQ).
  final _geocodingProvider = CachedGeocodingProvider(
    LocationIqGeocodingProvider(),
  );
  final _mapThumbnailProvider = CachedMapThumbnailProvider(
    LocationIqMapThumbnailProvider(),
  );
  final _rotationController = DeviceRotationController();

  late final CaptureController _captureController;

  AppPermissionsSummary? _permissions;
  bool _cameraReady = false;
  LocationSnapshot? _liveLocation;
  AddressSnapshot? _liveAddress;
  MapSnapshot? _liveMap;
  String? _lastLiveGeoKey;
  StreamSubscription<LocationSnapshot>? _locationSubscription;
  bool _showSavedBanner = false;
  Timer? _savedBannerTimer;

  /// Daftarkan observer lifecycle, siapkan capture controller, lalu mulai
  /// alur pengecekan izin.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final settings = context.read<SettingsController>();
    _captureController = CaptureController(
      locationService: _locationService,
      cameraService: _cameraService,
      storageService: PhotoStorageService(),
      geocodingProvider: _geocodingProvider,
      mapThumbnailProvider: _mapThumbnailProvider,
      historyService: PhotoHistoryService(),
      watermarkConfigProvider: () => settings.settings.watermark,
      saveOriginalProvider: () => settings.settings.saveOriginal,
    );
    _bootstrap();
  }

  /// Cek status izin kamera/lokasi saat layar pertama dibuka; kalau semua
  /// sudah diberikan, langsung mulai kamera dan lokasi.
  Future<void> _bootstrap() async {
    final permissions = await _appPermissions.checkAll();
    setState(() => _permissions = permissions);
    if (permissions.allGranted) {
      await _startCameraAndLocation();
    }
  }

  /// Nyalakan kamera dan mulai stream lokasi live setelah izin lengkap.
  Future<void> _startCameraAndLocation() async {
    await _cameraService.initialize();
    if (mounted) setState(() => _cameraReady = true);
    // Cegah layar mati otomatis selagi preview kamera aktif, seperti
    // aplikasi kamera pada umumnya.
    await WakelockPlus.enable();

    _locationSubscription = _locationService.watchSnapshot().listen(
      (snapshot) {
        if (mounted) setState(() => _liveLocation = snapshot);
        _maybeUpdateLiveWatermarkData(snapshot);
      },
      onError: (_) {
        // GPS mati/bermasalah: biarkan status tetap null, tampilkan fallback di UI.
      },
    );
  }

  /// Ambil alamat/map thumbnail untuk watermark live HANYA saat lokasi
  /// berpindah ke titik yang "praktis berbeda" (presisi sama dengan
  /// `CoordinateCache`), supaya tidak memicu request LocationIQ berulang
  /// untuk pergerakan beberapa sentimeter. Memakai provider yang sama
  /// dengan `CaptureController`, jadi hasil ini juga dipakai ulang saat
  /// shutter benar-benar ditekan (tidak menambah jumlah request).
  Future<void> _maybeUpdateLiveWatermarkData(LocationSnapshot snapshot) async {
    final key =
        '${snapshot.latitude.toStringAsFixed(4)},${snapshot.longitude.toStringAsFixed(4)}';
    if (key == _lastLiveGeoKey) return;
    _lastLiveGeoKey = key;

    final config = context.read<SettingsController>().settings.watermark;

    if (config.showAddress || config.showLocationName) {
      final address = await fetchSafely(
        () => _geocodingProvider.reverseGeocode(
          latitude: snapshot.latitude,
          longitude: snapshot.longitude,
        ),
      );
      if (mounted) setState(() => _liveAddress = address);
    }

    if (config.showMapThumbnail) {
      final map = await fetchSafely(
        () => _mapThumbnailProvider.fetchThumbnail(
          latitude: snapshot.latitude,
          longitude: snapshot.longitude,
          zoom: config.mapZoom,
        ),
      );
      if (mounted) setState(() => _liveMap = map);
    }
  }

  /// Minta izin kamera/lokasi yang belum diberikan, lalu mulai kamera dan
  /// lokasi jika semuanya sudah lengkap setelah diminta.
  Future<void> _requestMissingPermissions() async {
    final current = _permissions;
    if (current == null) return;

    var camera = current.camera;
    var location = current.location;
    if (camera != AppPermissionState.granted) {
      camera = await _appPermissions.requestCamera();
    }
    if (location != AppPermissionState.granted) {
      location = await _appPermissions.requestLocation();
    }

    final updated = AppPermissionsSummary(camera: camera, location: location);
    setState(() => _permissions = updated);
    if (updated.allGranted) {
      await _startCameraAndLocation();
    }
  }

  /// Lepaskan kamera saat app masuk background, buka lagi saat app resume,
  /// supaya resource kamera tidak bocor atau bentrok dengan app lain.
  ///
  /// Sengaja HANYA bereaksi ke [AppLifecycleState.paused] (app benar-benar
  /// di-background), BUKAN [AppLifecycleState.inactive] — `inactive` juga
  /// terpicu sesaat oleh hal-hal transient seperti pengambilan screenshot
  /// sistem, notification shade, atau dialog izin, yang sebelumnya membuat
  /// kamera ikut di-dispose & diinisialisasi ulang tiap kejadian itu
  /// (terlihat sebagai layar putih + ikon loading sekilas).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraReady) return;
    if (state == AppLifecycleState.paused) {
      _cameraService.pause();
      WakelockPlus.disable();
    } else if (state == AppLifecycleState.resumed) {
      _cameraService.resume();
      WakelockPlus.enable();
    }
  }

  /// Bersihkan semua resource (observer, stream lokasi, kamera) saat layar
  /// ditutup.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationSubscription?.cancel();
    _savedBannerTimer?.cancel();
    _cameraService.dispose();
    _captureController.dispose();
    _rotationController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  /// Jalankan capture saat tombol shutter ditekan, lalu tampilkan pesan
  /// error via snackbar jika gagal, atau banner "Tersimpan" (yang otomatis
  /// hilang sendiri setelah [_savedBannerDuration]) jika berhasil.
  Future<void> _onShutterPressed() async {
    await _captureController.capture();
    if (!mounted) return;
    if (_captureController.status == CaptureStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _captureController.errorMessage ?? 'Gagal mengambil foto.',
          ),
        ),
      );
      return;
    }

    _savedBannerTimer?.cancel();
    setState(() => _showSavedBanner = true);
    _savedBannerTimer = Timer(_savedBannerDuration, () {
      if (mounted) setState(() => _showSavedBanner = false);
    });
  }

  /// Bangun tampilan utama: app bar dengan navigasi, lalu body berupa
  /// loading/permission gate/tampilan kamera tergantung status izin.
  @override
  Widget build(BuildContext context) {
    final permissions = _permissions;
    return ChangeNotifierProvider.value(
      value: _rotationController,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GeoPatriot'),
          actions: [
            IconButton(
              tooltip: 'Pengaturan',
              icon: const _RotatedControl(child: Icon(Icons.settings)),
              onPressed: () => Navigator.of(context).pushNamed('/settings'),
            ),
            IconButton(
              tooltip: 'Riwayat foto',
              icon: const _RotatedControl(
                child: Icon(Icons.photo_library_outlined),
              ),
              onPressed: () => Navigator.of(context).pushNamed('/history'),
            ),
          ],
        ),
        body: permissions == null
            ? const Center(child: CircularProgressIndicator())
            : permissions.allGranted
            ? ChangeNotifierProvider.value(
                value: _captureController,
                child: _CameraBody(
                  cameraReady: _cameraReady,
                  controller: _cameraService.controller,
                  liveLocation: _liveLocation,
                  liveAddress: _liveAddress,
                  liveMap: _liveMap,
                  showSavedBanner: _showSavedBanner,
                  hasMultipleCameras: _cameraService.hasMultipleCameras,
                  onSwitchCamera: () async {
                    await _cameraService.switchCamera();
                    setState(() {});
                  },
                  onShutterPressed: _onShutterPressed,
                ),
              )
            : _PermissionGate(
                permissions: permissions,
                onRequestPermissions: _requestMissingPermissions,
                onOpenSettings: _appPermissions.openSettings,
              ),
      ),
    );
  }
}

/// Bungkus [child] supaya berputar 90° per langkah mengikuti orientasi
/// fisik device (lihat [DeviceRotationController]), sementara posisi
/// widget di layar tidak berubah — pola standar kontrol aplikasi kamera.
///
/// Pakai [RotatedBox], bukan `Transform`/`AnimatedRotation`: `RotatedBox`
/// menukar lebar/tinggi widget SAAT LAYOUT (bukan cuma saat menggambar),
/// jadi kotak pembungkusnya ikut menyesuaikan dan tidak meluber keluar
/// area yang dialokasikan `Positioned` — beda dengan `Transform.rotate`
/// yang cuma memutar hasil gambarnya sehingga kontrol lebar (seperti
/// badge status GPS) meluber jadi bar tipis memanjang saat diputar.
class _RotatedControl extends StatelessWidget {
  const _RotatedControl({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final quarterTurns = context.watch<DeviceRotationController>().quarterTurns;
    return RotatedBox(quarterTurns: quarterTurns, child: child);
  }
}

class _PermissionGate extends StatelessWidget {
  const _PermissionGate({
    required this.permissions,
    required this.onRequestPermissions,
    required this.onOpenSettings,
  });

  final AppPermissionsSummary permissions;
  final VoidCallback onRequestPermissions;
  final VoidCallback onOpenSettings;

  /// Tampilkan pesan permintaan izin, dengan tombol yang berbeda tergantung
  /// apakah izin ditolak permanen (harus buka Settings) atau belum diminta.
  @override
  Widget build(BuildContext context) {
    final permanentlyDenied =
        permissions.camera == AppPermissionState.permanentlyDenied ||
        permissions.location == AppPermissionState.permanentlyDenied;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Aplikasi membutuhkan izin kamera dan lokasi untuk menambahkan '
              'informasi GPS pada foto Anda.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: permanentlyDenied
                  ? onOpenSettings
                  : onRequestPermissions,
              child: Text(
                permanentlyDenied ? 'Buka Pengaturan' : 'Berikan Izin',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraBody extends StatelessWidget {
  const _CameraBody({
    required this.cameraReady,
    required this.controller,
    required this.liveLocation,
    required this.liveAddress,
    required this.liveMap,
    required this.showSavedBanner,
    required this.hasMultipleCameras,
    required this.onSwitchCamera,
    required this.onShutterPressed,
  });

  final bool cameraReady;
  final CameraController? controller;
  final LocationSnapshot? liveLocation;
  final AddressSnapshot? liveAddress;
  final MapSnapshot? liveMap;
  final bool showSavedBanner;
  final bool hasMultipleCameras;
  final VoidCallback onSwitchCamera;
  final VoidCallback onShutterPressed;

  /// Susun preview kamera, watermark live, banner hasil capture terakhir,
  /// dan kontrol shutter/switch-kamera dalam satu stack.
  @override
  Widget build(BuildContext context) {
    final captureController = context.watch<CaptureController>();
    final session = captureController.lastSession;
    final quarterTurns = context.watch<DeviceRotationController>().quarterTurns;

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewScale = _previewScale(constraints, controller);

        return Stack(
          fit: StackFit.expand,
          children: [
            if (cameraReady && controller != null)
              Center(child: CameraPreview(controller!))
            else
              const Center(child: CircularProgressIndicator()),
            // Hanya tampilkan watermark live saat kamera benar-benar siap —
            // saat kamera baru diinisialisasi ulang (mis. sesaat setelah
            // sempat di-dispose), `previewScale` jatuh ke nilai fallback
            // yang jauh lebih besar dari skala normal, membuat kotak
            // sempat terlihat membesar sekilas sebelum kembali normal.
            if (cameraReady && controller != null)
              LiveWatermarkOverlay(
                location: liveLocation,
                address: liveAddress,
                mapThumbnailBytes: liveMap?.imageBytes,
                previewScale: previewScale,
                previewAreaSize: constraints.biggest,
              ),
            if (session != null && showSavedBanner)
              EdgeAnchoredRotated(
                targetEdge: ScreenEdge.top,
                quarterTurns: quarterTurns,
                margin: 16,
                child: _LastCaptureBanner(session: captureController),
              ),
            Positioned(
              // Jarak dari tepi bawah layar dinaikkan (semula 24) supaya
              // tombol shutter/switch-kamera tidak terlalu mepet dengan
              // bar navigasi sistem Android di bawahnya.
              bottom: 48,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasMultipleCameras)
                    IconButton(
                      tooltip: 'Ganti kamera',
                      iconSize: 28,
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: const _RotatedControl(
                        child: Icon(Icons.cameraswitch_outlined),
                      ),
                      onPressed: onSwitchCamera,
                    ),
                  const SizedBox(width: 24),
                  _RotatedControl(
                    child: _ShutterButton(
                      busy: captureController.status == CaptureStatus.capturing,
                      onPressed: cameraReady ? onShutterPressed : null,
                    ),
                  ),
                  const SizedBox(width: 24 + 48),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Hitung faktor skala antara "1 piksel resolusi asli kamera" dan "1
  /// logical pixel di layar", supaya ukuran panel watermark live (dirender
  /// dalam logical pixel Flutter) bisa dibuat SEBANDING SECARA PROPORSI
  /// dengan panel watermark hasil foto akhir (dirender `WatermarkRenderer`
  /// dalam piksel gambar beresolusi tinggi) — tanpa penyesuaian ini, angka
  /// ukuran yang sama (mis. fontSize 20) akan terlihat jauh lebih besar di
  /// preview kecil dibanding di foto beresolusi tinggi.
  ///
  /// `CameraPreview` membesarkan diri mengikuti `controller.value.aspectRatio`
  /// sampai sebesar mungkin di area yang tersedia (pola containment-fit
  /// `AspectRatio` standar), jadi rasio (lebar preview di layar ÷
  /// `previewSize.width`) adalah faktor skala yang konsisten, terlepas dari
  /// orientasi sensor vs layar.
  double _previewScale(
    BoxConstraints constraints,
    CameraController? controller,
  ) {
    final previewSize = controller?.value.previewSize;
    if (controller == null || previewSize == null || previewSize.width <= 0) {
      return 1.0;
    }

    final aspectRatio = controller.value.aspectRatio;
    final onScreenWidth =
        constraints.maxWidth / constraints.maxHeight > aspectRatio
        ? constraints.maxHeight * aspectRatio
        : constraints.maxWidth;

    return onScreenWidth / previewSize.width;
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback? onPressed;

  /// Tombol shutter bulat dengan label semantik untuk screen reader dan
  /// indikator loading saat sedang memproses capture.
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !busy && onPressed != null,
      label: busy ? 'Sedang mengambil foto' : 'Ambil foto',
      child: GestureDetector(
        onTap: busy ? null : onPressed,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          padding: const EdgeInsets.all(6),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _LastCaptureBanner extends StatelessWidget {
  const _LastCaptureBanner({required this.session});

  final CaptureController session;

  /// Tampilkan banner timestamp foto terakhir yang berhasil disimpan.
  @override
  Widget build(BuildContext context) {
    final capture = session.lastSession;
    if (capture == null) return const SizedBox.shrink();

    final formatted = DateFormat(
      'dd MMM yyyy, HH:mm:ss',
      'id_ID',
    ).format(capture.timestamp);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              capture.processedImageFile,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Tersimpan: $formatted',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
