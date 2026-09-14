import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Menyimpan foto original dan processed (watermark) ke local storage
/// aplikasi. Original tidak pernah ditimpa oleh proses watermark karena
/// disimpan di subfolder terpisah, dan keduanya berbagi nama dasar yang
/// sama supaya mudah dipasangkan di history.
class PhotoStorageService {
  static const _originalFolderName = 'original';
  static const _processedFolderName = 'processed';

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

  /// Ambil (dan buat jika belum ada) folder khusus untuk menyimpan foto
  /// processed (sudah ada watermark) di dalam storage aplikasi.
  Future<Directory> _processedDirectory() => _folder(_processedFolderName);

  /// Tentukan nama dasar file yang collision-safe untuk satu capture,
  /// dicek terhadap folder original DAN processed sekaligus supaya kedua
  /// file pasangan (original + processed) selalu memakai suffix yang sama.
  Future<String> reserveBaseName(DateTime capturedAt) async {
    final originalDir = await _originalDirectory();
    final processedDir = await _processedDirectory();
    final base = _fileNameFor(capturedAt);

    var candidate = base;
    var suffix = 1;
    while (await File('${originalDir.path}/$candidate.jpg').exists() ||
        await File('${processedDir.path}/$candidate.jpg').exists()) {
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

  /// Simpan bytes JPEG hasil watermark ke folder processed dengan
  /// [baseName] yang sama dengan foto original pasangannya.
  Future<File> saveProcessed(Uint8List jpegBytes, {required String baseName}) async {
    final dir = await _processedDirectory();
    final file = File('${dir.path}/$baseName.jpg');
    return file.writeAsBytes(jpegBytes, flush: true);
  }

  /// Hapus sepasang file original+processed berdasarkan nama dasarnya.
  /// Dipakai saat pengguna menghapus satu entri di history.
  Future<void> deleteByBaseName(String baseName) async {
    final originalFile = File('${(await _originalDirectory()).path}/$baseName.jpg');
    final processedFile = File('${(await _processedDirectory()).path}/$baseName.jpg');
    if (await originalFile.exists()) await originalFile.delete();
    if (await processedFile.exists()) await processedFile.delete();
  }

  /// Buat nama file dasar dari timestamp capture, format `IMG_yyyyMMdd_HHmmss_SSS`.
  String _fileNameFor(DateTime timestamp) {
    String pad(int value, [int width = 2]) => value.toString().padLeft(width, '0');
    return 'IMG_${timestamp.year}${pad(timestamp.month)}${pad(timestamp.day)}_'
        '${pad(timestamp.hour)}${pad(timestamp.minute)}${pad(timestamp.second)}_'
        '${pad(timestamp.millisecond, 3)}';
  }
}
