# WORKFLOW — GPS Map Camera (Free-First / OSM-First)

## 1. Tujuan

Dokumen ini menentukan urutan kerja AI Coding Agent saat membangun GPS Map Camera. Agent harus bekerja secara bertahap, menjaga aplikasi tetap buildable, dan tidak melompat ke fitur berikutnya sebelum tahap sebelumnya stabil.

Prioritas arsitektur:
1. local-first;
2. free-first;
3. OSM-first;
4. provider abstraction;
5. camera workflow tidak bergantung pada internet.

Google Maps Platform **bukan dependency MVP**.

## 2. Aturan Umum Agent

1. Baca `prd.md` dan `rules.md` sebelum mengubah kode.
2. Jangan membuat backend/server kecuali ada keputusan baru yang eksplisit.
3. Jangan menambahkan package hanya karena terlihat praktis.
4. Sebelum memasang package, cek apakah Flutter/Dart/platform API yang sudah digunakan cukup.
5. Setiap dependency harus punya alasan teknis.
6. Setiap layanan eksternal harus dicek terms/policy dan dokumentasi resminya jika keputusan integrasi bergantung padanya.
7. Setelah perubahan besar, jalankan formatter, analyzer, test yang relevan, dan build/check platform.
8. Jangan menghapus konfigurasi platform yang sudah benar.
9. Jangan menyimpan API key/secret di source control.
10. Jangan menganggap kegagalan provider sebagai kegagalan capture.
11. Jangan mengubah scope MVP tanpa persetujuan.
12. Jangan menggunakan Google Maps webpage scraping.
13. Jangan menjadikan public OSM/Nominatim service sebagai dependency tanpa mematuhi policy yang berlaku.
14. Provider URL harus dapat diganti melalui konfigurasi/abstraction bila policy provider mengharuskannya.

## 3. Fase 0 — Project Bootstrap

Tujuan:
- membuat/menyiapkan project Flutter;
- memastikan Android/iOS dapat dianalisis;
- memastikan toolchain valid;
- menyiapkan struktur dasar.

Output:
- Flutter project buildable;
- `prd.md`, `workflow.md`, `rules.md` tersedia;
- README awal;
- konfigurasi lint/format yang wajar.

Jangan implementasi camera/GPS/API pada fase ini.

## 4. Fase 1 — App Shell

Implementasi:
- app theme;
- localization Bahasa Indonesia;
- navigation dasar;
- home/camera shell;
- settings shell;
- permission/error UI dasar.

Acceptance:
- app launch;
- Android build;
- iOS build/check;
- tidak ada dependency map/geocoding.

## 5. Fase 2 — Camera

Implementasi:
- camera preview;
- permission camera;
- shutter;
- capture JPEG;
- orientation handling;
- basic local save.

Acceptance:
- foto dapat diambil;
- foto tersimpan;
- internet tidak diperlukan.

## 6. Fase 3 — Location

Implementasi:
- permission location;
- GPS stream/snapshot;
- location snapshot model;
- latitude;
- longitude;
- accuracy;
- altitude bila tersedia;
- GPS status UI.

Acceptance:
- capture tidak crash ketika GPS disabled;
- accuracy aktual digunakan;
- lokasi tidak dibuat-buat.

## 7. Fase 4 — Timestamp

Implementasi:
- capture timestamp;
- timezone;
- date/time formatting;
- freeze timestamp dalam CaptureSession.

Acceptance:
- satu foto memiliki satu timestamp yang konsisten.

## 8. Fase 5 — Capture Session + Watermark Core

Implementasi:
- `CaptureSession`;
- watermark data model;
- watermark renderer;
- template/configuration;
- panel dasar;
- koordinat;
- tanggal;
- waktu;
- accuracy.

Acceptance:
- foto dapat diberi watermark tanpa network;
- renderer tidak mengetahui GPS/HTTP/provider.

## 9. Fase 6 — Local Storage + Original/Processed

Implementasi:
- original photo save;
- processed photo save;
- collision-safe filename;
- history metadata minimal;
- share/delete.

Acceptance:
- original tidak tertimpa;
- processed dapat dibuka;
- portrait/landscape benar.

## 10. Fase 7 — Geocoding Provider Abstraction

Implementasi:
- `GeocodingProvider`;
- internal `AddressData` model;
- provider error model;
- cache interface;
- provider-independent formatter.

Sebelum memilih/implementasi provider:
- cek policy terbaru;
- pastikan penggunaan sesuai dengan skala aplikasi;
- pastikan User-Agent/attribution/caching sesuai;
- pastikan provider dapat diganti.

### 7.1 Initial Provider — Nominatim

Jika menggunakan public Nominatim:
- implementasi reverse geocoding saja;
- tidak boleh autocomplete;
- tidak boleh systematic/grid queries;
- maksimal 1 request/detik;
- User-Agent aplikasi harus jelas;
- gunakan caching;
- tampilkan attribution;
- jangan kirim foto atau data sensitif;
- siapkan mekanisme penggantian provider.

