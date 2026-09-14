import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

/// Melacak orientasi fisik device dari sensor, dipakai untuk memutar
/// konten kontrol UI (ikon, panel watermark) di tempat supaya tetap
/// terbaca normal saat HP dipegang miring — meniru pola standar aplikasi
/// kamera (posisi kontrol di layar tetap, hanya kontennya yang berputar).
///
/// Subscription ini terpisah dari yang dipakai `CameraControllerService`
/// untuk mengunci orientasi capture; keduanya ringan dan tidak saling
/// mengganggu.
class DeviceRotationController extends ChangeNotifier {
  DeviceRotationController() {
    _subscription = NativeDeviceOrientationCommunicator()
        .onOrientationChanged(useSensor: true)
        .listen((orientation) {
      final turns = _quarterTurnsFor(orientation);
      if (turns == quarterTurns) return;
      quarterTurns = turns;
      notifyListeners();
    });
  }

  StreamSubscription<NativeDeviceOrientation>? _subscription;

  /// Jumlah putaran 90° searah jarum jam yang perlu diterapkan ke konten
  /// UI supaya tetap tegak dari sudut pandang pengguna.
  int quarterTurns = 0;

  /// Petakan orientasi sensor ke jumlah putaran kompensasi. Device yang
  /// berputar searah jarum jam butuh konten diputar balik berlawanan arah
  /// (dan sebaliknya) supaya terlihat tegak bagi pengguna.
  int _quarterTurnsFor(NativeDeviceOrientation orientation) {
    switch (orientation) {
      case NativeDeviceOrientation.landscapeLeft:
        return 1;
      case NativeDeviceOrientation.landscapeRight:
        return 3;
      case NativeDeviceOrientation.portraitDown:
        return 2;
      case NativeDeviceOrientation.portraitUp:
      case NativeDeviceOrientation.unknown:
        return 0;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
