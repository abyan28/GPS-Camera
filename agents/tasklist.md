# Tasklist — GPS Map Camera

Progress: 29% (Fase 0-4 dari 14 fase di `workflow-free-first.md` selesai)

Mengacu ke `agents/workflow-free-first.md`. Centang `[✓]` + ✅ setiap fase/task selesai, dengan catatan file yang dibuat/diubah. AI wajib update file ini setiap selesai satu task, sebelum melapor ke user (lihat `prd-free-first.md` §22).

## Fase 0 — Project Bootstrap
- [✓] ✅ Bootstrap project Flutter, struktur folder, dependency awal (Selesai)
  * `pubspec.yaml`, `.gitignore`, `README.md`
  * Struktur folder: `lib/core`, `lib/camera`, `lib/location`, `lib/capture`, `lib/storage`, `lib/settings`, `lib/history`
  * `lib/core/theme/app_theme.dart`

## Fase 1 — App Shell
- [✓] ✅ Navigasi Camera/Settings/History + permission state UI (Selesai)
  * `lib/app.dart`, `lib/main.dart`
  * `lib/settings/settings_screen.dart`, `lib/history/history_screen.dart` (placeholder)
  * `lib/core/permissions/app_permissions.dart`

## Fase 2 — Camera
- [✓] ✅ Camera preview, shutter, switch kamera, simpan foto original (Selesai)
  * `lib/camera/camera_controller_service.dart`, `lib/camera/camera_screen.dart`
  * `lib/storage/photo_storage_service.dart`

## Fase 3 — Location
- [✓] ✅ GPS live status, kategori akurasi, freeze snapshot (Selesai)
  * `lib/location/location_service.dart`, `lib/location/models/location_snapshot.dart`

## Fase 4 — Timestamp & Capture Session
- [✓] ✅ CaptureSession (image+location+timestamp dari momen yang sama) (Selesai)
  * `lib/capture/models/capture_session.dart`, `lib/capture/capture_controller.dart`
  * Unit test: `test/location_snapshot_test.dart`, `test/capture_session_test.dart`

## Fase 5 — Capture Session + Watermark Core
- [ ] Watermark renderer (pure, tidak ada HTTP/GPS), template dasar, panel koordinat/tanggal/waktu/accuracy

## Fase 6 — Local Storage + Original/Processed
- [ ] Processed photo save terpisah dari original, history metadata minimal, share/delete

## Fase 7 — Geocoding Provider Abstraction
- [ ] `GeocodingProvider` + `NominatimProvider` (rate limit, User-Agent, attribution, cache)

## Fase 8 — Map Thumbnail Provider
- [ ] `MapThumbnailProvider` + OpenFreeMap/MapLibre, marker, attribution

## Fase 9 — Map/Address Cache
- [ ] Coordinate normalization, cache key, TTL, dedupe request

## Fase 10 — Offline Fallback
- [ ] Verifikasi end-to-end alur capture tanpa internet (airplane mode)

## Fase 11 — Settings dan Template
- [ ] Field visibility, position, opacity, text size, template, persistence

## Fase 12 — EXIF
- [ ] Tulis GPS/timestamp ke EXIF bila platform/library memungkinkan

## Fase 13 — Quality, Testing, Platform
- [ ] Test menyeluruh (unit, provider error, cache, watermark), uji device Android/iOS

## Fase 14 — Optional Satellite Provider
- [ ] Evaluasi provider satellite (opsional, bukan syarat MVP)

## Fase 15 — Release Readiness
- [ ] Checklist rilis: secret, billing, attribution, privacy, build, app icon/name

---

## Catatan Non-Fase (perbaikan/audit tambahan)
- [✓] ✅ Audit `agents/ANTISLOP-ID.md` terhadap `camera_screen.dart` (Selesai)
  * Hapus em dash di komentar, tambah `tooltip` pada semua `IconButton`, tambah `Semantics` label pada tombol shutter, perbaiki kontras tombol switch-kamera
- [✓] ✅ Fix bug build Android: Kotlin incremental compiler cross-drive crash (Selesai)
  * `android/gradle.properties`: tambah `kotlin.incremental=false`
- [✓] ✅ Fix bug build Android: `camera_android_camerax` versi lama tidak kompatibel (Selesai)
  * `pubspec.yaml`: upgrade `camera: ^0.11.0+2` → `^0.12.1`
- [✓] ✅ Adopsi pedoman baru dari `prd-free-first.md` §22-23: buat `agents/tasklist.md`, tambah komentar Bahasa Indonesia di setiap fungsi (Selesai)
  * File baru: `agents/tasklist.md`
  * Komentar ditambahkan ke: `lib/core/permissions/app_permissions.dart`, `lib/location/location_service.dart`, `lib/location/models/location_snapshot.dart`, `lib/camera/camera_controller_service.dart`, `lib/camera/camera_screen.dart`, `lib/storage/photo_storage_service.dart`, `lib/capture/capture_controller.dart`, `lib/core/theme/app_theme.dart`, `lib/app.dart`, `lib/main.dart`, `lib/settings/settings_screen.dart`, `lib/history/history_screen.dart`
  * `flutter analyze` dan `flutter test` tetap bersih setelah perubahan
- [ ] Rename folder root project `Geotag Camera` → `GPS Camera` (DITUNDA atas keputusan user, karena berisiko membuat tool shell sesi ini error setelah rename; user akan lakukan manual lalu buka sesi baru)
