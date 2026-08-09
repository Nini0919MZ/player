import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SmartArtwork extends StatefulWidget {
  final int albumId;
  final String songPath;
  final double size;
  final BorderRadius? borderRadius;
  final ArtworkType type;

  const SmartArtwork({
    super.key,
    required this.albumId,
    required this.songPath,
    required this.size,
    this.borderRadius,
    this.type = ArtworkType.ALBUM,
  });

  @override
  State<SmartArtwork> createState() => _SmartArtworkState();
}

class _SmartArtworkState extends State<SmartArtwork> {
  static const _mediaChannel = MethodChannel('com.jglhomer.player/media_utils');
  
  // Cache para evitar re-lecturas
  static final Map<String, Uint8List?> _artworkCache = {};
  
  Uint8List? _artworkBytes;
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  @override
  void didUpdateWidget(SmartArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songPath != widget.songPath || oldWidget.albumId != widget.albumId) {
      _artworkBytes = null;
      _tried = false;
      _loadArtwork();
    }
  }

  Future<void> _loadArtwork() async {
    final cacheKey = '${widget.albumId}_${widget.songPath}';
    
    if (_artworkCache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _artworkBytes = _artworkCache[cacheKey];
          _tried = true;
        });
      }
      return;
    }

    try {
      // Nivel 1: MediaStore (on_audio_query)
      Uint8List? bytes = await OnAudioQuery().queryArtwork(
        widget.albumId,
        widget.type,
        size: (widget.size * 2).toInt(),
      );

      // Nivel 2: MediaMetadataRetriever (MethodChannel nativo)
      if (bytes == null || bytes.isEmpty) {
        bytes = await _mediaChannel.invokeMethod<Uint8List>(
          'extractEmbeddedArtwork', 
          {'filePath': widget.songPath}
        );
      }

      _artworkCache[cacheKey] = bytes;

      if (mounted) {
        setState(() {
          _artworkBytes = bytes;
          _tried = true;
        });
      }
    } catch (_) {
      _artworkCache[cacheKey] = null;
      if (mounted) setState(() => _tried = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final Widget img;

    if (!_tried) {
      img = _placeholder(s);
    } else if (_artworkBytes != null && _artworkBytes!.isNotEmpty) {
      img = Image.memory(
        _artworkBytes!,
        width: s,
        height: s,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(s),
      );
    } else {
      // Nivel 3: Placeholder genérico
      img = _placeholder(s);
    }

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: img);
    }
    return img;
  }

  Widget _placeholder(double s) => Container(
        width: s,
        height: s,
        color: Colors.grey[800],
        child: Icon(
          widget.type == ArtworkType.ALBUM ? Icons.album : Icons.music_note,
          color: Colors.grey[600], 
          size: s * 0.4
        ),
      );
}
