import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';

class ThemeManager extends ChangeNotifier {
  bool _isDarkMode = true; // Default to dark mode

  bool get isDarkMode => _isDarkMode;

  ThemeManager() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _isDarkMode = await LocalStorageService.loadTheme();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await LocalStorageService.saveTheme(_isDarkMode);
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      await LocalStorageService.saveTheme(_isDarkMode);
      notifyListeners();
    }
  }
}

