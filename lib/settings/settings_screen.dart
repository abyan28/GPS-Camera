import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../watermark/models/watermark_position.dart';
import '../watermark/models/watermark_template.dart';
import 'settings_controller.dart';

/// Layar pengaturan watermark: template, field visibility, posisi,
/// appearance, dan opsi penyimpanan foto original. Semua perubahan
/// langsung dipersist oleh [SettingsController].
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();

    if (!controller.isLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pengaturan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final watermark = controller.settings.watermark;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader('Template'),
          _TemplatePicker(controller: controller),
          const Divider(height: 24),
          _SectionHeader('Informasi yang ditampilkan'),
          SwitchListTile(
            title: const Text('Nama lokasi'),
            value: watermark.showLocationName,
            onChanged: (value) => controller.updateWatermark((c) => c.copyWith(showLocationName: value)),
          ),
          SwitchListTile(
            title: const Text('Alamat lengkap'),
            value: watermark.showAddress,
            onChanged: (value) => controller.updateWatermark((c) => c.copyWith(showAddress: value)),
          ),
          SwitchListTile(
            title: const Text('Koordinat'),
            value: watermark.showCoordinates,
            onChanged: (value) => controller.updateWatermark((c) => c.copyWith(showCoordinates: value)),
          ),
          SwitchListTile(
            title: const Text('Tanggal'),
            value: watermark.showDate,
            onChanged: (value) => controller.updateWatermark((c) => c.copyWith(showDate: value)),
          ),
          SwitchListTile(
            title: const Text('Waktu'),
            value: watermark.showTime,
            onChanged: (value) => controller.updateWatermark((c) => c.copyWith(showTime: value)),
          ),
          SwitchListTile(
            title: const Text('Zona waktu'),
            value: watermark.showTimezone,
            onChanged: (value) => controller.updateWatermark((c) => c.copyWith(showTimezone: value)),
          ),
          SwitchListTile(
            title: const Text('Akurasi GPS'),
            value: watermark.showAccuracy,
            onChanged: (value) => controller.updateWatermark((c) => c.copyWith(showAccuracy: value)),
          ),
          SwitchListTile(
            title: const Text('Ketinggian (altitude)'),
            value: watermark.showAltitude,
            onChanged: (value) => controller.updateWatermark((c) => c.copyWith(showAltitude: value)),
          ),
          SwitchListTile(
            title: const Text('Thumbnail peta'),
            value: watermark.showMapThumbnail,
            onChanged: (value) => controller.updateWatermark((c) => c.copyWith(showMapThumbnail: value)),
          ),
          const Divider(height: 24),
          _SectionHeader('Posisi watermark'),
          _PositionPicker(controller: controller),
          const Divider(height: 24),
          _SectionHeader('Tampilan'),
          _SliderSetting(
            label: 'Transparansi panel',
            value: watermark.opacity,
            min: 0.1,
            max: 1.0,
            // Nilainya geser kontinu (bukan bilangan bulat 0/1) — pakai
            // format persen supaya label ikut berubah halus sesuai posisi
            // geser, bukan dibulatkan ke 0 atau 1 seperti slider lain.
            labelFormatter: (value) => '${(value * 100).round()}%',
            onChanged: (value) => controller.updateWatermark((c) => c.copyWith(opacity: value)),
          ),
          _SliderSetting(
            label: 'Ukuran teks',
            value: watermark.fontSize,
            min: 10,
            max: 32,
            onChanged: (value) => controller.updateWatermark((c) => c.copyWith(fontSize: value)),
          ),
          _SliderSetting(
            label: 'Ukuran thumbnail peta',
            value: watermark.thumbnailSize,
            min: 0,
            max: 160,
            onChanged: (value) => controller.updateWatermark((c) => c.copyWith(thumbnailSize: value)),
          ),
          _SliderSetting(
            label: 'Zoom peta',
            value: watermark.mapZoom.toDouble(),
            min: 12,
            max: 19,
            divisions: 7,
            onChanged: (value) => controller.updateWatermark((c) => c.copyWith(mapZoom: value.round())),
          ),
          const Divider(height: 24),
          _SectionHeader('Teks tambahan'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextFormField(
              key: ValueKey(watermark.customText),
              initialValue: watermark.customText,
              decoration: const InputDecoration(
                labelText: 'Teks custom (opsional)',
                hintText: 'Contoh: Nama proyek atau catatan lapangan',
              ),
              onFieldSubmitted: (value) => controller.updateWatermark(
                (c) => c.copyWith(customText: value.trim().isEmpty ? null : value.trim()),
              ),
            ),
          ),
          const Divider(height: 24),
          _SectionHeader('Penyimpanan'),
          SwitchListTile(
            title: const Text('Simpan foto original'),
            subtitle: const Text('Foto tanpa watermark tetap disimpan terpisah'),
            value: controller.settings.saveOriginal,
            onChanged: controller.setSaveOriginal,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _TemplatePicker extends StatelessWidget {
  const _TemplatePicker({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: WatermarkTemplate.values.map((template) {
          return ChoiceChip(
            label: Text(template.label),
            selected: false,
            onSelected: (_) => controller.applyTemplate(template),
          );
        }).toList(),
      ),
    );
  }
}

class _PositionPicker extends StatelessWidget {
  const _PositionPicker({required this.controller});

  final SettingsController controller;

  static const _labels = {
    WatermarkPosition.top: 'Atas',
    WatermarkPosition.bottom: 'Bawah',
    WatermarkPosition.topLeft: 'Kiri Atas',
    WatermarkPosition.topRight: 'Kanan Atas',
    WatermarkPosition.bottomLeft: 'Kiri Bawah',
    WatermarkPosition.bottomRight: 'Kanan Bawah',
  };

  @override
  Widget build(BuildContext context) {
    final current = controller.settings.watermark.position;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: WatermarkPosition.values.map((position) {
          return ChoiceChip(
            label: Text(_labels[position]!),
            selected: current == position,
            onSelected: (_) => controller.updateWatermark((c) => c.copyWith(position: position)),
          );
        }).toList(),
      ),
    );
  }
}

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.labelFormatter,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  /// Format tampilan nilai di label, default bilangan bulat. Dipakai untuk
  /// slider yang nilainya BUKAN bilangan bulat (mis. opacity 0.1-1.0) supaya
  /// label ikut berubah sesuai posisi geser, bukan dibulatkan ke 0/1.
  final String Function(double value)? labelFormatter;

  @override
  Widget build(BuildContext context) {
    final formattedValue = labelFormatter?.call(value) ?? value.round().toString();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: $formattedValue'),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
