import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  String _currentLanguage = 'es';

  String get currentLanguage => _currentLanguage;

  LanguageController() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? 'es';
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    _currentLanguage = _currentLanguage == 'es' ? 'en' : 'es';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _currentLanguage);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode == 'es' || languageCode == 'en') {
      _currentLanguage = languageCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, _currentLanguage);
      notifyListeners();
    }
  }
}
