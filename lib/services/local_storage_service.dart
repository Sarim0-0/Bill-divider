import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _themeKey = 'isDarkMode';

  static Future<void> saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  static Future<bool> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to dark mode (true)
    return prefs.getBool(_themeKey) ?? true;
  }
}

