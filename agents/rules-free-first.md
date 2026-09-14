# RULES — GPS Map Camera Coding Agent (Free-First / OSM-First)

## 1. Source of Truth

- `prd.md` = product requirements.
- `workflow.md` = implementation order.
- `rules.md` = coding/architecture constraints.

Jika ketiganya berbeda:
1. Jangan menebak.
2. Ikuti keputusan paling baru yang diberikan pengguna.
3. Dokumentasikan perubahan yang diperlukan.

## 2. Core Principle

Build a local-first GPS camera, not a web application.

Dilarang secara default:
- Laravel;
- PHP;
- MySQL;
- Firebase;
- Supabase;
- custom backend;
- cloud photo upload;
- Google Maps Platform dependency.

Jangan membuat backend hanya untuk menyelesaikan masalah yang dapat diselesaikan di device.

## 3. Free-First / OSM-First

MVP harus dapat berjalan tanpa Google Cloud Billing.

Prioritas:
1. device-native capability;
2. local processing;
3. OSM-derived/open provider;
4. optional commercial provider;
5. Google hanya jika pengguna secara eksplisit memutuskan untuk menambahkannya di masa depan.

Jangan mengklaim layanan eksternal "gratis tanpa batas". Selalu periksa quota, terms, attribution, dan policy terbaru sebelum integrasi.

## 4. Architecture

Gunakan pemisahan tanggung jawab.

Contoh konsep:

```text
presentation/
camera/
location/
geocoding/
map/
satellite/
watermark/
image_processing/
storage/
settings/
```

Nama folder dapat disesuaikan dengan arsitektur Flutter yang dipilih agent, tetapi tanggung jawab harus tetap terpisah.

## 5. Provider Abstraction

Jangan mengikat domain/core langsung ke provider tertentu.

Gunakan interface/abstraction seperti:

```text
GeocodingProvider
MapThumbnailProvider
SatelliteProvider
```

Implementasi provider berada di layer infrastructure/service.

Core tidak boleh mengetahui:
- endpoint provider;
- response JSON provider;
- API key;
- HTTP implementation;
- provider-specific field names.

## 6. Capture Snapshot

Semua informasi untuk satu foto harus berasal dari satu capture session.

Konsep:

```text
CaptureSession
├── image
├── locationSnapshot
├── timestamp
├── timezone
├── addressSnapshot
├── mapSnapshot
└── optional satelliteSnapshot
```

GPS dan timestamp tidak boleh dibaca ulang secara acak ketika watermark sedang dirender.

## 7. Watermark Engine

Watermark renderer:
- menerima data;
- tidak melakukan HTTP;
- tidak meminta GPS;
- tidak memanggil geocoder;
- tidak memanggil map provider;
- tidak mengubah application state secara global.

Renderer bertanggung jawab hanya terhadap komposisi visual.

## 8. Image Processing

- Jangan mengubah original jika user memilih menyimpannya.
- Gunakan resolusi sumber secara efisien.
- Hindari pemrosesan berkali-kali.
- Hindari memory spike untuk foto resolusi tinggi.
- Tangani EXIF orientation.
- Pastikan hasil portrait/landscape benar.
- Gunakan JPEG quality yang masuk akal.
- Jangan mengurangi resolusi secara diam-diam kecuali diperlukan dan dijelaskan.

## 9. GPS

- Jangan mengklaim lokasi lebih akurat daripada `accuracy` yang diberikan device.
- Jangan mengarang koordinat.
- Jangan memblokir shutter karena accuracy buruk.
- Jangan menggunakan lokasi stale tanpa menandainya secara internal.
- Jika GPS tidak tersedia, tampilkan fallback yang jujur.

## 10. Address

- Jangan mengarang alamat.
- Jangan menggabungkan field secara duplikatif.
- Jangan menampilkan raw provider response langsung.
- Formatter harus menangani field null/missing.
- Alamat panjang harus di-wrap/truncate secara aman tanpa merusak informasi utama.

Prioritas format Indonesia:

```text
Jalan (jika ada)
Desa/Kelurahan
Kecamatan
Kabupaten/Kota
Provinsi
Negara
```

## 11. Nominatim / Public Geocoding Policy

Jika public Nominatim digunakan, penggunaan harus merupakan keputusan sadar developer dan mengikuti policy terbaru.

Wajib:
- reverse geocoding saja untuk MVP;
- maksimal 1 request/detik untuk public service;
- User-Agent yang jelas mengidentifikasi aplikasi;
- attribution yang sesuai;
- caching;
- kemampuan mengganti provider;
- tidak mengirim foto;
- tidak mengirim data pribadi/sensitif yang tidak diperlukan.

