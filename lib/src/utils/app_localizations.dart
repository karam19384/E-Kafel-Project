import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  static const supportedLocales = [
    Locale('ar'),
    Locale('en'),
  ];

  static const Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      'settings': 'الإعدادات',
      'appearance': 'المظهر والواجهة',
      'darkMode': 'الوضع الليلي',
      'darkModeDesc': 'تفعيل المظهر الداكن',
      'language': 'اللغة',
      // ... باقي النصوص
    },
    'en': {
      'settings': 'Settings',
      'appearance': 'Appearance & Interface',
      'darkMode': 'Dark Mode',
      'darkModeDesc': 'Enable dark theme',
      'language': 'Language',
      // ... باقي النصوص
    },
  };

  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String get settings {
    return _localizedValues[locale.languageCode]!['settings']!;
  }

  String get appearance {
    return _localizedValues[locale.languageCode]!['appearance']!;
  }

  String get darkMode {
    return _localizedValues[locale.languageCode]!['darkMode']!;
  }

  String get darkModeDesc {
    return _localizedValues[locale.languageCode]!['darkModeDesc']!;
  }

  String get language {
    return _localizedValues[locale.languageCode]!['language']!;
  }

  // ... باقي التوابع
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}