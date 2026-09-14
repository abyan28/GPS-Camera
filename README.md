# GPS Camera

Aplikasi kamera Flutter yang menandai setiap foto dengan lokasi GPS,
alamat, thumbnail peta, dan waktu pengambilan lewat watermark yang
dirender langsung ke gambar. Dibangun **local-first** dan
**free-first / OSM-first**: tidak ada backend, login, database server,
atau Google Maps Platform. Lihat `agents/prd-free-first.md`,
`agents/workflow-free-first.md`, dan `agents/rules-free-first.md` untuk
spesifikasi lengkap.

## Status implementasi saat ini

Fase 0-13 dari `workflow-free-first.md` sudah selesai (lihat
`agents/tasklist.md` untuk rincian per fase):

- Camera: preview, shutter, switch kamera.
- Location: status GPS live + kategori akurasi, freeze snapshot saat capture.
- Watermark: panel lokasi/alamat/koordinat/tanggal/waktu/akurasi/altitude +
  thumbnail peta, 3 template (Default/Ringkas/Detail), sepenuhnya bisa
  dikonfigurasi lewat Settings.
- Reverse geocoding: Nominatim publik, dengan cache dan rate limit.
- Map thumbnail: raster tile OpenStreetMap, dengan marker dan attribution.
- EXIF: GPS + DateTimeOriginal ditulis ke file processed (best-effort).
- History: gallery, detail, share, delete foto (index lokal, tanpa database).
- Settings: seluruh pengaturan watermark tersimpan lokal dan langsung
  memengaruhi capture berikutnya.
- Offline-first: kegagalan geocoding/map/EXIF tidak pernah menggagalkan
  capture (lihat `lib/core/network/safe_fetch.dart`).

**Belum dikerjakan**: satellite imagery (Fase 14, sengaja opsional/bukan
MVP), checklist rilis (Fase 15: app icon custom, signing config produksi),
dan pengujian di device Android/iOS fisik (lingkungan pengembangan ini
tidak punya device tersambung).

**Sebelum rilis**, ganti dua placeholder berikut:
- User-Agent Nominatim di `lib/geocoding/nominatim_geocoding_provider.dart`
  dengan kontak developer nyata (wajib sesuai policy Nominatim).
- Pertimbangkan mengganti `tile.openstreetmap.org` di
  `lib/map/osm_raster_map_thumbnail_provider.dart` dengan provider raster
  OSM-derived berskala produksi jika basis pengguna besar.

## Menjalankan project

```
flutter pub get
flutter run
```

Izin kamera dan lokasi akan diminta saat aplikasi pertama kali dibuka.
Reverse geocoding dan map thumbnail membutuhkan koneksi internet; tanpa
internet, foto tetap tersimpan dengan watermark koordinat+waktu saja.

## Verifikasi

```
flutter analyze
flutter test
flutter build apk --debug
```
