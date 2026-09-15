import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../storage/photo_storage_service.dart';
import 'models/history_entry.dart';
import 'photo_history_service.dart';

/// Layar riwayat foto: gallery grid dari [PhotoHistoryService], dengan
/// detail (swipe antar-foto), share, delete, dan pilih-banyak (tekan-tahan).
/// Tidak memakai database server, hanya index JSON lokal.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _historyService = PhotoHistoryService();
  final _storageService = PhotoStorageService();

  List<HistoryEntry>? _entries;
  final Set<String> _selectedBaseNames = {};

  bool get _isSelecting => _selectedBaseNames.isNotEmpty;

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

  /// Masuk/toggle mode pilih-banyak lewat tekan-tahan salah satu foto.
  void _toggleSelection(HistoryEntry entry) {
    setState(() {
      if (_selectedBaseNames.contains(entry.baseName)) {
        _selectedBaseNames.remove(entry.baseName);
      } else {
        _selectedBaseNames.add(entry.baseName);
      }
    });
  }

  void _cancelSelection() {
    setState(_selectedBaseNames.clear);
  }

  /// Hapus semua foto yang sedang dipilih di mode pilih-banyak.
  Future<void> _deleteSelected() async {
    final confirmed = await _confirmDelete(count: _selectedBaseNames.length);
    if (confirmed != true) return;

    for (final baseName in _selectedBaseNames) {
      await _storageService.deleteByBaseName(baseName);
      await _historyService.remove(baseName);
    }
    _selectedBaseNames.clear();
    await _loadEntries();
  }

  Future<bool?> _confirmDelete({required int count}) {
    final message = count == 1
        ? 'Foto original dan processed akan dihapus permanen.'
        : '$count foto (original dan processed) akan dihapus permanen.';
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(count == 1 ? 'Hapus foto ini?' : 'Hapus $count foto ini?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  /// Bagikan semua foto yang sedang dipilih sekaligus lewat satu share sheet.
  Future<void> _shareSelected() async {
    final entries = _entries ?? [];
    final files = entries
        .where((entry) => _selectedBaseNames.contains(entry.baseName))
        .map((entry) => XFile(entry.processedPath))
        .toList();
    if (files.isEmpty) return;
    await Share.shareXFiles(files);
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    return Scaffold(
      appBar: _isSelecting ? _buildSelectionAppBar() : AppBar(title: const Text('Riwayat Foto')),
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
                      final selected = _selectedBaseNames.contains(entry.baseName);
                      return _HistoryThumbnail(
                        entry: entry,
                        selected: selected,
                        selectionMode: _isSelecting,
                        onTap: () => _isSelecting ? _toggleSelection(entry) : _openDetail(entries, index),
                        onLongPress: () => _toggleSelection(entry),
                      );
                    },
                  ),
                ),
    );
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
      leading: IconButton(
        tooltip: 'Batal pilih',
        icon: const Icon(Icons.close),
        onPressed: _cancelSelection,
      ),
      title: Text('${_selectedBaseNames.length} dipilih'),
      actions: [
        IconButton(tooltip: 'Bagikan', icon: const Icon(Icons.share_outlined), onPressed: _shareSelected),
        IconButton(tooltip: 'Hapus', icon: const Icon(Icons.delete_outline), onPressed: _deleteSelected),
      ],
    );
  }

  /// Buka layar detail mulai dari foto ke-[initialIndex], dengan seluruh
  /// [entries] supaya bisa swipe kiri/kanan pindah foto tanpa kembali ke grid.
  void _openDetail(List<HistoryEntry> entries, int initialIndex) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _HistoryDetailScreen(entries: entries, initialIndex: initialIndex),
      ),
    );
    // Foto mungkin dihapus selagi di layar detail — muat ulang supaya grid selalu sinkron.
    await _loadEntries();
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
  const _HistoryThumbnail({
    required this.entry,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  final HistoryEntry entry;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(entry.processedPath), fit: BoxFit.cover),
          ),
          if (selectionMode)
            Positioned(
              top: 6,
              right: 6,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: selected ? Theme.of(context).colorScheme.primary : Colors.black.withValues(alpha: 0.4),
                child: Icon(
                  selected ? Icons.check : Icons.circle_outlined,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Layar detail foto: `PageView` supaya bisa swipe kiri/kanan pindah foto
/// tanpa kembali ke grid dulu. Foto ditampilkan di tengah layar (bukan
/// nempel atas seperti sebelumnya) supaya foto landscape juga proporsional.
/// Metadata (tanggal/koordinat/alamat) disembunyikan dulu dalam
/// `DraggableScrollableSheet` yang bisa ditarik naik dari bawah — meniru
/// pola Galeri Samsung — karena info yang sama sudah ada di watermark foto.
class _HistoryDetailScreen extends StatefulWidget {
  const _HistoryDetailScreen({required this.entries, required this.initialIndex});

  final List<HistoryEntry> entries;
  final int initialIndex;

  @override
  State<_HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<_HistoryDetailScreen> {
  final _historyService = PhotoHistoryService();
  final _storageService = PhotoStorageService();
  late final PageController _pageController;
  late List<HistoryEntry> _entries;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _entries = List.of(widget.entries);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  HistoryEntry get _current => _entries[_currentIndex];

  Future<void> _share() async {
    await Share.shareXFiles([XFile(_current.processedPath)]);
  }

  /// Tampilkan detail (tanggal/koordinat/alamat) lewat modal bottom sheet,
  /// cuma muncul saat ikon info diklik — supaya tidak menutupi foto secara
  /// permanen (info yang sama sudah ada di watermark foto).
  void _showInfo() {
    final entry = _current;
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(entry.timestamp);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // Material 3 membatasi lebar bottom sheet maks 640dp secara default,
      // yang di beberapa device (logical width > 640dp) membuatnya tampak
      // seperti kartu melayang dengan margin kiri-kanan alih-alih penuh
      // selebar layar. Dipaksa selebar layar sesuai permintaan user.
      constraints: const BoxConstraints(maxWidth: double.infinity),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
        );
      },
    );
  }

  /// Hapus foto yang sedang tampil. Kalau masih ada foto lain, lanjut ke
  /// foto berikutnya (atau sebelumnya jika itu foto terakhir); kalau list
  /// jadi kosong, otomatis kembali ke grid.
  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus foto ini?'),
        content: const Text('Foto original dan processed akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final entry = _current;
    await _storageService.deleteByBaseName(entry.baseName);
    await _historyService.remove(entry.baseName);
    if (!mounted) return;

    final deletedIndex = _currentIndex;
    setState(() {
      _entries.removeAt(deletedIndex);
      if (_entries.isNotEmpty && _currentIndex >= _entries.length) {
        _currentIndex = _entries.length - 1;
      }
    });

    if (_entries.isEmpty) {
      Navigator.of(context).pop();
    } else {
      _pageController.jumpToPage(_currentIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Foto'),
        actions: [
          IconButton(tooltip: 'Info foto', icon: const Icon(Icons.info_outline), onPressed: _showInfo),
          IconButton(tooltip: 'Bagikan', icon: const Icon(Icons.share_outlined), onPressed: _share),
          IconButton(tooltip: 'Hapus', icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _entries.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return Center(
            child: Image.file(File(_entries[index].processedPath), fit: BoxFit.contain),
          );
        },
      ),
    );
  }
}
