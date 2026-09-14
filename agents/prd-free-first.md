# PRD — GPS Map Camera (Free-First / OSM-First)

## 1. Ringkasan

GPS Map Camera adalah aplikasi mobile Android dan iOS untuk mengambil foto dengan informasi lokasi dan waktu yang dirender langsung ke hasil foto. Target visual utamanya menyerupai aplikasi GPS Map Camera komersial: foto asli menjadi latar, lalu terdapat panel watermark semi-transparan berisi lokasi detail, koordinat, tanggal/waktu, dan thumbnail peta.

Karena Google Cloud Billing tidak dapat digunakan untuk proyek ini, MVP **tidak boleh bergantung pada Google Maps Platform**.

Arsitektur MVP menggunakan pendekatan **free-first / OSM-first**:
- GPS berasal dari perangkat.
- Reverse geocoding menggunakan provider OSM-compatible yang dapat diganti; kandidat awal adalah Nominatim publik setelah mempertimbangkan dan mematuhi policy-nya.
- Thumbnail peta menggunakan OSM-derived map provider yang sesuai, dengan OpenFreeMap sebagai kandidat awal.
- Tidak ada Google API yang wajib.
- Citra satelit bukan dependency MVP. Dukungan satellite imagery menjadi provider opsional pada fase lanjutan.
- Tidak ada backend, login, database server, cloud storage, analytics, iklan, atau subscription pada MVP.

Aplikasi harus tetap berfungsi untuk mengambil dan menyimpan foto ketika internet tidak tersedia.

## 2. Tujuan

1. Menghasilkan foto dokumentasi yang langsung memiliki watermark lokasi dan waktu.
2. Menampilkan koordinat GPS dan akurasi lokasi.
3. Mengubah koordinat menjadi alamat yang mudah dibaca, terutama untuk format alamat Indonesia.
4. Menampilkan thumbnail peta dengan marker lokasi.
5. Menyimpan metadata GPS/timestamp ke EXIF jika memungkinkan.
6. Tetap dapat mengambil dan menyimpan foto ketika internet tidak tersedia.
7. Menargetkan biaya operasional Rp0 untuk penggunaan pribadi/skala kecil dengan memilih layanan yang tidak membutuhkan Google Cloud Billing, sambil tetap mematuhi quota, attribution, dan terms provider.
8. Menyediakan provider abstraction sehingga geocoding dan map imagery dapat diganti tanpa mengubah core capture/watermark.
9. Menjadikan satellite imagery sebagai fitur opsional, bukan fondasi MVP.

## 3. Non-goals MVP

MVP tidak mencakup:
- akun/login/register;
- backend Laravel;
- database server;
- sinkronisasi cloud;
- social feed;
- analytics wajib;
- iklan;
- subscription;
- editor foto kompleks;
- server proxy;
- fitur berbagi lokasi secara real-time;
- Google Maps Platform;
- Google Static Maps;
- Google Geocoding;
- satellite imagery sebagai dependency wajib.

## 4. Platform dan teknologi

- Framework: Flutter
- Bahasa: Dart
- Target: Android dan iOS
- Penyimpanan: local device storage
- Image composition: pemrosesan gambar lokal
- GPS: sensor/device location
- Reverse geocoding MVP: provider OSM-compatible, kandidat awal Nominatim
- Map thumbnail MVP: OSM-derived provider, kandidat awal OpenFreeMap + MapLibre/client renderer
- Satellite imagery: optional provider pada fase lanjutan
- API keys: tidak diperlukan untuk MVP jika provider yang dipilih tidak memerlukannya
- Arsitektur: provider/service abstraction

Catatan penting:
- Public Nominatim memiliki batas penggunaan dan policy khusus. Penggunaan harus merupakan keputusan sadar developer, memakai User-Agent/identification yang benar, attribution, caching, maksimal 1 request/detik per aplikasi, dan kemampuan mengganti provider bila diperlukan.
- Public OSM tile/vector services juga memiliki policy penggunaan. Jangan memperlakukan server OSM sebagai CDN pribadi atau sumber bulk/offline download.
- OpenFreeMap menyatakan public instance-nya gratis tanpa API key dan mendukung penggunaan komersial, tetapi tetap merupakan layanan pihak ketiga tanpa SLA; attribution tetap wajib.

