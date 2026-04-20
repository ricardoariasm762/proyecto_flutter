import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class ThemeController extends ChangeNotifier {
  // Singleton
  static final ThemeController instance = ThemeController._();
  ThemeController._();

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool _useMaterial3 = true;
  bool get useMaterial3 => _useMaterial3;

  FlexScheme _usedScheme = FlexScheme.flutterDash;
  FlexScheme get usedScheme => _usedScheme;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void setUseMaterial3(bool useM3) {
    if (_useMaterial3 == useM3) return;
    _useMaterial3 = useM3;
    notifyListeners();
  }

  void setScheme(FlexScheme scheme) {
    if (_usedScheme == scheme) return;
    _usedScheme = scheme;
    notifyListeners();
  }
}
