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
- [✓] ✅ Diagnostik alamat tidak muncul & map thumbnail rusak → TERKONFIRMASI, provider diganti (Selesai)
  * Bukti log device nyata: Nominatim membalas `403 "Access denied. See https://operations.osmfoundation.org/policies/nominatim/"` (block eksplisit, bukan rate-limit); 9 tile `tile.openstreetmap.org` di koordinat berbeda-beda semua membalas `status=200 bytes=6987` (identik persis → gambar "soft-block" pengganti, bukan peta asli)
  * Keputusan user (AskUserQuestion): pindah ke **LocationIQ** untuk geocoding + map thumbnail (satu API key, free tier, memang didesain untuk aplikasi)
  * File baru: `lib/core/config/api_keys.dart` (`String.fromEnvironment('LOCATIONIQ_API_KEY')`, tidak di-hardcode), `lib/geocoding/locationiq_geocoding_provider.dart`, `lib/map/locationiq_map_thumbnail_provider.dart`
  * `lib/camera/camera_screen.dart`: wiring provider diganti ke LocationIQ (dibungkus `CachedGeocodingProvider`/`CachedMapThumbnailProvider` yang sudah ada, tidak berubah)
  * Provider Nominatim/OSM tile lama TIDAK dihapus (`nominatim_geocoding_provider.dart`, `osm_raster_map_thumbnail_provider.dart`), tetap sebagai referensi implementasi provider alternatif
  * `README.md` diupdate: cara daftar & pakai API key LocationIQ (`--dart-define=LOCATIONIQ_API_KEY=...`)
  * VERIFIKASI DEVICE: berhasil — alamat & map thumbnail asli sudah muncul di foto uji nyata
- [✓] ✅ Fix akar masalah orientasi — TERKONFIRMASI BERHASIL di device nyata (Selesai)
  * PERCOBAAN #1 (lock ke `controller.value.deviceOrientation`) GAGAL — `deviceOrientation` stuck di `portraitUp` walau HP landscape (bug plugin `camera`/`camera_android_camerax`)
  * PERCOBAAN #2 (BERHASIL): baca orientasi dari `native_device_orientation` (sensor fisik langsung), independen dari tracking internal `camera` plugin yang bermasalah
  * VERIFIKASI DEVICE: log menunjukkan `NativeDeviceOrientation.landscapeLeft` terdeteksi benar dan `EXIF Orientation mentah: 1` (normal, tidak perlu rotasi) — watermark & foto sudah mengikuti orientasi landscape dengan benar
- [✓] ✅ Fix "glitch" preview saat capture (Selesai)
  * Penyebab: `lockCaptureOrientation()`/`unlockCaptureOrientation()` dipanggil di SETIAP `takePicture()`, memicu CameraX mengonfigurasi ulang sesi preview tiap shutter ditekan
  * Fix: `lib/camera/camera_controller_service.dart` sekarang mengunci orientasi lewat stream (`onOrientationChanged`) sekali saat kamera dibuka, hanya mengunci ulang saat orientasi BENAR-BENAR berubah; `takePicture()` tidak lock/unlock sama sekali lagi
  * Log diagnostik orientasi (per-capture) dihapus karena bug sudah tuntas; diganti log ringan hanya saat orientasi berubah
- [✓] ✅ Fix alamat berbahasa Inggris (Selesai)
  * `lib/geocoding/locationiq_geocoding_provider.dart`: tambah parameter `accept-language: id`
- [✓] ✅ Fix teks alamat & attribution terpotong di tengah kata (Selesai)
  * `lib/watermark/watermark_renderer.dart`: baris alamat/custom text sekarang boleh wrap sampai 2 baris dengan pemutusan di batas kata (`_WatermarkLine`, `_wrapLine`, `_lastWordBreak`), bukan dipotong paksa 1 baris
- [✓] ✅ Fix spasi aneh sebelum "LocationIQ" di attribution (Selesai)
  * Penyebab: karakter "©" tidak punya glyph di bitmap font `image` package, dirender kosong tapi tetap makan lebar
  * `lib/map/locationiq_map_thumbnail_provider.dart`: hapus "©" dari `_attribution` (kredit LocationIQ + OpenStreetMap tetap dipertahankan, wajib sesuai ToS LocationIQ)
