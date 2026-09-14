import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../geocoding/address_formatter.dart';
import '../geocoding/models/address_snapshot.dart';
import '../location/models/location_snapshot.dart';
import '../settings/settings_controller.dart';
import '../watermark/models/watermark_configuration.dart';
import '../watermark/models/watermark_position.dart';
import 'device_rotation_controller.dart';
import 'edge_anchored_rotated.dart';

/// Overlay watermark LIVE di atas viewfinder, sebelum shutter ditekan.
/// Dirender dengan widget Flutter biasa (bukan `WatermarkRenderer` yang
/// berbasis `image` package), jadi tidak identik piksel-demi-piksel dengan
/// hasil akhir, tapi cukup merepresentasikan tata letak/isi supaya
/// pengguna tahu kira-kira hasilnya sebelum memotret.
class LiveWatermarkOverlay extends StatelessWidget {
  const LiveWatermarkOverlay({
    super.key,
    required this.location,
    required this.address,
    required this.mapThumbnailBytes,
  });

  final LocationSnapshot? location;
  final AddressSnapshot? address;
  final Uint8List? mapThumbnailBytes;

  /// Bangun panel watermark live sesuai konfigurasi watermark aktif saat
  /// ini, diposisikan sesuai `config.position`.
  @override
  Widget build(BuildContext context) {
    final location = this.location;
    if (location == null) return const SizedBox.shrink();

    final config = context.watch<SettingsController>().settings.watermark;
    final lines = _buildLines(config, location, address);
    final showThumbnail = config.showMapThumbnail && mapThumbnailBytes != null;

    final panel = Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: config.opacity.clamp(0, 1)),
        borderRadius: BorderRadius.circular(config.cornerRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showThumbnail) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.memory(
                mapThumbnailBytes!,
                width: config.thumbnailSize,
                height: config.thumbnailSize,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: config.spacing),
          ],
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines,
            ),
          ),
        ],
      ),
    );

    final quarterTurns = context.watch<DeviceRotationController>().quarterTurns;

    // Posisi tengah (top/bottom, kasus default): pakai EdgeAnchoredRotated
    // supaya sisi yang ditempeli ikut menyesuaikan saat device dimiringkan
    // (misal watermark tetap tampak di BAWAH dari sudut pandang pengguna,
    // bukan cuma menempel di tepi fisik bawah HP yang berpindah makna saat
    // landscape), sekaligus mencegah bug ukuran panel membesar tegas
    // selebar/setinggi layar saat kontennya ditukar orientasi.
    if (config.position == WatermarkPosition.top || config.position == WatermarkPosition.bottom) {
      return EdgeAnchoredRotated(
        targetEdge: config.position == WatermarkPosition.top ? ScreenEdge.top : ScreenEdge.bottom,
        quarterTurns: quarterTurns,
        margin: config.margin,
        child: panel,
      );
    }

    // Posisi sudut (topLeft/topRight/bottomLeft/bottomRight): tetap menempel
    // di sudut fisik yang sama, cuma kontennya yang berputar di tempat.
    return Positioned(
      top: _isTop(config.position) ? config.margin : null,
      bottom: _isTop(config.position) ? null : config.margin,
      left: _isRightAligned(config.position) ? null : config.margin,
      right: _isRightAligned(config.position) ? config.margin : null,
      child: RotatedBox(quarterTurns: quarterTurns, child: panel),
    );
  }

  bool _isTop(WatermarkPosition position) {
    return position == WatermarkPosition.top ||
        position == WatermarkPosition.topLeft ||
        position == WatermarkPosition.topRight;
  }

  bool _isRightAligned(WatermarkPosition position) {
    return position == WatermarkPosition.topRight || position == WatermarkPosition.bottomRight;
  }

  /// Susun baris teks live sesuai field yang diaktifkan, meniru urutan
  /// `WatermarkRenderer._buildTextLines` supaya preview konsisten dengan
  /// hasil akhir.
  List<Widget> _buildLines(WatermarkConfiguration config, LocationSnapshot location, AddressSnapshot? address) {
    final widgets = <Widget>[];
    final formatter = AddressFormatter();
    final bodyStyle = TextStyle(color: Colors.white, fontSize: config.fontSize);
    final titleStyle = TextStyle(
      color: Colors.white,
      fontSize: config.fontSize * 1.3,
      fontWeight: FontWeight.bold,
    );

    void addLine(String text, {bool isTitle = false}) {
      widgets.add(Padding(
        padding: EdgeInsets.only(bottom: config.spacing),
        child: Text(text, style: isTitle ? titleStyle : bodyStyle),
      ));
    }

    if (config.showLocationName && address != null) {
      final name = address.village ?? address.regency;
      if (name != null && name.isNotEmpty) addLine(name, isTitle: true);
    }

    if (config.showAddress) {
      if (address != null && !address.isEmpty) {
        final formatted = formatter.format(address, includeStreet: true, maxLength: 220);
        if (formatted.isNotEmpty) addLine(formatted);
      } else if (!config.showCoordinates) {
        addLine(_coordinatesText(location));
      }
    }

    if (config.showCoordinates) addLine(_coordinatesText(location));
    if (config.showDate) addLine(DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.now()));
    if (config.showTime) {
      final now = DateTime.now();
      final time = DateFormat('HH:mm:ss', 'id_ID').format(now);
      addLine(config.showTimezone ? '$time (${now.timeZoneName})' : time);
    }
    if (config.showAccuracy && location.accuracy != null) {
      addLine('Akurasi: ±${location.accuracy!.round()} m (${location.accuracyCategory.label})');
    }
    if (config.showAltitude && location.altitude != null) {
      addLine('Alt: ${location.altitude!.round()} m');
    }
    if (config.customText != null && config.customText!.trim().isNotEmpty) {
      addLine(config.customText!.trim());
    }
    addLine(config.appBrandingText);

    return widgets;
  }

  String _coordinatesText(LocationSnapshot location) {
    return '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
  }
}