Dilarang:
- autocomplete;
- systematic/grid queries;
- bulk geocoding;
- scraping details pages;
- polling/periodic bulk requests;
- menjadikan public Nominatim sebagai geocoding service untuk trafik besar.

Jika skala aplikasi meningkat atau policy tidak lagi cocok, ganti provider atau gunakan instance/service yang dikelola sendiri.

## 12. Map Provider

Map MVP menggunakan OSM-derived provider.

Jika menggunakan OpenFreeMap:
- attribution wajib;
- jangan mengklaim SLA;
- gunakan provider sesuai terms;
- jangan scraping website;
- jangan melakukan automated/bulk download;
- provider harus dapat diganti.

Jika menggunakan `tile.openstreetmap.org` atau `vector.openstreetmap.org` secara langsung:
- ikuti policy OSMF;
- User-Agent aplikasi harus jelas;
- attribution wajib;
- cache sesuai policy;
- jangan bulk download;
- jangan membuat offline-map archive dari server OSMF;
- jangan hard-code provider tanpa mekanisme penggantian bila policy/availability mengharuskan.

Untuk MVP, lebih disukai provider OSM-derived yang memang menyediakan layanan aplikasi dan dokumentasi integrasi yang jelas.

## 13. Satellite

Satellite bersifat optional.

Wajib sebelum integrasi:
- verifikasi lisensi/terms;
- verifikasi attribution;
- verifikasi quota/pricing;
- verifikasi penggunaan pada aplikasi mobile;
- pastikan tidak melanggar hak imagery;
- jangan menggunakan screenshot/scraping dari website peta.

Jika satellite provider gagal, fallback:

```text
Satellite → Map thumbnail → No thumbnail
```

Capture tetap berhasil.

## 14. API Keys

MVP sebaiknya tidak membutuhkan API key.

Jika provider masa depan membutuhkan key:
- jangan commit API key ke Git;
- jangan menaruh secret di README;
- jangan menaruh production secret di contoh source;
- jangan mengirim key ke logging;
- gunakan konfigurasi environment/build-time/platform-appropriate;
- gunakan key berbeda untuk platform jika relevan;
- restrict key sesuai kemampuan provider.

API key yang berada di aplikasi mobile tidak boleh dianggap sebagai secret absolut.

## 15. Network

Semua HTTP eksternal harus memiliki:
- timeout;
- error handling;
- retry terbatas bila relevan;
- cancellation bila relevan;
- cache strategy.

Dilarang:
- infinite retry;
- infinite loading;
- capture menunggu network tanpa batas.

## 16. Offline

Jika network gagal:

```text
Capture → SUCCESS
Geocoding → OPTIONAL
Map → OPTIONAL
Satellite → OPTIONAL
Watermark → SUCCESS dengan fallback
Save → SUCCESS
```

Minimal fallback:

```text
Latitude
Longitude
Date
Time
```

## 17. Caching

Cache boleh digunakan untuk:
- reverse geocoding;
- map thumbnails;
- future satellite thumbnails.

Cache key harus mempertimbangkan koordinat dengan precision yang masuk akal.

Jangan membuat cache setiap perubahan beberapa centimeter sebagai lokasi berbeda.

Hormati TTL/cache policy provider.

Cache tidak boleh menjadi sumber kebenaran permanen jika data provider perlu diperbarui.

## 18. Permissions

Request permission hanya saat dibutuhkan.

Jelaskan fungsi permission dengan bahasa sederhana.

Jika ditolak:
- jangan crash;
- jangan loop dialog;
- berikan jalan untuk membuka Settings jika diperlukan.

## 19. Privacy

Default:
- foto lokal;
- lokasi lokal;
- tidak ada analytics;
- tidak ada upload foto.

Jangan menambahkan telemetry tanpa keputusan produk.

Jangan mengirim foto ke geocoding/map provider.

Jangan log lokasi lengkap secara tidak perlu.

## 20. Dependencies

Sebelum menambahkan package:
1. Tentukan masalah yang diselesaikan.
2. Cek apakah package aktif dan kompatibel.
3. Cek Android/iOS support.
4. Cek license.
5. Cek apakah package benar-benar diperlukan.
6. Hindari package yang terlalu besar untuk masalah kecil.
7. Jangan menambahkan dua package yang melakukan fungsi sama.

## 21. UI

