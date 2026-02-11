import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Context üzerinden erişim için yardımcı metod
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('tr'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // --- SÖZLÜK ---
  static final Map<String, Map<String, String>> _localizedValues = {
    'tr': {
      'profile_title': 'Profilim',
      'language_settings': 'Dil Seçimi / Language',
      'my_orders': 'Siparişlerim',
      'my_addresses': 'Adreslerim',
      'live_support': 'Canlı Destek',
      'logout': 'Çıkış Yap',
      'phone_missing': 'Telefon eklenmemiş',
      'guest_user': 'Misafir Kullanıcı',
      // Diğer sayfalar için buraya eklemeler yapılabilir
    },
    'en': {
      'profile_title': 'My Profile',
      'language_settings': 'Language / Dil Seçimi',
      'my_orders': 'My Orders',
      'my_addresses': 'My Addresses',
      'live_support': 'Live Support',
      'logout': 'Log Out',
      'phone_missing': 'No phone number',
      'guest_user': 'Guest User',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['tr', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
