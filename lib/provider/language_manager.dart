import 'dart:ui';

import 'package:dan_xi/common/constant.dart';
import 'package:flutter/material.dart';

class LanguageManager {
  /// Convert the [Language] to language code for [Locale].
  static Locale toLocale(Language language) {
    if (language == Language.SIMPLE_CHINESE) return const Locale("zh", "CN");
    if (language == Language.ENGLISH) return const Locale("en");
    if (language == Language.JAPANESE) return const Locale("ja");
    return const Locale("en");
  }
}
