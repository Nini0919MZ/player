import 'package:shared_preferences/shared_preferences.dart';

enum PlaybackMode { folder, global }

class StatePersistence {
  static const double defaultEpicenterSweepFreq = 45.0;
  static const double defaultEpicenterWidth = 50.0;
  static const double defaultEpicenterIntensity = 50.0;
  static const double defaultEpicenterBalance = 50.0;
  static const double defaultEpicenterVolume = 100.0;

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

  // Epicenter parameters persistence
  static const String _epicenterSweepFreqKey = 'epicenter_sweep_freq';
  static const String _epicenterWidthKey = 'epicenter_width';
  static const String _epicenterIntensityKey = 'epicenter_intensity';
  static const String _epicenterBalanceKey = 'epicenter_balance';
  static const String _epicenterVolumeKey = 'epicenter_volume';

  static Future<Map<String, double>> loadEpicenterParams() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'sweepFreq':
          prefs.getDouble(_epicenterSweepFreqKey) ?? defaultEpicenterSweepFreq,
      'width': prefs.getDouble(_epicenterWidthKey) ?? defaultEpicenterWidth,
      'intensity':
          prefs.getDouble(_epicenterIntensityKey) ?? defaultEpicenterIntensity,
      'balance':
          prefs.getDouble(_epicenterBalanceKey) ?? defaultEpicenterBalance,
      'volume': prefs.getDouble(_epicenterVolumeKey) ?? defaultEpicenterVolume,
    };
  }

  static Future<void> saveEpicenterParams({
    required double sweepFreq,
    required double width,
    required double intensity,
    required double balance,
    required double volume,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_epicenterSweepFreqKey, sweepFreq);
    await prefs.setDouble(_epicenterWidthKey, width);
    await prefs.setDouble(_epicenterIntensityKey, intensity);
    await prefs.setDouble(_epicenterBalanceKey, balance);
    await prefs.setDouble(_epicenterVolumeKey, volume);
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

  // Tab count persistence (how many tabs to show in the main UI)
  static const String _tabCountKey = 'main_tab_count';

  static Future<int> loadTabCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_tabCountKey) ?? 3; // default 3 tabs (Carpetas, Canciones, Favoritos)
  }

  static Future<void> saveTabCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tabCountKey, count);
  }
}

