import 'package:shared_preferences/shared_preferences.dart';

enum PlaybackMode { folder, global }

class StatePersistence {
  static const String _modeKey = 'playback_mode';
  static const String _folderPathKey = 'active_folder_path';
  static const String _songPathKey = 'current_song_path';
  static const String _positionKey = 'position_ms';
  static const String _favoritesKey = 'favorites';
  static const String _autoModeKey = 'auto_mode_enabled';
  static const String _legacyAutoModeKey = 'modo_auto';
  static const String _epicenterEnabledKey = 'epicenter_enabled';
  static const String _legacyEpicenterKey = 'epicentro';

  static Future<bool> loadAutoMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoModeKey) ??
        prefs.getBool(_legacyAutoModeKey) ??
        false;
  }

  static Future<void> saveAutoMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoModeKey, enabled);
    await prefs.setBool(_legacyAutoModeKey, enabled);
  }

  static Future<bool> loadEpicenterEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_epicenterEnabledKey) ??
        prefs.getBool(_legacyEpicenterKey) ??
        false;
  }

  static Future<void> saveEpicenterEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_epicenterEnabledKey, enabled);
    await prefs.setBool(_legacyEpicenterKey, enabled);
  }

  static Future<void> savePlaybackState({
    required PlaybackMode mode,
    String? folderPath,
    required String songPath,
    required int positionMs,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.toString());

    if (folderPath != null) {
      await prefs.setString(_folderPathKey, folderPath);
    } else {
      await prefs.remove(_folderPathKey);
    }

    await prefs.setString(_songPathKey, songPath);
    await prefs.setInt(_positionKey, positionMs);
  }

  static Future<Map<String, dynamic>> loadPlaybackState() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString(_modeKey);
    final mode = (modeStr == PlaybackMode.folder.toString())
        ? PlaybackMode.folder
        : PlaybackMode.global;

    return {
      'mode': mode,
      'folderPath': prefs.getString(_folderPathKey),
      'songPath': prefs.getString(_songPathKey),
      'positionMs': prefs.getInt(_positionKey) ?? 0,
    };
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
