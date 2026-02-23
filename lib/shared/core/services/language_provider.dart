import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  // Varsayılan Dil: Türkçe
  Locale _currentLocale = const Locale('tr', 'TR');

  Locale get currentLocale => _currentLocale;

  void changeLanguage(Locale locale) {
    if (_currentLocale == locale) return;
    _currentLocale = locale;
    notifyListeners(); // Tüm uygulamayı uyar
  }
}