UI harus:
- responsive;
- nyaman di layar kecil;
- mendukung portrait dan landscape;
- accessible;
- tidak terlalu ramai.

Camera screen harus memprioritaskan:
1. preview;
2. GPS status;
3. shutter;
4. camera controls.

## 22. Localization

MVP utama:
- Bahasa Indonesia.

Tanggal/waktu harus dapat diformat secara lokal.

Data teknis seperti latitude/longitude harus tetap menggunakan format konsisten.

## 23. Logging

Log boleh digunakan untuk debugging, tetapi:
- jangan log API key;
- jangan log foto;
- jangan log full sensitive location unnecessarily;
- jangan memasukkan response provider mentah ke production logs.

## 24. Error Messages

User-facing error:
- sederhana;
- actionable;
- tidak menampilkan stack trace;
- tidak menyebut detail internal kecuali membantu.

Contoh:

Baik:
> Lokasi belum tersedia. Pastikan GPS aktif lalu coba lagi.

Buruk:
> PlatformException(location_service_disabled, code=...)

## 25. Testing

Minimal test area:
- address formatter;
- coordinate formatter;
- watermark field visibility;
- watermark layout;
- map provider fallback;
- cache key;
- capture fallback;
- provider error/rate-limit handling;
- settings persistence.

Untuk watermark, test setidaknya:
- portrait;
- landscape;
- long address;
- missing address;
- missing map;
- large resolution;
- small resolution.

## 26. Git

Gunakan commit kecil dan bermakna.

Contoh:
- `feat: add camera capture`
- `feat: add location snapshot`
- `feat: add watermark renderer`
- `feat: add geocoding provider`
- `feat: add map thumbnail provider`

Jangan melakukan massive unrelated refactor dalam satu commit.

## 27. Code Quality

- gunakan null safety;
- hindari `dynamic` jika tipe dapat diketahui;
- gunakan immutable models bila sesuai;
- hindari global mutable state;
- hindari hard-coded magic numbers;
- beri nama fungsi berdasarkan intent;
- jangan membuat file raksasa;
- jangan menaruh seluruh aplikasi dalam satu `main.dart`.

## 28. No Premature Optimization

Jangan:
- membuat database lokal kompleks sebelum dibutuhkan;
- membuat backend;
- membuat state management kompleks untuk satu screen;
- membuat abstraction berlapis-lapis tanpa kebutuhan;
- menambahkan dependency untuk fitur yang belum masuk scope.

Provider abstraction untuk geocoding/map/satellite tetap diperlukan karena provider harus dapat diganti.

## 29. No Scope Creep

Agent dilarang menambahkan:
- login;
- cloud sync;
- subscription;
- ads;
- social features;
- online account;
- AI image enhancement;
- map navigation;
- satellite imagery;

tanpa persetujuan eksplisit atau fase workflow yang mengizinkannya.

## 30. Build Safety

Setelah perubahan yang menyentuh:
- Android manifest;
- iOS Info.plist;
- Gradle;
- Podfile;
- permissions;
- native plugin;
- camera;
- location;

wajib melakukan pemeriksaan build/analyzer yang relevan.

Jangan menganggap perubahan native berhasil hanya karena Dart analyzer bersih.

## 31. External Service Reality

Jangan mengklaim layanan eksternal "gratis tanpa batas".

Free usage, quota, pricing, attribution, terms, policy, dan API behavior dapat berubah.

Jika menyentuh pricing/terms/policy terbaru, verifikasi dokumentasi resmi provider sebelum mengambil keputusan.

## 32. Final Agent Behavior

Jika implementasi dapat dilakukan tanpa bertanya:
- kerjakan.

Jika ada beberapa pilihan teknis yang semuanya valid:
- pilih solusi paling sederhana yang sesuai PRD dan free-first goal.

Jika ada konflik requirement atau keputusan produk:
- jangan mengarang;
- jelaskan konflik;
- minta keputusan pengguna.

Jika provider eksternal gagal:
- implementasikan fallback;
- jangan memblokir core camera workflow.

## 33. Definition of Done

Kode tidak dianggap selesai hanya karena "sudah dibuat".

Syarat:
- analyzer bersih;
- test relevan lulus;
- build platform relevan berhasil;
- acceptance criteria terpenuhi;
- tidak ada secret;
- tidak ada broken permission configuration;
- offline fallback bekerja;
- tidak ada crash pada provider failure;
- attribution provider benar;
- tidak ada Google Billing dependency pada MVP;
- dokumentasi perubahan tersedia bila diperlukan.
