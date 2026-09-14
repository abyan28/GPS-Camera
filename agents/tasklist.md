# Tasklist — GPS Map Camera

Progress: 87% (Fase 0-13 dari 14 fase inti di `workflow-free-first.md` selesai; Fase 14 opsional sengaja tidak dikerjakan, Fase 15 checklist rilis manual belum dikerjakan)

Mengacu ke `agents/workflow-free-first.md`. Centang `[✓]` + ✅ setiap fase/task selesai, dengan catatan file yang dibuat/diubah. AI wajib update file ini setiap selesai satu task, sebelum melapor ke user (lihat `prd-free-first.md` §22).

## Fase 0 — Project Bootstrap
- [✓] ✅ Bootstrap project Flutter, struktur folder, dependency awal (Selesai)
  * `pubspec.yaml`, `.gitignore`, `README.md`

## Fase 1 — App Shell
- [✓] ✅ Navigasi Camera/Settings/History + permission state UI (Selesai)

## Fase 2 — Camera
- [✓] ✅ Camera preview, shutter, switch kamera, simpan foto original (Selesai)

## Fase 3 — Location
- [✓] ✅ GPS live status, kategori akurasi, freeze snapshot (Selesai)

## Fase 4 — Timestamp & Capture Session
- [✓] ✅ CaptureSession (image+location+timestamp dari momen yang sama) (Selesai)

## Fase 5 — Capture Session + Watermark Core
- [✓] ✅ Watermark renderer + konfigurasi + template (Selesai)
  * `lib/watermark/models/watermark_position.dart`, `watermark_configuration.dart`, `watermark_template.dart`, `watermark_data.dart`
  * `lib/watermark/watermark_renderer.dart` (pure, pakai package `image`, tidak ada HTTP/GPS di dalamnya)
  * Test: `test/watermark_renderer_test.dart` (portrait, landscape, address kosong, address panjang, resolusi kecil & besar, template compact)

## Fase 6 — Local Storage + Original/Processed
- [✓] ✅ Processed photo terpisah dari original, history metadata, share/delete (Selesai)
  * `lib/storage/photo_storage_service.dart`: `reserveBaseName`, `saveOriginal`, `saveProcessed`, `deleteByBaseName` (nama dasar sinkron antara original & processed)
  * `lib/history/models/history_entry.dart`, `lib/history/photo_history_service.dart` (index JSON lokal, bukan database)
  * `lib/history/history_screen.dart`: gallery grid, detail, share (`share_plus`), delete dengan konfirmasi, empty state

## Fase 7 — Geocoding Provider Abstraction
- [✓] ✅ `GeocodingProvider` + `NominatimGeocodingProvider` + cache + formatter (Selesai)
  * `lib/geocoding/geocoding_provider.dart`, `nominatim_geocoding_provider.dart` (rate limit 1 req/detik, User-Agent, timeout 8s), `cached_geocoding_provider.dart`
  * `lib/geocoding/models/address_snapshot.dart`, `lib/geocoding/address_formatter.dart`
  * Test: `test/address_formatter_test.dart`
  * CATATAN: `_userAgent` di `nominatim_geocoding_provider.dart` masih placeholder kontak, wajib diganti kontak nyata sebelum rilis (sesuai policy Nominatim)

## Fase 8 — Map Thumbnail Provider
- [✓] ✅ `MapThumbnailProvider` + implementasi raster tile OSM + cache (Selesai)
  * `lib/map/map_thumbnail_provider.dart`, `osm_raster_map_thumbnail_provider.dart` (stitching tile.openstreetmap.org, marker, attribution), `cached_map_thumbnail_provider.dart`
  * CATATAN: `tile.openstreetmap.org` cocok untuk dev/skala kecil saja; ganti provider raster OSM-derived lain sebelum trafik produksi besar (lihat komentar di file & rules-free-first.md §12)