- [✓] ✅ Redesign watermark: box menyesuaikan konten, hierarki font, ukuran diperbesar, accuracy default OFF (Selesai)
  * `lib/watermark/watermark_renderer.dart`: `panelWidth` sekarang dihitung dari lebar konten aktual (wrap + thumbnail + padding), bukan dipaksa selebar foto; baris nama lokasi pakai font satu tingkat lebih besar dari body (`_titleFontFor`)
  * `lib/watermark/models/watermark_configuration.dart`: `defaultTemplate()` — `fontSize` 14→20, `thumbnailSize` 96→140, `showAccuracy` true→false; `detail()` — `fontSize` 15→22, `thumbnailSize` 112→160; `compact()` — `fontSize` 12→14
  * BELUM diverifikasi ulang di device fisik oleh user (menunggu uji berikutnya)
- [✓] ✅ Fix UI landscape "aneh" & preview tidak full-screen (Selesai)
  * Root cause: aplikasi tidak mengunci orientasi UI, sehingga layout jadi tidak konsisten saat device landscape (bukan transient glitch seperti dugaan sebelumnya) — pola standar aplikasi kamera adalah UI dikunci portrait, sensor orientasi hanya dipakai untuk EXIF foto (sudah benar sejak fix sebelumnya)
  * `lib/main.dart`: `SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])`
  * `android/app/src/main/AndroidManifest.xml`: `android:screenOrientation="portrait"` pada MainActivity
  * `lib/camera/camera_screen.dart`: preview kamera diganti dari `Center(child: CameraPreview(...))` (letterbox, tidak mengisi layar) ke `_FullBleedCameraPreview` (pola `Transform.scale` + `AspectRatio` + `ClipRect` standar, mengisi layar penuh seperti aplikasi kamera lain)
  * BELUM diverifikasi ulang di device fisik oleh user
- [✓] ✅ Watermark live preview (floating overlay sebelum capture) (Selesai)
  * File baru `lib/camera/live_watermark_overlay.dart`: render panel watermark pakai widget Flutter biasa (bukan `WatermarkRenderer`/`image` package yang berat untuk live), posisi mengikuti `WatermarkConfiguration.position` aktif
  * `lib/camera/camera_screen.dart`: alamat & map thumbnail untuk live preview diambil proaktif saat lokasi berpindah ke titik "praktis berbeda" (presisi sama `CoordinateCache`), pakai instance `CachedGeocodingProvider`/`CachedMapThumbnailProvider` yang SAMA dengan `CaptureController` (cache terbagi, tidak menambah request LocationIQ dibanding sebelumnya — hanya pindah waktu fetch jadi lebih awal)
  * BUKAN pixel-perfect sama dengan hasil akhir (font Flutter vs bitmap font watermark renderer akan sedikit berbeda) — representasi visual, bukan preview identik
  * BELUM diverifikasi ulang di device fisik oleh user
- [✓] ✅ Rotasi ikon/panel UI mengikuti orientasi fisik saat landscape (Selesai)
  * Root cause sebenarnya (dikonfirmasi dari perbandingan screenshot user vs aplikasi referensi): kunci UI ke portrait itu SUDAH BENAR dan dipakai juga oleh aplikasi referensi (posisi kontrol tidak berpindah) — yang belum dibangun adalah rotasi KONTEN kontrol (ikon/teks/panel) 90° di tempat supaya tetap terbaca saat HP dipegang miring
  * File baru `lib/camera/device_rotation_controller.dart`: `ChangeNotifier` yang melacak sensor orientasi (`native_device_orientation`, sumber sama dengan yang dipakai EXIF, subscription terpisah) dan expose `quarterTurns` (0/1/2/3)
  * `lib/camera/camera_screen.dart`: widget `_RotatedControl` (`AnimatedRotation`) membungkus ikon AppBar (Settings/Riwayat), tombol switch kamera, tombol shutter, GPS badge, dan banner "Tersimpan" — posisi di layar tetap, hanya konten yang berputar
  * `lib/camera/live_watermark_overlay.dart`: seluruh panel watermark live ikut diputar sebagai satu blok (meniru referensi)