Acceptance:
- address tersedia ketika online;
- capture tetap sukses ketika Nominatim gagal/rate limited.

## 11. Fase 8 — Map Thumbnail Provider

Tujuan:
- menampilkan thumbnail peta OSM-derived;
- marker lokasi;
- attribution.

Implementasi awal dapat menggunakan OpenFreeMap + MapLibre atau provider OSM-derived lain yang terms-nya sesuai.

Jangan:
- scraping screenshot dari website;
- bulk download tiles;
- membuat offline map dari server tile yang melarangnya;
- hard-code provider sehingga tidak bisa diganti.

Acceptance:
- thumbnail map muncul ketika online;
- attribution terlihat;
- provider failure tidak menggagalkan capture.

## 12. Fase 9 — Map/Address Cache

Implementasi:
- coordinate normalization;
- cache key;
- TTL/version strategy;
- deduplicate request;
- cache invalidation dasar.

Tujuan:
- menghindari request untuk setiap foto;
- mengurangi beban provider;
- mempercepat capture berikutnya.

Acceptance:
- foto berulang di lokasi yang sama tidak melakukan request berulang secara tidak perlu.

## 13. Fase 10 — Offline Fallback

Pastikan seluruh alur:

```text
Capture
  ↓
Location
  ↓
Timestamp
  ↓
Watermark
  ↓
Save
```

dapat selesai tanpa internet.

Fallback:
- cached address jika tersedia;
- cached map jika tersedia;
- jika tidak ada, tampilkan coordinates + date/time.

Acceptance:
- airplane mode tetap dapat menghasilkan foto.

## 14. Fase 11 — Settings dan Template

Implementasi:
- field visibility;
- position;
- opacity;
- text size;
- map size;
- map zoom;
- custom text;
- save original;
- default template.

Acceptance:
- settings persisten;
- watermark mengikuti settings;
- tidak ada hard-coded template-only logic.

## 15. Fase 12 — EXIF

Implementasi:
- GPS latitude/longitude;
- altitude jika tersedia;
- DateTimeOriginal;
- orientation handling.

Acceptance:
- EXIF ditulis bila library/platform memungkinkan;
- kegagalan EXIF tidak menggagalkan save.

## 16. Fase 13 — Quality, Testing, Platform

Test:
- unit tests;
- provider error tests;
- cache tests;
- watermark tests;
- long address;
- missing address;
- missing map;
- portrait;
- landscape;
- large/small image.

Platform:
- Android real device;
- iOS real device jika tersedia;
- permission flows;
- storage;
- camera;
- location.

## 17. Fase 14 — Optional Satellite Provider

Satellite bukan bagian dari MVP completion.

Sebelum implementasi:
1. Tentukan provider imagery.
2. Verifikasi terms/license.
3. Verifikasi attribution.
4. Verifikasi pricing/free allowance.
5. Verifikasi Android/iOS usage.
6. Pastikan tidak memerlukan Google Billing jika target free-first dipertahankan.
7. Pastikan provider dapat dicabut tanpa merusak core camera.

Implementasi:
- `SatelliteProvider`;
- satellite thumbnail;
- cache;
- fallback ke map thumbnail.

Jangan memakai screenshot/scraping dari Google Maps atau website imagery lain.

## 18. Fase 15 — Release Readiness

Checklist:
- no secret;
- no required billing;
- no forbidden scraping;
- provider attribution;
- privacy review;
- permissions;
- Android build;
- iOS build;
- app icon/name;
- crash/error handling;
- README;
- known limitations.

## 19. Definition of Done

Fase dianggap selesai jika:
- kode terformat;
- analyzer tidak memiliki error;
- test relevan lulus;
- build/check relevan berhasil;
- acceptance criteria fase terpenuhi;
- tidak merusak fase sebelumnya;
- tidak menambah dependency yang tidak diperlukan.

## 20. Jika Agent Menemui Masalah

Urutan:
1. Identifikasi masalah.
2. Cek dokumentasi resmi package/platform/provider.
3. Cek policy/terms provider jika terkait layanan eksternal.
4. Periksa dependency/API compatibility.
5. Pilih solusi paling sederhana.
6. Jika masalah hanya provider online, pertahankan fallback offline.
7. Jangan menambahkan backend hanya untuk mengatasi masalah provider.
8. Jika keputusan produk diperlukan, berhenti dan minta keputusan pengguna.

## 21. Prioritas

Jika waktu/kompleksitas terbatas:

1. Camera.
2. GPS.
3. Timestamp.
4. Local photo output.
5. Watermark.
6. Address.
7. Map thumbnail.
8. EXIF.
9. Settings.
10. History.
11. Optional satellite.
12. Compass.

Aplikasi harus sudah berguna sebelum layanan online selesai.
