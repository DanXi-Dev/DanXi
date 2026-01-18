import 'dart:ui';

import 'package:dan_xi/common/constant.dart';
import 'package:flutter/material.dart';

class LanguageManager {
  /// Convert the [Language] to language code for [Locale].
  static Locale toLocale(Language language) {
    return switch (language) {
      Language.ENGLISH => const Locale("en"),
      Language.JAPANESE => const Locale("ja"),
      Language.SIMPLIFIED_CHINESE => const Locale.fromSubtags(
        languageCode: "zh",
        scriptCode: "Hans",
      ),
      Language.TRADITIONAL_CHINESE => const Locale.fromSubtags(
        languageCode: "zh",
        scriptCode: "Hant",
      ),
      _ => const Locale("en"),
    };
  }
}
