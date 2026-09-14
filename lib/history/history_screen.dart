import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../storage/photo_storage_service.dart';
import 'models/history_entry.dart';
import 'photo_history_service.dart';

/// Layar riwayat foto: gallery grid dari [PhotoHistoryService], dengan
/// detail, share, dan delete. Tidak memakai database server, hanya index
/// JSON lokal.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _historyService = PhotoHistoryService();
  final _storageService = PhotoStorageService();

  List<HistoryEntry>? _entries;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  /// Muat ulang daftar riwayat foto dari index lokal.
  Future<void> _loadEntries() async {
    final entries = await _historyService.loadAll();
    if (mounted) setState(() => _entries = entries);
  }

  /// Hapus satu entri (file original+processed dan metadatanya) setelah
  /// pengguna mengonfirmasi.
  Future<void> _deleteEntry(HistoryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus foto ini?'),
        content: const Text('Foto original dan processed akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirmed != true) return;

    await _storageService.deleteByBaseName(entry.baseName);
    await _historyService.remove(entry.baseName);
    if (mounted) Navigator.of(context).pop();
    await _loadEntries();
  }

  /// Bagikan foto processed lewat native share sheet.
  Future<void> _shareEntry(HistoryEntry entry) async {
    await Share.shareXFiles([XFile(entry.processedPath)]);
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Foto')),
      body: entries == null
          ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty
              ? const _EmptyHistory()
              : RefreshIndicator(
                  onRefresh: _loadEntries,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _HistoryThumbnail(
                        entry: entry,
                        onTap: () => _openDetail(entry),
                      );
                    },
                  ),
                ),
    );
  }

  /// Buka layar detail satu foto: preview besar, metadata, share, delete.
  void _openDetail(HistoryEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _HistoryDetailScreen(
          entry: entry,
          onDelete: () => _deleteEntry(entry),
          onShare: () => _shareEntry(entry),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library_outlined, size: 48),
            const SizedBox(height: 12),
            Text('Belum ada foto', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'Foto yang Anda ambil akan muncul di sini.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryThumbnail extends StatelessWidget {
  const _HistoryThumbnail({required this.entry, required this.onTap});

  final HistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(File(entry.processedPath), fit: BoxFit.cover),
      ),
    );
  }
}

class _HistoryDetailScreen extends StatelessWidget {
  const _HistoryDetailScreen({required this.entry, required this.onDelete, required this.onShare});

  final HistoryEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(entry.timestamp);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Foto'),
        actions: [
          IconButton(tooltip: 'Bagikan', icon: const Icon(Icons.share_outlined), onPressed: onShare),
          IconButton(tooltip: 'Hapus', icon: const Icon(Icons.delete_outline), onPressed: onDelete),
        ],
      ),
      body: ListView(
        children: [
          Image.file(File(entry.processedPath)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formattedDate, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('${entry.latitude.toStringAsFixed(6)}, ${entry.longitude.toStringAsFixed(6)}'),
                if (entry.addressText != null && entry.addressText!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(entry.addressText!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
