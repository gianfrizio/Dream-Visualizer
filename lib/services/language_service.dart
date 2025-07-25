import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';

  Locale _currentLocale = const Locale('it', 'IT');

  Locale get currentLocale => _currentLocale;

  String get currentLanguageCode => _currentLocale.languageCode;

  String get speechLanguageCode {
    switch (_currentLocale.languageCode) {
      case 'it':
        return 'it-IT';
      case 'en':
        return 'en-US';
      default:
        return 'it-IT';
    }
  }

  // Lista delle lingue supportate
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
  ];

  // Inizializza il servizio caricando la lingua salvata
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey) ?? 'it';
    _currentLocale = Locale(savedLanguage);
    notifyListeners();
  }

  // Cambia la lingua dell'app
  Future<void> changeLanguage(String languageCode) async {
    if (languageCode != _currentLocale.languageCode) {
      _currentLocale = Locale(languageCode);

      // Salva la preferenza
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);

      notifyListeners();
    }
  }

  // Ottieni il nome della lingua corrente
  String getCurrentLanguageName() {
    return supportedLanguages.firstWhere(
      (lang) => lang['code'] == _currentLocale.languageCode,
      orElse: () => supportedLanguages.first,
    )['name']!;
  }

  // Ottieni la bandiera della lingua corrente
  String getCurrentLanguageFlag() {
    return supportedLanguages.firstWhere(
      (lang) => lang['code'] == _currentLocale.languageCode,
      orElse: () => supportedLanguages.first,
    )['flag']!;
  }
}
