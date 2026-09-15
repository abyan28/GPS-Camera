import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// Menyimpan foto original (privat) dan mempublikasikan foto processed
/// (watermark) ke Galeri publik Android. Original tidak pernah ditimpa oleh
/// proses watermark karena disimpan di subfolder terpisah, dan keduanya
/// berbagi nama dasar yang sama supaya mudah dipasangkan di history.
class PhotoStorageService {
  static const _originalFolderName = 'original';

  /// Folder ini sekarang cuma dipakai sebagai STAGING sementara untuk foto
  /// processed (dibutuhkan `ExifWriter` yang perlu `File` asli untuk menulis
  /// tag EXIF sebelum file disalin ke galeri) — bukan penyimpanan permanen
  /// lagi, supaya tidak ada duplikat foto processed di storage privat DAN
  /// galeri publik sekaligus.
  static const _stagingFolderName = 'processed';

  /// Nama album di Galeri Android tempat foto processed dipublikasikan.
  static const galleryAlbumName = 'GeoPatriot';

  /// Path standar folder publik "Pictures" Android untuk profil pengguna
  /// utama/default — dipakai untuk memprediksi lokasi akhir foto processed
  /// setelah dipublikasikan lewat `gal` (package `gal` menyimpan gambar
  /// dengan album ke `Pictures/<album>`, bukan `DCIM/<album>`, terkonfirmasi
  /// dari source code Android plugin ini). Android-only, konsisten dengan
  /// proyek ini yang belum mendukung platform lain.
  static const _publicPicturesPath = '/storage/emulated/0/Pictures';

  Future<Directory> _folder(String name) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${documentsDir.path}/GeotagCamera/$name');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Ambil (dan buat jika belum ada) folder khusus untuk menyimpan foto
  /// original di dalam storage aplikasi.
  Future<Directory> _originalDirectory() => _folder(_originalFolderName);

  /// Ambil (dan buat jika belum ada) folder staging sementara untuk foto
  /// processed sebelum dipublikasikan ke galeri.
  Future<Directory> _stagingDirectory() => _folder(_stagingFolderName);

  /// Lokasi akhir (prediksi) foto processed di galeri publik untuk satu
  /// [baseName].
  File _publicFileFor(String baseName) {
    return File('$_publicPicturesPath/$galleryAlbumName/$baseName.jpg');
  }

  /// Tentukan nama dasar file yang collision-safe untuk satu capture,
  /// dicek terhadap folder original privat DAN lokasi publik galeri
  /// sekaligus supaya kedua file pasangan (original + processed) selalu
  /// memakai suffix yang sama.
  Future<String> reserveBaseName(DateTime capturedAt) async {
    final originalDir = await _originalDirectory();
    final base = _fileNameFor(capturedAt);

    var candidate = base;
    var suffix = 1;
    while (await File('${originalDir.path}/$candidate.jpg').exists() ||
        await _publicFileFor(candidate).exists()) {
      candidate = '${base}_$suffix';
      suffix++;
    }
    return candidate;
  }

  /// Simpan foto original dari path sementara hasil capture kamera ke
  /// storage aplikasi, dengan [baseName] yang sudah dijamin collision-safe.
  Future<File> saveOriginal(String sourcePath, {required String baseName}) async {
    final dir = await _originalDirectory();
    return File(sourcePath).copy('${dir.path}/$baseName.jpg');
  }

  /// Tulis bytes JPEG hasil watermark ke file STAGING sementara (privat),
  /// dipakai `ExifWriter` untuk menulis tag EXIF sebelum dipublikasikan ke
  /// galeri lewat [publishProcessedToGallery].
  Future<File> saveProcessed(Uint8List jpegBytes, {required String baseName}) async {
    final dir = await _stagingDirectory();
    final file = File('${dir.path}/$baseName.jpg');
    return file.writeAsBytes(jpegBytes, flush: true);
  }

  /// Salin foto processed (yang EXIF-nya sudah ditulis) dari file staging
  /// ke Galeri publik Android (album [galleryAlbumName]), lalu hapus file
  /// staging-nya — supaya cuma ada SATU salinan foto processed (di galeri),
  /// tidak dobel di storage privat.
  Future<File> publishProcessedToGallery(File stagingFile, {required String baseName}) async {
    await Gal.requestAccess(toAlbum: true);
    await Gal.putImage(stagingFile.path, album: galleryAlbumName);
    if (await stagingFile.exists()) await stagingFile.delete();
    return _publicFileFor(baseName);
  }

  /// Hapus sepasang file original (privat) + processed (galeri publik)
  /// berdasarkan nama dasarnya. Dipakai saat pengguna menghapus satu entri
  /// di history. Menghapus langsung lewat `File.delete()` ke path publik
  /// sah dilakukan tanpa izin tambahan karena aplikasi selalu punya akses
  /// penuh ke media yang dibuatnya sendiri.
  Future<void> deleteByBaseName(String baseName) async {
    final originalFile = File('${(await _originalDirectory()).path}/$baseName.jpg');
    final publicFile = _publicFileFor(baseName);
    if (await originalFile.exists()) await originalFile.delete();
    if (await publicFile.exists()) await publicFile.delete();
  }

  /// Buat nama file dasar dari timestamp capture, format `IMG_yyyyMMdd_HHmmss_SSS`.
  String _fileNameFor(DateTime timestamp) {
    String pad(int value, [int width = 2]) => value.toString().padLeft(width, '0');
    return 'IMG_${timestamp.year}${pad(timestamp.month)}${pad(timestamp.day)}_'
        '${pad(timestamp.hour)}${pad(timestamp.minute)}${pad(timestamp.second)}_'
        '${pad(timestamp.millisecond, 3)}';
  }
}
