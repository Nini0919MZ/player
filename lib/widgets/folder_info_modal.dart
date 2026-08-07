import 'dart:io';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

void showFolderInfo(BuildContext context, String folderName, String folderPath, List<SongModel> songs) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF222222),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (context) => _FolderInfoModal(
      folderName: folderName,
      folderPath: folderPath,
      songs: songs,
    ),
  );
}

class _FolderInfoModal extends StatefulWidget {
  final String folderName;
  final String folderPath;
  final List<SongModel> songs;

  const _FolderInfoModal({
    required this.folderName,
    required this.folderPath,
    required this.songs,
  });

  @override
  State<_FolderInfoModal> createState() => _FolderInfoModalState();
}
class _FolderInfoModalState extends State<_FolderInfoModal> {
  int _totalSize = 0;
  DateTime? _lastModified;
  DateTime? _creationDate;

  @override
  void initState() {
    super.initState();
    _loadFolderInfo();
  }

  Future<void> _loadFolderInfo() async {
    try {
      int size = 0;
      DateTime? latestMod;
      DateTime? earliestCreated;

      for (var song in widget.songs) {
        final file = File(song.data);
        if (await file.exists()) {
          size += await file.length();
          final stat = await file.stat();
          if (latestMod == null || stat.modified.isAfter(latestMod)) {
            latestMod = stat.modified;
          }
          final created = stat.changed;
          if (earliestCreated == null || created.isBefore(earliestCreated)) {
            earliestCreated = created;
          }
        }
      }

      if (mounted) {
        setState(() {
          _totalSize = size;
          _lastModified = latestMod;
          _creationDate = earliestCreated;
        });
      }
    } catch (e) {
      debugPrint('Error reading folder stats: $e');
    }
  }

  String _formatDate(DateTime dt) {
    final months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    final d = dt.day.toString().padLeft(2, '0');
    final m = months[dt.month - 1];
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d $m $y, $h:$min';
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    final kb = bytes / 1024;
    final mb = kb / 1024;
    if (mb > 1024) {
      return "${(mb / 1024).toStringAsFixed(2)} GB";
    }
    return "${mb.toStringAsFixed(2)} MB";
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.folder, color: Colors.amber, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Información de carpeta",
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      Text(
                        widget.folderName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow("Ruta", widget.folderPath),
            _buildInfoRow("Cantidad de archivos", "${widget.songs.length} pistas de audio"),
            _buildInfoRow("Tamaño total", _totalSize > 0 ? _formatSize(_totalSize) : "Calculando..."),
            _buildInfoRow("Fecha de creación", _creationDate != null 
                ? _formatDate(_creationDate!) 
                : "Desconocida"),
            _buildInfoRow("Última modificación", _lastModified != null 
                ? _formatDate(_lastModified!) 
                : "Desconocida"),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