## 5. Alur utama

### 5.1 Capture Session

Saat pengguna menekan shutter:

1. Ambil/freeze lokasi terbaru.
2. Simpan latitude, longitude, accuracy, altitude jika tersedia.
3. Ambil timestamp device dan timezone.
4. Ambil foto.
5. Cari alamat dari cache.
6. Jika cache tidak tersedia dan internet tersedia, lakukan reverse geocoding.
7. Cari thumbnail peta dari cache.
8. Jika belum tersedia dan internet tersedia, ambil/render thumbnail peta.
9. Render watermark ke foto.
10. Tulis EXIF GPS/timestamp jika didukung.
11. Simpan original jika opsi aktif.
12. Simpan final processed photo.
13. Tampilkan preview hasil.

Kegagalan geocoding atau map thumbnail tidak boleh menggagalkan penyimpanan foto.

## 6. Data Capture

Informasi yang dapat digunakan watermark:

- latitude;
- longitude;
- GPS accuracy;
- altitude;
- timestamp lokal;
- timezone;
- tanggal;
- waktu;
- nama negara;
- provinsi;
- kabupaten/kota;
- kecamatan;
- desa/kelurahan;
- jalan/alamat;
- Plus Code jika tersedia;
- compass/heading pada fase lanjutan;
- custom text;
- app name/logo;
- map thumbnail.

## 7. Watermark

### 7.1 Default

Default watermark mengikuti konsep referensi:
- panel hitam/transparan;
- rounded corners;
- thumbnail peta di sisi kiri;
- informasi lokasi di sisi kanan;
- teks putih;
- logo/nama aplikasi;
- attribution provider peta tetap terlihat dan tidak tertutup.

MVP tidak mensyaratkan tampilan satellite. Thumbnail default adalah peta jalan/area dari provider OSM-derived.

### 7.2 Field

Watermark harus berbasis template/configuration, bukan hard-coded.

Field yang dapat diaktifkan:
- location name;
- address;
- coordinates;
- date;
- time;
- timezone;
- accuracy;
- altitude;
- compass;
- map thumbnail;
- custom text;
- application branding.

### 7.3 Position

Minimal:
- top;
- bottom;
- top-left;
- top-right;
- bottom-left;
- bottom-right.

Default: bottom.

### 7.4 Appearance

Dapat dikonfigurasi:
- opacity;
- font size;
- thumbnail size;
- margin;
- corner radius;
- spacing;
- text alignment.

## 8. Address Formatting

Raw response provider tidak boleh langsung ditempel ke watermark.

Aplikasi harus memiliki Address Formatter yang mengubah response provider menjadi struktur internal.

Untuk Indonesia, format default:
`[Jalan jika tersedia], [Desa/Kelurahan], Kec. [Kecamatan], Kab./Kota [Kabupaten/Kota], [Provinsi], Indonesia`

Formatter harus:
- menghindari duplikasi komponen;
- menghindari alamat yang terlalu panjang;
- mempertahankan komponen yang tersedia;
- menangani field yang hilang;
- tidak mengarang komponen alamat;
- dapat menangani perbedaan struktur administrasi Indonesia.

Jika reverse geocoding gagal, watermark tetap menampilkan koordinat.

## 9. Map Thumbnail

### 9.1 MVP

MVP menggunakan **OSM-derived map**, bukan Google Static Maps dan bukan satellite imagery.

Provider harus berada di balik abstraction, misalnya:

```text
MapThumbnailProvider
```

Implementasi awal dapat menggunakan OpenFreeMap/MapLibre atau provider OSM-derived lain yang sesuai dengan kebutuhan aplikasi.