- [✓] ✅ Auto-hide banner "Tersimpan", fix posisi+ukuran card saat landscape, layar tetap menyala saat kamera aktif (Selesai)
  * Diputuskan (dikonfirmasi user via AskUserQuestion): TETAP kunci UI ke portrait, tidak ikut berputar sungguhan seperti kamera bawaan HP — sesuai perilaku aplikasi referensi GPS Map Camera yang juga terkunci portrait
  * Root cause bug "kotak membesar aneh saat landscape": `Positioned(top:16,left:16,right:16,...)` membuat lebar jadi TEGAS (tight), lalu `RotatedBox` menukar balik batasan lebar/tinggi itu untuk anaknya saat quarterTurns ganjil — anak jadi dipaksa setinggi lebar layar penuh
  * Root cause bug "posisi tidak ikut pindah sisi saat landscape": piksel layar tidak ikut berputar (dikunci portrait), cuma konten yang berputar lewat `RotatedBox`, jadi sisi fisik HP yang tetap (atas/kanan/bawah/kiri) berpindah makna dari sudut pandang pengguna saat dimiringkan — card yang nempel di tepi-atas-fisik jadi terlihat nempel di kiri/kanan tergantung arah kemiringan
  * File baru `lib/camera/edge_anchored_rotated.dart`: widget `EdgeAnchoredRotated` — terima target sisi dari SUDUT PANDANG PENGGUNA (atas/kanan/bawah/kiri), hitung sisi fisik yang benar dipakai via rumus `(targetEdge + quarterTurns) % 4`, dibungkus `Center` supaya batasan yang diteruskan ke `RotatedBox` selalu longgar (sekaligus jadi fix generik untuk bug ukuran membesar di atas)
  * `lib/camera/camera_screen.dart`: `_LastCaptureBanner` pakai `EdgeAnchoredRotated(targetEdge: top)` — selalu tampak di atas dari sudut pandang pengguna, portrait maupun landscape kedua arah
  * `lib/camera/live_watermark_overlay.dart`: posisi `top`/`bottom` (default) pakai `EdgeAnchoredRotated`; posisi 4 sudut (topLeft/dst, bukan default) TIDAK diubah — tetap menempel sudut fisik yang sama seperti sebelumnya (di luar cakupan laporan bug ini)
  * Banner "Tersimpan": tambah auto-hide — `_CameraScreenState` sekarang punya `_showSavedBanner`+`_savedBannerTimer`, otomatis disembunyikan 2 detik setelah capture sukses (data `lastSession` di `CaptureController` sendiri TIDAK dihapus, cuma visibilitas banner di UI)
  * Layar tetap menyala saat kamera aktif: tambah dependency `wakelock_plus` (memakai `FLAG_KEEP_SCREEN_ON` Android, tidak butuh izin manifest tambahan) — `WakelockPlus.enable()` dipanggil setelah kamera siap & saat app resume, `WakelockPlus.disable()` saat app pause/dispose
  * VERIFIKASI: `flutter analyze` bersih, `flutter test` 26/26 lolos; BELUM diverifikasi ulang di device fisik oleh user
- [✓] ✅ Fix preview kamera tampil miring/rusak terus-menerus saat landscape (Selesai)
  * Root cause sebenarnya: fix "glitch saat capture" sebelumnya (lock orientasi terus-menerus lewat stream, re-lock tiap sensor berubah) TERBUKTI membuat CameraX ikut memutar TEKSTUR PREVIEW kamera secara berkelanjutan selama kamera menyala, bukan cuma memengaruhi EXIF foto hasil — inilah penyebab layar kamera terlihat "aneh"/rusak terus-menerus di landscape, bukan sekadar transient
  * Dikonfirmasi lewat urutan gejala yang diingat user: masalah ini mulai muncul persis sejak sesi lalu mengganti mekanisme lock jadi terus-menerus
  * `lib/camera/camera_controller_service.dart`: hapus mekanisme lock terus-menerus (`_watchOrientation`, `_orientationSubscription`), kembali ke lock SEKALI-PAKAI tepat sebelum `takePicture()` dan unlock segera sesudahnya (pola seperti percobaan pertama), tapi sumber orientasinya tetap dibaca one-shot dari `native_device_orientation` (bukan `controller.value.deviceOrientation` yang terbukti macet di `portraitUp`)
  * Konsekuensi yang bisa diterima: preview normal selama user mengarahkan kamera; kemungkinan ada kedipan super singkat tepat saat shutter ditekan, foto hasil tetap berorientasi benar
  * BELUM diverifikasi ulang di device fisik oleh user
- [✓] ✅ Fix arah rotasi ikon/panel UI terbalik (Selesai)
  * User konfirmasi rotasi berjalan tapi arahnya salah
  * `lib/camera/device_rotation_controller.dart`: tukar nilai `quarterTurns` untuk `NativeDeviceOrientation.landscapeLeft` (3→1) dan `landscapeRight` (1→3)
  * VERIFIKASI: `flutter analyze` bersih, `flutter test` 26/26 lolos; BELUM diverifikasi ulang di device fisik oleh user
