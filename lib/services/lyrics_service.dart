import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path/path.dart' as path;

enum LyricsSource { embedded, internet }

class LyricsLine {
  final Duration timestamp;
  final String text;

  const LyricsLine({required this.timestamp, required this.text});
}

class LyricsResult {
  final String text;
  final List<LyricsLine> lines;

  const LyricsResult({required this.text, this.lines = const []});

  bool get hasTimestamps => lines.isNotEmpty;
}

class LyricsService {
  static const MethodChannel _mediaChannel =
      MethodChannel('com.jglhomer.player/media_utils');
  static final Map<String, LyricsResult?> _cache = {};

  static Future<LyricsResult?> load(SongModel song, LyricsSource source) async {
    final key = '${source.name}:${song.data}';
    if (_cache.containsKey(key)) return _cache[key];

    final lyrics = source == LyricsSource.embedded
        ? await _loadEmbedded(song.data)
        : await _loadFromInternet(song);
    _cache[key] = lyrics;
    return lyrics;
  }

  static void clearCache() => _cache.clear();

  static Future<LyricsResult?> _loadEmbedded(String filePath) async {
    try {
      final lyrics = await _mediaChannel.invokeMethod<String>(
        'extractEmbeddedLyrics',
        {'filePath': filePath},
      );
      return _parse(lyrics);
    } on PlatformException {
      return null;
    }
  }

  static Future<LyricsResult?> _loadFromInternet(SongModel song) async {
    final title = _cleanTitle(song);
    final artist = song.artist?.trim() ?? '';
    if (title.trim().isEmpty) return null;

    final query = Uri.https('lrclib.net', '/api/get', {
      'track_name': title,
      if (artist.isNotEmpty && artist != '<unknown>') 'artist_name': artist,
    });

    final client = HttpClient();
    try {
      final request = await client.getUrl(query);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        return _search(client, title, artist, song);
      }
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      return _parse(decoded['syncedLyrics'] as String?) ??
          _parse(decoded['plainLyrics'] as String?) ??
          await _search(client, title, artist, song);
    } catch (error) {
      debugPrint('[Lyrics] Error consultando LRCLIB: $error');
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static Future<LyricsResult?> _search(
      HttpClient client, String title, String artist, SongModel song) async {
    final query = Uri.https('lrclib.net', '/api/search', {
      'q': artist.isEmpty ? title : '$artist $title',
    });
    final request = await client.getUrl(query);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) return null;
    final body = await response.transform(utf8.decoder).join();
    final decoded = jsonDecode(body);
    if (decoded is! List || decoded.isEmpty) return null;
    final candidates = [
      title.toLowerCase(),
      _cleanFileTitle(song.data).toLowerCase(),
    ];
    for (final item in decoded) {
      if (item is! Map) continue;
      final resultTitle = item['trackName']?.toString().toLowerCase() ?? '';
      if (resultTitle.isNotEmpty &&
          !candidates.any((candidate) =>
              candidate == resultTitle ||
              candidate.contains(resultTitle) ||
              resultTitle.contains(candidate))) {
        continue;
      }
      final lyrics = _parse(item['syncedLyrics'] as String?) ??
          _parse(item['plainLyrics'] as String?);
      if (lyrics != null) return lyrics;
    }

    return null;
  }

  static String _cleanTitle(SongModel song) {
    final title = song.title.trim();
    if (title.isNotEmpty && title != '<unknown>') return title;
    return _cleanFileTitle(song.data);
  }

  static String _cleanFileTitle(String filePath) {
    final name = path.basenameWithoutExtension(filePath);
    return name.replaceAll(RegExp(r'[_]+'), ' ').trim();
  }

  static LyricsResult? _parse(String? value) {
    final cleaned = _clean(value);
    if (cleaned == null) return null;
    final lines = <LyricsLine>[];
    final timestampPattern =
        RegExp(r'^\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]\s*(.*)$');
    for (final rawLine in cleaned.split('\n')) {
      final match = timestampPattern.firstMatch(rawLine.trim());
      if (match == null) continue;
      final minutes = int.parse(match.group(1)!);
      final seconds = int.parse(match.group(2)!);
      final fraction = match.group(3) ?? '0';
      final milliseconds = fraction.length == 1
          ? int.parse(fraction) * 100
          : fraction.length == 2
              ? int.parse(fraction) * 10
              : int.parse(fraction.padRight(3, '0').substring(0, 3));
      final text = match.group(4)!.trim();
      if (text.isNotEmpty) {
        lines.add(LyricsLine(
          timestamp: Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: milliseconds,
          ),
          text: text,
        ));
      }
    }
    if (lines.isEmpty) return LyricsResult(text: cleaned);
    return LyricsResult(
      text: lines.map((line) => line.text).join('\n'),
      lines: lines,
    );
  }

  static String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }
}
