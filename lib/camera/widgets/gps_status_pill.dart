import 'package:flutter/material.dart';

import '../../core/theme/camera_tokens.dart';
import '../../location/models/location_snapshot.dart';

/// Pill mengambang di atas viewfinder kamera yang menampilkan status akurasi
/// GPS secara real-time dengan kode warna semantik.
class GpsStatusPill extends StatelessWidget {
  const GpsStatusPill({
    super.key,
    required this.location,
    this.onTap,
  });

  final LocationSnapshot? location;
  final VoidCallback? onTap;

  Color _statusColor() {
    if (location == null) return CameraTokens.gpsSearching;
    switch (location!.accuracyCategory) {
      case AccuracyCategory.excellent:
        return CameraTokens.gpsExcellent;
      case AccuracyCategory.good:
        return CameraTokens.gpsGood;
      case AccuracyCategory.fair:
        return CameraTokens.gpsFair;
      case AccuracyCategory.poor:
        return CameraTokens.gpsPoor;
      case AccuracyCategory.unknown:
        return CameraTokens.gpsSearching;
    }
  }

  String _statusText() {
    if (location == null) return 'Mencari GPS...';
    if (location!.accuracy != null) {
      return '±${location!.accuracy!.round()} m';
    }
    return location!.accuracyCategory.label;
  }

  void _showGpsDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final loc = location;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _statusColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Status Sensor GPS',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (loc != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.gps_fixed),
                  title: const Text('Kategori Akurasi'),
                  subtitle: Text('${loc.accuracyCategory.label} (±${loc.accuracy?.round() ?? '-'} meter)'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.my_location),
                  title: const Text('Koordinat Terkunci'),
                  subtitle: Text('${loc.latitude.toStringAsFixed(6)}, ${loc.longitude.toStringAsFixed(6)}'),
                ),
                if (loc.altitude != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.height),
                    title: const Text('Ketinggian (Altitude)'),
                    subtitle: Text('${loc.altitude!.round()} m di atas permukaan laut'),
                  ),
              ] else ...[
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.gps_not_fixed, color: Colors.amber),
                  title: Text('Menunggu Sinyal Satelit'),
                  subtitle: Text(
                    'Pastikan GPS aktif dan berada di area terbuka untuk mendapatkan koordinat akurat.',
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showGpsDetail(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: CameraTokens.hudBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: CameraTokens.hudBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _statusText(),
                style: const TextStyle(
                  color: CameraTokens.textHighEmphasis,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}
