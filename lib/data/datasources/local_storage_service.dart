import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
    await saveLastUpdated(key, DateTime.now().toUtc());
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<void> saveLastUpdated(String key, DateTime time) async {
    await _prefs.setString('${key}_last_updated', time.toIso8601String());
  }

  DateTime? getLastUpdated(String key) {
    final str = _prefs.getString('${key}_last_updated');
    if (str == null) return null;
    return DateTime.tryParse(str);
  }
}
