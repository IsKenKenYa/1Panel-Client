import 'package:shared_preferences/shared_preferences.dart';
import 'log_level.dart';

class LogPreferencesService {
  static const String _minLogLevelKey = 'logger_min_level';

  Future<AppLogLevel> loadMinLogLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return AppLogLevel.fromStorage(prefs.getString(_minLogLevelKey));
  }

  Future<void> saveMinLogLevel(AppLogLevel level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_minLogLevelKey, level.storageValue);
  }
}
