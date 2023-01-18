import 'dart:ui';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class LanguageManager {
  LanguageManager(this.language);

  final Language language;

  /// Convert the [Language] to language code for [Locale].
  Locale languageCodeGenerator(Language language) {
    if (language == Language.SIMPLE_CHINESE) return const Locale("zh", "CN");
    if (language == Language.ENGLISH) return const Locale("en");
    if (language == Language.JAPANESE) return const Locale("ja");
    return const Locale("en");
  }

  void setLanguage() {
    final locale =
        languageCodeGenerator(SettingsProvider.getInstance().language);

    S.delegate.load(locale);
    GlobalMaterialLocalizations.delegate.load(locale);
    GlobalWidgetsLocalizations.delegate.load(locale);
    GlobalCupertinoLocalizations.delegate.load(locale);
  }
}