Thumbnail harus:
- berpusat pada latitude/longitude capture;
- memiliki marker lokasi;
- menggunakan ukuran kecil/efisien;
- memiliki zoom configurable;
- mempertahankan attribution yang diwajibkan provider;
- tidak menggunakan scraping screenshot dari situs peta;
- tidak melakukan bulk tile download;
- menggunakan cache sesuai policy provider.

### 9.2 Satellite

Satellite imagery bukan dependency MVP.

Pada fase lanjutan, dapat ditambahkan:

```text
SatelliteProvider
```

hanya setelah ditemukan provider yang:
- mengizinkan penggunaan pada aplikasi yang ditargetkan;
- memiliki lisensi/terms yang jelas;
- sesuai kebutuhan biaya;
- menyediakan imagery atau tile/static output yang legal digunakan;
- tidak membutuhkan Google Cloud Billing jika target free-first masih dipertahankan.

Jangan menggunakan screenshot/scraping Google Maps atau layanan lain sebagai pengganti API resmi.

## 10. Reverse Geocoding

MVP menggunakan abstraction `GeocodingProvider`.

Implementasi awal:
- `NominatimProvider` hanya jika policy publik Nominatim dapat dipatuhi.

Aturan:
- gunakan cache;
- jangan request ulang untuk lokasi yang secara praktis sama;
- jangan melakukan request untuk setiap foto jika lokasi masih sama dan hasil cache masih valid;
- maksimal 1 request/detik pada public Nominatim;
- gunakan User-Agent yang jelas mengidentifikasi aplikasi;
- tampilkan attribution yang sesuai;
- provider harus dapat diganti;
- kegagalan service tidak boleh menghalangi capture;
- provider response dipetakan ke model internal;
- raw provider model tidak boleh menyebar ke UI/watermark engine.

Jika penggunaan meningkat atau policy provider tidak lagi sesuai, ganti provider atau gunakan instance/service yang dikelola sendiri; jangan memaksa public Nominatim.

## 11. Offline-first

### Tetap tersedia offline
- camera;
- GPS;
- timestamp;
- coordinates;
- accuracy;
- altitude jika tersedia;
- watermark;
- local storage;
- export/share foto lokal.

### Membutuhkan internet
- reverse geocoding yang belum ter-cache;
- map thumbnail yang belum ter-cache;
- future satellite imagery yang belum ter-cache.

Jika data online tidak tersedia:
- gunakan cache jika ada;
- jika tidak ada address, tampilkan koordinat;
- jika tidak ada map thumbnail, render watermark tanpa map;
- jangan gagal menyimpan foto.

## 12. GPS Quality

Tampilkan accuracy kepada pengguna.

Kategori:
- `< 5 m`: excellent;
- `5–15 m`: good;
- `15–50 m`: fair;
- `> 50 m`: poor.

Accuracy buruk tidak boleh memblokir shutter.

Aplikasi harus menggunakan lokasi yang tersedia dan mencatat accuracy aktual.

## 13. EXIF

Jika library/platform mendukung:
- GPS latitude;
- GPS longitude;
- GPS altitude;
- DateTimeOriginal.

EXIF bersifat tambahan dan tidak boleh menjadi satu-satunya sumber informasi. Watermark tetap merupakan informasi visual utama.

## 14. Original dan Processed Photo

Default:
- simpan original: ON;
- simpan processed: ON.

Original tidak boleh ditimpa oleh hasil watermark.

Nama file harus konsisten dan collision-safe.

## 15. Permission

Minimal:
- camera;
- location;
- photo/media/storage sesuai kebutuhan platform.

Jangan meminta permission yang tidak dibutuhkan.

Permission denial harus ditangani dengan UI yang jelas.

## 16. Settings

Minimal:
- show/hide location;
- show/hide address;
- show/hide coordinates;
- show/hide date;
- show/hide time;
- show/hide timezone;
- show/hide accuracy;
- show/hide altitude;
- show/hide map thumbnail;
- watermark position;
- opacity;
- text size;
- map zoom;
- save original;
- default template;
- custom application text.

Satellite setting tidak wajib pada MVP dan hanya muncul jika satellite provider sudah diaktifkan.

## 17. Photo History

