# Geotag Camera

Aplikasi kamera Flutter yang menandai setiap foto dengan lokasi GPS dan
waktu pengambilan. Dibangun **local-first** dan **free-first / OSM-first**:
tidak ada backend, login, database server, atau Google Maps Platform.
Lihat `agents/prd-free-first.md`, `agents/workflow-free-first.md`, dan
`agents/rules-free-first.md` untuk spesifikasi lengkap.

## Status implementasi saat ini

Sesi ini menyelesaikan **Fase 0–4** dari `workflow-free-first.md`:

- Bootstrap project Flutter, struktur folder, tema dasar.
- App shell dengan navigasi Camera / Settings / History.
- Camera: preview, shutter, switch kamera, simpan foto original ke storage lokal.
- Location: status GPS live + kategori akurasi, freeze snapshot saat capture.
- Timestamp & `CaptureSession`: satu snapshot foto+lokasi+waktu per capture.

**Belum diimplementasikan** (fase berikutnya): reverse geocoding (Nominatim),
map thumbnail (OpenFreeMap/MapLibre), watermark rendering ke gambar, settings
persistence, EXIF, dan history penuh. Screen Settings dan History saat ini
masih placeholder.

## Menjalankan project

```
flutter pub get
flutter run
```

Izin kamera dan lokasi akan diminta saat aplikasi pertama kali dibuka.

## Verifikasi

```
flutter analyze
flutter test
flutter build apk --debug
```
