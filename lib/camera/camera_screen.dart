import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../capture/capture_controller.dart';
import '../core/permissions/app_permissions.dart';
import '../geocoding/cached_geocoding_provider.dart';
import '../geocoding/nominatim_geocoding_provider.dart';
import '../history/photo_history_service.dart';
import '../location/location_service.dart';
import '../location/models/location_snapshot.dart';
import '../map/cached_map_thumbnail_provider.dart';
import '../map/osm_raster_map_thumbnail_provider.dart';
import '../settings/settings_controller.dart';
import '../storage/photo_storage_service.dart';
import 'camera_controller_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final _appPermissions = AppPermissions();
  final _cameraService = CameraControllerService();
  final _locationService = LocationService();
  late final CaptureController _captureController;

  AppPermissionsSummary? _permissions;
  bool _cameraReady = false;
  LocationSnapshot? _liveLocation;
  StreamSubscription<LocationSnapshot>? _locationSubscription;

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
      geocodingProvider: CachedGeocodingProvider(NominatimGeocodingProvider()),
      mapThumbnailProvider: CachedMapThumbnailProvider(OsmRasterMapThumbnailProvider()),
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

    _locationSubscription = _locationService.watchSnapshot().listen(
      (snapshot) {
        if (mounted) setState(() => _liveLocation = snapshot);
      },
      onError: (_) {
        // GPS mati/bermasalah: biarkan status tetap null, tampilkan fallback di UI.
      },
    );
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
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraReady) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraService.pause();
    } else if (state == AppLifecycleState.resumed) {
      _cameraService.resume();
    }
  }

  /// Bersihkan semua resource (observer, stream lokasi, kamera) saat layar
  /// ditutup.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationSubscription?.cancel();
    _cameraService.dispose();
    _captureController.dispose();
    super.dispose();
  }

  /// Jalankan capture saat tombol shutter ditekan, lalu tampilkan pesan
  /// error via snackbar jika gagal.
  Future<void> _onShutterPressed() async {
    await _captureController.capture();
    if (!mounted) return;
    if (_captureController.status == CaptureStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_captureController.errorMessage ?? 'Gagal mengambil foto.')),
      );
    }
  }

  /// Bangun tampilan utama: app bar dengan navigasi, lalu body berupa
  /// loading/permission gate/tampilan kamera tergantung status izin.
  @override
  Widget build(BuildContext context) {
    final permissions = _permissions;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geotag Camera'),
        actions: [
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
          IconButton(
            tooltip: 'Riwayat foto',
            icon: const Icon(Icons.photo_library_outlined),
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
    );
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
    final permanentlyDenied = permissions.camera == AppPermissionState.permanentlyDenied ||
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
              onPressed: permanentlyDenied ? onOpenSettings : onRequestPermissions,
              child: Text(permanentlyDenied ? 'Buka Pengaturan' : 'Berikan Izin'),
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
    required this.hasMultipleCameras,
    required this.onSwitchCamera,
    required this.onShutterPressed,
  });

  final bool cameraReady;
  final CameraController? controller;
  final LocationSnapshot? liveLocation;
  final bool hasMultipleCameras;
  final VoidCallback onSwitchCamera;
  final VoidCallback onShutterPressed;

  /// Susun preview kamera, badge status GPS, banner hasil capture terakhir,
  /// dan kontrol shutter/switch-kamera dalam satu stack.
  @override
  Widget build(BuildContext context) {
    final captureController = context.watch<CaptureController>();
    final session = captureController.lastSession;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (cameraReady && controller != null)
          Center(child: CameraPreview(controller!))
        else
          const Center(child: CircularProgressIndicator()),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: _GpsStatusBadge(location: liveLocation),
        ),
        if (session != null)
          Positioned(
            top: 72,
            left: 16,
            right: 16,
            child: _LastCaptureBanner(session: captureController),
          ),
        Positioned(
          bottom: 24,
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
                  icon: const Icon(Icons.cameraswitch_outlined),
                  onPressed: onSwitchCamera,
                ),
              const SizedBox(width: 24),
              _ShutterButton(
                busy: captureController.status == CaptureStatus.capturing,
                onPressed: cameraReady ? onShutterPressed : null,
              ),
              const SizedBox(width: 24 + 48),
            ],
          ),
        ),
      ],
    );
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
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            child: busy ? const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()) : null,
          ),
        ),
      ),
    );
  }
}

class _GpsStatusBadge extends StatelessWidget {
  const _GpsStatusBadge({required this.location});

  final LocationSnapshot? location;

  /// Tampilkan badge status GPS: koordinat + kategori akurasi, atau pesan
  /// "mencari lokasi" jika belum ada fix.
  @override
  Widget build(BuildContext context) {
    final text = location == null
        ? 'Mencari lokasi...'
        : '${location!.latitude.toStringAsFixed(6)}, '
            '${location!.longitude.toStringAsFixed(6)} '
            '(${location!.accuracyCategory.label})';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.gps_fixed, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Flexible(child: Text(text, style: const TextStyle(color: Colors.white))),
        ],
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

    final formatted = DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(capture.timestamp);
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
            child: Image.file(capture.processedImageFile, width: 40, height: 40, fit: BoxFit.cover),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text('Tersimpan: $formatted', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
