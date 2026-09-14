import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

import '../geocoding/address_formatter.dart';
import '../location/models/location_snapshot.dart';
import 'models/watermark_configuration.dart';
import 'models/watermark_data.dart';
import 'models/watermark_position.dart';

/// Watermark gagal dirender (mis. bytes foto sumber rusak/bukan gambar).
class WatermarkRenderException implements Exception {
  WatermarkRenderException(this.message);
  final String message;

  @override
  String toString() => 'WatermarkRenderException: $message';
}

/// Merender panel watermark (lokasi, alamat, koordinat, tanggal/waktu,
/// akurasi, thumbnail peta) ke atas foto sumber. Pure/semi-pure: hanya
/// menerima bytes gambar + data + konfigurasi, tidak melakukan HTTP,
/// tidak meminta GPS, tidak memanggil geocoder/map provider, tidak
/// mengubah application state global.
class WatermarkRenderer {
  static const _innerPadding = 12;
  static const _jpegQuality = 90;

  /// Render watermark ke [sourceImageBytes] sesuai [config] dan [data].
  /// Mengembalikan bytes JPEG hasil akhir. Melempar
  /// [WatermarkRenderException] jika gambar sumber tidak dapat didekode.
  Uint8List render({
    required Uint8List sourceImageBytes,
    required WatermarkData data,
    required WatermarkConfiguration config,
  }) {
    final source = img.decodeImage(sourceImageBytes);
    if (source == null) {
      throw WatermarkRenderException('Format gambar sumber tidak dikenali.');
    }

    // Normalisasi orientasi EXIF supaya piksel sesuai tampilan portrait/landscape asli.
    final oriented = img.bakeOrientation(source);

    final lines = _buildTextLines(data, config);
    final showThumbnail = config.showMapThumbnail && data.map != null;
    final font = _fontFor(config.fontSize);

    final thumbnailSize = showThumbnail ? config.thumbnailSize.round() : 0;
    final textBlockWidth = _isFullWidthPosition(config.position)
        ? oriented.width - 2 * config.margin.round() - 2 * _innerPadding - (showThumbnail ? thumbnailSize + config.spacing.round() : 0)
        : (oriented.width * 0.42).round();
    final maxCharsPerLine = (textBlockWidth / _approxCharWidth(font)).floor().clamp(8, 200);

    final wrappedLines = lines.map((line) => _truncateToWidth(line, maxCharsPerLine)).toList();

    final lineHeight = _lineHeightFor(font) + config.spacing.round();
    final textBlockHeight = wrappedLines.length * lineHeight;
    final contentHeight = showThumbnail ? (thumbnailSize > textBlockHeight ? thumbnailSize : textBlockHeight) : textBlockHeight;
    final panelHeight = contentHeight + 2 * _innerPadding;

    final panelWidth = _isFullWidthPosition(config.position)
        ? oriented.width - 2 * config.margin.round()
        : (showThumbnail ? thumbnailSize + config.spacing.round() : 0) + textBlockWidth + 2 * _innerPadding;

    final panelOrigin = _panelOrigin(
      imageWidth: oriented.width,
      imageHeight: oriented.height,
      panelWidth: panelWidth,
      panelHeight: panelHeight,
      margin: config.margin.round(),
      position: config.position,
    );

    _drawPanel(oriented, panelOrigin.dx, panelOrigin.dy, panelWidth, panelHeight, config);

    var textX = panelOrigin.dx + _innerPadding;
    final textY = panelOrigin.dy + _innerPadding;

    if (showThumbnail) {
      final resizedMap = img.copyResize(
        img.decodePng(data.map!.imageBytes)!,
        width: thumbnailSize,
        height: thumbnailSize,
      );
      final thumbY = panelOrigin.dy + (panelHeight - thumbnailSize) ~/ 2;
      img.compositeImage(oriented, resizedMap, dstX: textX, dstY: thumbY);
      textX += thumbnailSize + config.spacing.round();
    }

    var y = textY;
    for (final line in wrappedLines) {
      img.drawString(oriented, line, font: font, x: textX, y: y, color: img.ColorRgba8(255, 255, 255, 255));
      y += lineHeight;
    }

    return Uint8List.fromList(img.encodeJpg(oriented, quality: _jpegQuality));
  }

