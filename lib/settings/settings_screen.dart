import 'package:flutter/material.dart';

/// Placeholder untuk Fase 1 (App Shell). Field visibility, template, dan
/// persistence akan ditambahkan pada Fase 11 sesuai workflow-free-first.md.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Tampilkan halaman pengaturan (masih placeholder, logic ditambahkan
  /// pada Fase 11 sesuai workflow-free-first.md).
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Pengaturan watermark, template, dan penyimpanan akan tersedia '
            'pada fase berikutnya.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