MVP boleh memiliki gallery/history lokal:
- daftar foto hasil;
- preview;
- detail;
- share;
- delete.

Tidak perlu database server.

## 18. Error Handling

Kegagalan berikut harus graceful:
- GPS disabled;
- GPS accuracy buruk;
- location permission denied;
- internet unavailable;
- geocoding timeout;
- map provider timeout;
- provider rate limit;
- invalid provider response;
- image processing failure;
- storage failure.

Pesan error harus informatif dan tidak teknis untuk pengguna.

## 19. Privacy

- Foto tidak di-upload ke server aplikasi.
- Tidak ada cloud storage MVP.
- Lokasi hanya digunakan untuk fungsi aplikasi.
- Cache lokal harus dapat dibersihkan.
- API request hanya mengirim data yang dibutuhkan oleh provider.
- Jangan mengirim foto ke provider geocoding/map.
- Jangan mengumpulkan analytics lokasi tanpa keputusan produk eksplisit.

## 20. Acceptance Criteria MVP

MVP dianggap selesai jika:

1. Pengguna dapat membuka kamera.
2. Pengguna dapat mengambil foto.
3. Foto tersimpan walaupun internet mati.
4. Latitude/longitude dapat diperoleh ketika GPS tersedia.
5. Timestamp capture tersimpan.
6. Accuracy ditampilkan/tersimpan.
7. Address dapat diperoleh ketika online dan provider tersedia.
8. Address yang sama dapat menggunakan cache.
9. Map thumbnail dapat diperoleh/render ketika online dan provider tersedia.
10. Attribution map tetap terlihat.
11. Watermark ter-render ke JPG.
12. Foto original tidak tertimpa.
13. EXIF GPS/timestamp ditulis bila platform/library memungkinkan.
14. Geocoding gagal tidak menggagalkan capture.
15. Map thumbnail gagal tidak menggagalkan capture.
16. Aplikasi dapat dibangun untuk Android dan iOS.
17. Tidak ada backend yang dibutuhkan untuk menjalankan MVP.
18. Tidak ada Google Cloud Billing yang dibutuhkan untuk MVP.
19. Tidak ada Google Maps Platform API yang menjadi dependency wajib.

## 21. Prinsip Arsitektur

Gunakan pemisahan:
- presentation;
- camera/capture;
- location;
- geocoding;
- map;
- optional satellite;
- watermark;
- image processing;
- storage;
- settings.

Provider eksternal harus diabstraksikan.

Core capture dan watermark engine tidak boleh bergantung langsung pada provider tertentu.

Provider map/geocoding harus dapat diganti tanpa perubahan besar pada domain/capture flow.


## 22. Pedoman Pengerjaan AI (Tasklist Rules)
Setiap kali selesai mengerjakan satu tugas/fitur, AI wajib memperbarui file `agents/tasklist.md` sebelum melaporkan hasil pengerjaan kepada user dengan ketentuan:
1. Tandai task yang selesai dengan centang `[✓]`.
2. Tambahkan emoji ✅ di depan task.
3. Update progress keseluruhan proyek (misal: `Progress: 35%`).
4. Tambahkan catatan singkat di bawah task mengenai file apa saja yang dibuat/diubah.
   *Contoh:*
   ```markdown
   - [✓] ✅ Task 2.3 - Membuat Room Migration `[Mudah]` (Selesai)
     * Membuat file `database/migrations/xxxx_create_students_table.php`
   ```
5. update tasklist.md setiap selesai 1 task.
6. kasih summary jelas di akhir setiap task.
7. kalau mulai limit, berhenti di check point yg rapi
8. jadi nanti next agent tinggal baca task list dan tahu tepat mana yang dilanjut.

## 23. Pedoman Penulisan Coding
- Berikan komentar dengan bahasa Indonesia untuk setiap fungsi kodingan yg dibuat, sehingga memudahkan programmer untuk memahami kodingannya.
- Seluruh teks yang tampil di antarmuka mengikuti aturan `ANTISLOP SKILLS`. Coba cek folder skills-mu.