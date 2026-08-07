import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Widget que intenta cargar la portada de varias formas:
/// 1. Lee bytes APIC directamente del MP3 (máxima compatibilidad con tags editados)
/// 2. Fallback a QueryArtworkWidget (base de datos de Android)
/// 3. Fallback a ícono gris
class SmartArtwork extends StatefulWidget {
  final int albumId;
  final String songPath;
  final double size;
  final BorderRadius? borderRadius;

  const SmartArtwork({
    super.key,
    required this.albumId,
    required this.songPath,
    required this.size,
    this.borderRadius,
  });

  @override
  State<SmartArtwork> createState() => _SmartArtworkState();
}

class _SmartArtworkState extends State<SmartArtwork> {
  Uint8List? _id3Bytes;
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    _tryLoadId3();
  }

  @override
  void didUpdateWidget(SmartArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la ruta cambió (canción diferente), recargar
    if (oldWidget.songPath != widget.songPath) {
      _id3Bytes = null;
      _tried = false;
      _tryLoadId3();
    }
  }

  Future<void> _tryLoadId3() async {
    try {
      final file = File(widget.songPath);
      if (!await file.exists()) {
        if (mounted) setState(() => _tried = true);
        return;
      }
      final bytes = await file.readAsBytes();
      final extracted = _extractApicBytes(bytes);
      if (mounted) {
        setState(() {
          _id3Bytes = extracted;
          _tried = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _tried = true);
    }
  }

  /// Extrae los bytes de imagen del frame APIC de un MP3 con ID3v2
  Uint8List? _extractApicBytes(Uint8List bytes) {
    if (bytes.length < 10) return null;
    if (bytes[0] != 0x49 || bytes[1] != 0x44 || bytes[2] != 0x33) return null;

    final int id3Size = ((bytes[6] & 0x7F) << 21) |
        ((bytes[7] & 0x7F) << 14) |
        ((bytes[8] & 0x7F) << 7) |
        (bytes[9] & 0x7F);
    int offset = 10;
    final int end = (offset + id3Size).clamp(0, bytes.length);

    while (offset + 10 < end) {
      final frameId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final frameSize = (bytes[offset + 4] << 24) |
          (bytes[offset + 5] << 16) |
          (bytes[offset + 6] << 8) |
          bytes[offset + 7];
      if (frameSize <= 0 || frameSize > bytes.length) break;
      offset += 10;

      if (frameId == 'APIC' && offset + frameSize <= bytes.length) {
        int i = offset;
        i++; // encoding byte
        while (i < offset + frameSize && bytes[i] != 0) i++; // mime type
        if (i >= offset + frameSize) { offset += frameSize; continue; }
        i++; // null terminator
        if (i >= offset + frameSize) { offset += frameSize; continue; }
        i++; // picture type byte
        while (i < offset + frameSize && bytes[i] != 0) i++; // description
        if (i >= offset + frameSize) { offset += frameSize; continue; }
        i++; // null terminator
        if (i < offset + frameSize) {
          return bytes.sublist(i, offset + frameSize);
        }
      }
      offset += frameSize;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final Widget img;

    if (_id3Bytes != null && _id3Bytes!.isNotEmpty) {
      img = Image.memory(
        _id3Bytes!,
        width: s,
        height: s,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackQuery(s),
      );
    } else {
      img = QueryArtworkWidget(
        id: widget.albumId,
        type: ArtworkType.ALBUM,
        size: (s * 2).toInt(),
        artworkHeight: s,
        artworkWidth: s,
        nullArtworkWidget: _placeholder(s),
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: img);
    }
    return img;
  }

  Widget _fallbackQuery(double s) => QueryArtworkWidget(
        id: widget.albumId,
        type: ArtworkType.ALBUM,
        size: (s * 2).toInt(),
        artworkHeight: s,
        artworkWidth: s,
        nullArtworkWidget: _placeholder(s),
      );

  Widget _placeholder(double s) => Container(
        width: s,
        height: s,
        color: Colors.grey[800],
        child: Icon(Icons.music_note, color: Colors.grey[600], size: s * 0.4),
      );
}
