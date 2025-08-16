import 'package:flutter/material.dart';

/// Simple theme provider to switch between light and dark themes.
class ThemeService extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get themeMode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setMode(ThemeMode m) {
    if (_mode != m) {
      _mode = m;
      notifyListeners();
    }
  }
}
