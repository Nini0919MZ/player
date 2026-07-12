import 'package:shared_preferences/shared_preferences.dart';

enum PlaybackMode { folder, global, album, custom }

class StatePersistence {
  static const String _modeKey = 'playback_mode';
  static const String _folderPathKey = 'active_folder_path';
  static const String _albumNameKey = 'active_album_name';
  static const String _songIdKey = 'current_song_id';
  static const String _songPathKey = 'current_song_path';
  static const String _currentIndexKey = 'current_index';
  static const String _positionKey = 'position_ms';
  static const String _playlistIdsKey = 'playlist_song_ids';
  static const String _playlistPathsKey = 'playlist_song_paths';
  static const String _shuffleKey = 'shuffle_enabled';
  static const String _loopModeKey = 'loop_mode';
  static const String _wasPlayingKey = 'was_playing';
  static const String _favoritesKey = 'favorites';
  static const String _autoModeKey = 'auto_mode_enabled';

  static Future<bool> loadAutoMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoModeKey) ?? false;
  }

  static Future<void> saveAutoMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoModeKey, enabled);
  }

  static Future<void> savePlaybackState({
    required PlaybackMode mode,
    String? folderPath,
    String? albumName,
    required int songId,
    required String songPath,
    required int currentIndex,
    required int positionMs,
    required List<int> playlistSongIds,
    required List<String> playlistSongPaths,
    required bool shuffle,
    required int loopModeIndex,
    required bool wasPlaying,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);

    if (folderPath != null) {
      await prefs.setString(_folderPathKey, folderPath);
    } else {
      await prefs.remove(_folderPathKey);
    }

    if (albumName != null) {
      await prefs.setString(_albumNameKey, albumName);
    } else {
      await prefs.remove(_albumNameKey);
    }

    await prefs.setInt(_songIdKey, songId);
    await prefs.setString(_songPathKey, songPath);
    await prefs.setInt(_currentIndexKey, currentIndex);
    await prefs.setInt(_positionKey, positionMs);
    await prefs.setStringList(
      _playlistIdsKey,
      playlistSongIds.map((id) => id.toString()).toList(),
    );
    await prefs.setStringList(_playlistPathsKey, playlistSongPaths);
    await prefs.setBool(_shuffleKey, shuffle);
    await prefs.setInt(_loopModeKey, loopModeIndex);
    await prefs.setBool(_wasPlayingKey, wasPlaying);
  }

  static Future<Map<String, dynamic>> loadPlaybackState() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString(_modeKey);
    final mode = _parsePlaybackMode(modeStr);
    final playlistIds = (prefs.getStringList(_playlistIdsKey) ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .toList();

    return {
      'mode': mode,
      'folderPath': prefs.getString(_folderPathKey),
      'albumName': prefs.getString(_albumNameKey),
      'songId': prefs.getInt(_songIdKey),
      'songPath': prefs.getString(_songPathKey),
      'currentIndex': prefs.getInt(_currentIndexKey) ?? 0,
      'positionMs': prefs.getInt(_positionKey) ?? 0,
      'playlistSongIds': playlistIds,
      'playlistSongPaths': prefs.getStringList(_playlistPathsKey) ?? [],
      'shuffle': prefs.getBool(_shuffleKey) ?? false,
      'loopModeIndex': prefs.getInt(_loopModeKey) ?? 0,
      'wasPlaying': prefs.getBool(_wasPlayingKey) ?? false,
    };
  }

  static PlaybackMode _parsePlaybackMode(String? value) {
    if (value == null) return PlaybackMode.global;
    for (final mode in PlaybackMode.values) {
      if (value == mode.name || value == mode.toString()) {
        return mode;
      }
    }
    return PlaybackMode.global;
  }

  static Future<Set<int>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList(_favoritesKey) ?? [];
    return favList.map((id) => int.parse(id)).toSet();
  }

  static Future<void> saveFavorites(Set<int> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _favoritesKey, favorites.map((id) => id.toString()).toList());
  }
}
