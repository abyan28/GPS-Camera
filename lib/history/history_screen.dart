import 'package:flutter/material.dart';

/// Placeholder untuk Fase 1 (App Shell). Gallery, preview, share, dan delete
/// akan ditambahkan pada fase local storage/history lanjutan.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  /// Tampilkan halaman riwayat foto (masih placeholder, gallery/preview/
  /// share/delete ditambahkan pada fase local storage lanjutan).
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Foto')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Riwayat foto akan tersedia pada fase berikutnya.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
