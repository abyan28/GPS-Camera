# GPS Camera

Aplikasi kamera Flutter yang menandai setiap foto dengan lokasi GPS,
alamat, thumbnail peta, dan waktu pengambilan lewat watermark yang
dirender langsung ke gambar. Dibangun **local-first**: tidak ada backend,
login, atau database server. Lihat `agents/prd-free-first.md`,
`agents/workflow-free-first.md`, dan `agents/rules-free-first.md` untuk
spesifikasi lengkap.

## Status implementasi saat ini

Fase 0-13 dari `workflow-free-first.md` sudah selesai (lihat
`agents/tasklist.md` untuk rincian per fase):

- Camera: preview, shutter, switch kamera, orientasi capture dikunci ke
  posisi device saat ini.
- Location: status GPS live + kategori akurasi, freeze snapshot saat capture.
- Watermark: panel lokasi/alamat/koordinat/tanggal/waktu/akurasi/altitude +
  thumbnail peta, 3 template (Default/Ringkas/Detail), sepenuhnya bisa
  dikonfigurasi lewat Settings.
- Reverse geocoding & map thumbnail: **LocationIQ** (butuh API key gratis,
  lihat bagian "Menjalankan project" di bawah).
- EXIF: GPS + DateTimeOriginal ditulis ke file processed (best-effort).
- History: gallery, detail, share, delete foto (index lokal, tanpa database).
- Settings: seluruh pengaturan watermark tersimpan lokal dan langsung
  memengaruhi capture berikutnya.
- Offline-first: kegagalan geocoding/map/EXIF tidak pernah menggagalkan
  capture (lihat `lib/core/network/safe_fetch.dart`).

**Belum dikerjakan**: satellite imagery (Fase 14, sengaja opsional/bukan
MVP), checklist rilis (Fase 15: app icon custom, signing config produksi).

**Bug diketahui, belum diperbaiki**: watermark/foto belum konsisten
mengikuti orientasi landscape pada sebagian device (lihat
`agents/tasklist.md` bagian "Catatan Non-Fase" untuk detail diagnostik
yang sedang dikumpulkan).

### Kenapa LocationIQ, bukan Nominatim/OSM tile publik?

Versi awal aplikasi memakai Nominatim publik dan `tile.openstreetmap.org`
langsung (sesuai visi free-first di PRD). Uji di device fisik menunjukkan
kedua layanan itu memblokir traffic aplikasi ini (Nominatim membalas HTTP
403 mengarah ke halaman policy resminya; tile server membalas gambar
"diblokir" pengganti, bukan peta asli). LocationIQ dipilih sebagai
gantinya karena satu API key gratis mencakup keduanya dan memang didesain
untuk dipakai aplikasi. Implementasi Nominatim/OSM tile lama tetap ada di
`lib/geocoding/nominatim_geocoding_provider.dart` dan
`lib/map/osm_raster_map_thumbnail_provider.dart` sebagai referensi/alternatif
provider (arsitektur provider abstraction memang dirancang supaya mudah diganti).

## Menjalankan project

```
flutter pub get
```

Daftar API key gratis di [locationiq.com](https://locationiq.com), lalu jalankan dengan:

```
flutter run --dart-define=LOCATIONIQ_API_KEY=xxxxxxxxxxxxx
```

Tanpa API key, aplikasi tetap berjalan normal, hanya reverse geocoding dan
map thumbnail yang tidak aktif (watermark fallback ke koordinat saja).

Izin kamera dan lokasi akan diminta saat aplikasi pertama kali dibuka.

## Verifikasi

```
flutter analyze
flutter test
flutter build apk --debug --dart-define=LOCATIONIQ_API_KEY=xxxxxxxxxxxxx
```