  /// Susun daftar baris teks watermark sesuai field yang diaktifkan di
  /// [config]. Baris kosong (field aktif tapi datanya tidak tersedia)
  /// dilewati, tidak pernah mengarang isi.
  List<String> _buildTextLines(WatermarkData data, WatermarkConfiguration config) {
    final lines = <String>[];
    final address = data.address;
    final formatter = AddressFormatter();

    if (config.showLocationName && address != null) {
      final name = address.village ?? address.regency;
      if (name != null && name.isNotEmpty) lines.add(name);
    }

    if (config.showAddress) {
      if (address != null && !address.isEmpty) {
        final formatted = formatter.format(address, includeStreet: true);
        if (formatted.isNotEmpty) lines.add(formatted);
      } else if (!config.showCoordinates) {
        // Offline fallback: alamat tidak tersedia dan koordinat tidak
        // ditampilkan terpisah, jadi tetap tampilkan koordinat di sini
        // supaya foto tidak kehilangan informasi lokasi sama sekali.
        lines.add(_coordinatesText(data.location));
      }
    }

    if (config.showCoordinates) {
      lines.add(_coordinatesText(data.location));
    }

    if (config.showDate) {
      lines.add(DateFormat('dd MMM yyyy', 'id_ID').format(data.timestamp));
    }

    if (config.showTime) {
      final time = DateFormat('HH:mm:ss', 'id_ID').format(data.timestamp);
      lines.add(config.showTimezone ? '$time (${data.timeZoneName})' : time);
    }

    if (config.showAccuracy && data.location.accuracy != null) {
      final accuracy = data.location.accuracy!.round();
      lines.add('Akurasi: ±$accuracy m (${data.location.accuracyCategory.label})');
    }

    if (config.showAltitude && data.location.altitude != null) {
      lines.add('Alt: ${data.location.altitude!.round()} m');
    }

    if (config.customText != null && config.customText!.trim().isNotEmpty) {
      lines.add(config.customText!.trim());
    }

    lines.add(config.appBrandingText);

    if (config.showMapThumbnail && data.map != null) {
      lines.add(data.map!.attributionText);
    }

    return lines;
  }

  String _coordinatesText(LocationSnapshot location) {
    return '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
  }

  bool _isFullWidthPosition(WatermarkPosition position) {
    return position == WatermarkPosition.top || position == WatermarkPosition.bottom;
  }

  /// Tentukan titik kiri-atas panel berdasarkan posisi yang dipilih.
  ({int dx, int dy}) _panelOrigin({
    required int imageWidth,
    required int imageHeight,
    required int panelWidth,
    required int panelHeight,
    required int margin,
    required WatermarkPosition position,
  }) {
    switch (position) {
      case WatermarkPosition.top:
        return (dx: margin, dy: margin);
      case WatermarkPosition.bottom:
        return (dx: margin, dy: imageHeight - margin - panelHeight);
      case WatermarkPosition.topLeft:
        return (dx: margin, dy: margin);
      case WatermarkPosition.topRight:
        return (dx: imageWidth - margin - panelWidth, dy: margin);
      case WatermarkPosition.bottomLeft:
        return (dx: margin, dy: imageHeight - margin - panelHeight);
      case WatermarkPosition.bottomRight:
        return (dx: imageWidth - margin - panelWidth, dy: imageHeight - margin - panelHeight);
    }
  }

  /// Gambar panel latar semi-transparan dengan sudut membulat sesuai
  /// [config].
  void _drawPanel(img.Image image, int x, int y, int width, int height, WatermarkConfiguration config) {
    final alpha = (config.opacity.clamp(0, 1) * 255).round();
    img.fillRect(
      image,
      x1: x,
      y1: y,
      x2: x + width,
      y2: y + height,
      color: img.ColorRgba8(0, 0, 0, alpha),
      radius: config.cornerRadius,
    );
  }

  /// Pilih bitmap font bawaan `image` package yang paling mendekati ukuran
  /// font yang diminta konfigurasi.
  img.BitmapFont _fontFor(double fontSize) {
    if (fontSize <= 16) return img.arial14;
    if (fontSize <= 30) return img.arial24;
    return img.arial48;
  }

  int _lineHeightFor(img.BitmapFont font) {
    if (font == img.arial48) return 52;
    if (font == img.arial24) return 28;
    return 18;
  }

  /// Perkiraan lebar rata-rata satu karakter untuk font ini, dipakai untuk
  /// membatasi panjang baris tanpa perlu mengukur setiap teks secara presisi.
  double _approxCharWidth(img.BitmapFont font) {
    if (font == img.arial48) return 26;
    if (font == img.arial24) return 13;
    return 8;
  }

  /// Potong teks yang lebih panjang dari [maxChars], menambahkan elipsis
  /// supaya tidak keluar dari panel.
  String _truncateToWidth(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars - 1)}…';
  }
}
