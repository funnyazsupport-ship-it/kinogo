import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight key/value preferences (view mode, onboarding flags, last update
/// check, etc.). Mirrors `core/storage/preferences_storage.dart`.
class PreferencesStorage {
  PreferencesStorage(this._prefs);

  final SharedPreferences _prefs;

  static Future<PreferencesStorage> create() async {
    return PreferencesStorage(await SharedPreferences.getInstance());
  }

  static const kViewMode = 'view_mode'; // grid | list
  static const kLastUpdateCheck = 'last_update_check';

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  int? getInt(String key) => _prefs.getInt(key);
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
}
