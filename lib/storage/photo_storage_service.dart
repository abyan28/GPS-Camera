import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Menyimpan foto ke local storage milik aplikasi. Original tidak pernah
/// ditimpa oleh proses lain (mis. watermark di fase berikutnya) karena
/// disimpan di subfolder terpisah dengan nama collision-safe.
class PhotoStorageService {
  static const _originalFolderName = 'original';

  /// Ambil (dan buat jika belum ada) folder khusus untuk menyimpan foto
  /// original di dalam storage aplikasi.
  Future<Directory> _originalDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${documentsDir.path}/GeotagCamera/$_originalFolderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Simpan foto original dari path sementara hasil capture kamera ke
  /// storage aplikasi, dengan nama file berbasis timestamp yang collision-safe.
  Future<File> saveOriginal(String sourcePath, {required DateTime capturedAt}) async {
    final dir = await _originalDirectory();
    final baseName = _fileNameFor(capturedAt);

    var candidate = File('${dir.path}/$baseName.jpg');
    var suffix = 1;
    while (await candidate.exists()) {
      candidate = File('${dir.path}/${baseName}_$suffix.jpg');
      suffix++;
    }

    return File(sourcePath).copy(candidate.path);
  }

  /// Buat nama file dasar dari timestamp capture, format `IMG_yyyyMMdd_HHmmss_SSS`.
  String _fileNameFor(DateTime timestamp) {
    String pad(int value, [int width = 2]) => value.toString().padLeft(width, '0');
    return 'IMG_${timestamp.year}${pad(timestamp.month)}${pad(timestamp.day)}_'
        '${pad(timestamp.hour)}${pad(timestamp.minute)}${pad(timestamp.second)}_'
        '${pad(timestamp.millisecond, 3)}';
  }
}