- [✓] ✅ Fix preview kamera terlihat "ter-zoom"/terlalu besar (Selesai)
  * Root cause: rumus skala di `_FullBleedCameraPreview` (`controller.value.aspectRatio / deviceRatio`) BENAR untuk layar yang bisa berputar bebas, tapi SALAH sejak UI dikunci portrait terus-menerus — `controller.value.aspectRatio` dari sensor kamera selalu >1 ("landscape"), sedangkan rasio layar yang dikunci portrait selalu <1, sehingga pembagian langsung menghasilkan skala sangat besar (preview jadi tampak ter-zoom, padahal tidak ada fitur zoom yang aktif)
  * `lib/camera/camera_screen.dart`: `_FullBleedCameraPreview` sekarang pakai rumus resmi contoh package `camera` untuk preview full-bleed di layar terkunci portrait — `scale = size.aspectRatio * controller.value.aspectRatio`, dibalik `1/scale` jika hasilnya <1
  * VERIFIKASI: `flutter analyze` bersih; BELUM diverifikasi ulang di device fisik oleh user
- [✓] ✅ Kembalikan preview kamera ke versi semula (sebelum revisi full-bleed) atas permintaan user (Selesai)
  * User menilai preview full-bleed (`_FullBleedCameraPreview`, `Transform.scale`) hasilnya lebih jelek daripada versi awal, walau rumus skalanya sudah diperbaiki — diminta kembali ke kondisi sebelum rangkaian revisi kunci orientasi
  * `lib/camera/camera_screen.dart`: `_CameraBody` kembali pakai `Center(child: CameraPreview(controller!))` polos (letterbox, sesuai aspect ratio asli kamera, tidak dipotong/di-scale); widget `_FullBleedCameraPreview` dihapus (tidak dipakai lagi)
  * VERIFIKASI: `flutter analyze` bersih; BELUM diverifikasi ulang di device fisik oleh user
- [✓] ✅ Hapus badge koordinat live, pindahkan watermark (live & hasil akhir) ke bottom-center (Selesai)
  * Permintaan user: hapus kotak koordinat GPS live (dianggap tidak perlu, sudah terwakili watermark), dan watermark harus selalu bottom-center di kedua mode (portrait & landscape)
  * `lib/camera/camera_screen.dart`: hapus widget `_GpsStatusBadge` beserta pemanggilannya; banner "Tersimpan" naik ke `top: 16` (sebelumnya `top: 72`, dulu di bawah badge yang kini dihapus)
  * `lib/watermark/watermark_renderer.dart`: `_panelOrigin` untuk `WatermarkPosition.top`/`bottom` sekarang menghitung `dx` rata tengah horizontal (`(imageWidth - panelWidth) ~/ 2`), bukan rata kiri seperti sebelumnya (default template sudah pakai `WatermarkPosition.bottom`, jadi ini otomatis membuat hasil akhir watermark bottom-center)
  * `lib/camera/live_watermark_overlay.dart`: untuk posisi `top`/`bottom`, panel live dibungkus `Center` dengan `left: 0, right: 0` (bukan `margin` rata kiri/kanan) — posisi Positioned ini tidak berubah saat device diputar (hanya konten di dalamnya yang berputar lewat `RotatedBox`), jadi otomatis tetap bottom-center di portrait maupun landscape
  * VERIFIKASI: `flutter analyze` bersih, `flutter test` 26/26 lolos; BELUM diverifikasi ulang di device fisik oleh user
- [✓] ✅ Fix badge/panel UI meluber & rusak saat diputar landscape (Selesai)
  * Root cause (dikonfirmasi dari screenshot device nyata): `AnimatedRotation`/`Transform.rotate` hanya memutar hasil GAMBAR widget, bukan ukuran kotak layout-nya — untuk widget lebar seperti badge status GPS (`left:16, right:16`, hampir selebar layar), saat diputar 90° hasilnya meluber jauh ke luar area yang dialokasikan `Positioned`, tampil sebagai bar tipis memanjang yang rusak
  * Preview kamera yang terlihat "miring mengikuti device" saat landscape TERNYATA SUDAH BENAR — dibandingkan langsung dengan screenshot aplikasi referensi (`contoh tampilan apps gps map camera saat mode landscape.jpg`), perilaku itu memang standar untuk UI yang dikunci portrait; bukan bug
  * `lib/camera/camera_screen.dart`: `_RotatedControl` ganti `AnimatedRotation` → `RotatedBox` (menukar lebar/tinggi widget SAAT LAYOUT, bukan cuma saat digambar, sehingga kotak pembungkus ikut menyesuaikan dan tidak meluber)
  * `lib/camera/live_watermark_overlay.dart`: panel watermark live juga ganti ke `RotatedBox`
  * Konsekuensi: transisi rotasi jadi langsung/tanpa animasi halus (sebelumnya 200ms), demi mencegah bug meluber — trade-off yang sama dipakai referensi (ikon di aplikasi referensi juga snap langsung, tidak animasi)
  * VERIFIKASI: `flutter analyze` bersih; BELUM diverifikasi ulang di device fisik oleh user
  * BELUM diverifikasi ulang di device fisik oleh user