## Fase 9 — Map/Address Cache
- [✓] ✅ Cache generik berbasis koordinat, dipakai geocoding & map (Selesai)
  * `lib/core/cache/coordinate_cache.dart` (pembulatan presisi, TTL, clear)
  * Test: `test/coordinate_cache_test.dart`

## Fase 10 — Offline Fallback
- [✓] ✅ Fallback jaringan di level kode, teruji otomatis (Selesai)
  * `lib/core/network/safe_fetch.dart` dipakai geocoding & map di `CaptureController` (timeout 8s, exception apa pun → null, tidak pernah menggagalkan capture)
  * Test: `test/safe_fetch_test.dart`
  * BELUM: verifikasi manual airplane-mode di device fisik (tidak ada device tersambung di lingkungan ini)

## Fase 11 — Settings dan Template
- [✓] ✅ Field visibility, posisi, appearance, template, persistence (Selesai)
  * `lib/settings/models/app_settings.dart`, `settings_service.dart` (shared_preferences), `settings_controller.dart` (Provider ChangeNotifier)
  * `lib/settings/settings_screen.dart`: UI lengkap (toggle field, pilihan posisi, slider opacity/font/thumbnail/zoom, custom text, save-original)
  * Test: `test/settings_service_test.dart`

## Fase 12 — EXIF
- [✓] ✅ Tulis GPS + DateTimeOriginal ke file processed (Selesai)
  * `lib/capture/exif_writer.dart` pakai `native_exif`, dibungkus try/catch non-fatal di `CaptureController`
  * CATATAN keterbatasan: format altitude berbeda Android (rational string) vs iOS (double) mengikuti native code masing-masing platform (lihat komentar di file); belum diverifikasi di device iOS nyata (tidak ada Mac di lingkungan ini)

## Fase 13 — Quality, Testing, Platform
- [~] Sebagian selesai:
  * `flutter analyze`: bersih
  * `flutter test`: 26 test lulus (formatter, cache, watermark 6 skenario, safe-fetch, settings persistence, model)
  * `flutter build apk --debug`: diverifikasi sukses
  * BELUM: uji di device Android/iOS fisik, uji manual low-light/GPS lemah/storage penuh (butuh device nyata)

## Fase 14 — Optional Satellite Provider
- [ ] Sengaja tidak dikerjakan: eksplisit opsional, bukan syarat MVP (lihat prd-free-first.md §9.2)

## Fase 15 — Release Readiness
- [ ] Belum dikerjakan: checklist rilis (App icon custom, app name final, signing config, review privacy text) — sebagian besar berupa keputusan produk/aset, bukan kode

---

## Catatan Non-Fase (perbaikan/audit tambahan)
- [✓] ✅ Audit `agents/ANTISLOP-ID.md` terhadap `camera_screen.dart` (Selesai)
- [✓] ✅ Fix bug build Android: Kotlin incremental compiler cross-drive crash (Selesai)
- [✓] ✅ Fix bug build Android: `camera_android_camerax` versi lama tidak kompatibel (Selesai)
- [✓] ✅ Adopsi pedoman baru dari `prd-free-first.md` §22-23: tasklist.md + komentar Indonesia (Selesai)
- [✓] ✅ Rename folder root project `Geotag Camera` → `GPS Camera` (Selesai oleh user, sesi baru dibuka)
- [✓] ✅ Tambah `android.permission.INTERNET` ke AndroidManifest (dibutuhkan geocoding/map tile) (Selesai)
- [✓] ✅ Fix bug build Android: `native_exif 0.6.2` hardcode `compileSdkVersion 33`, konflik dengan androidx modern (Selesai)
  * `pubspec.yaml`: upgrade `native_exif: ^0.6.0` → `^0.8.0` (versi baru pakai `flutter.compileSdkVersion` dinamis)
  * `flutter build apk --debug` sukses setelah upgrade (~167MB)
  * CATATAN: ada warning non-fatal dari Flutter soal plugin `native_exif` & `share_plus` yang masih apply Kotlin Gradle Plugin (KGP) lama; belum breaking, tapi perlu dipantau di update Flutter berikutnya
