import 'dart:ui';

import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../page/home_page.dart';
import '/common/constant.dart';

class LanguageManager{

  LanguageManager(this.language);

  final Language language;

  ///Convert the [Language] to languagecode for [Locale]
  String languageCodeGenerator(Language language){
    if(language == Language.SCHINESE) return "zh";
    if(language == Language.ENGLISH) return "en";
    if(language == Language.JAPANESE) return "ja";
    return "?";
  }

  void setLanguage(){
    S.delegate.load(Locale(languageCodeGenerator(SettingsProvider.getInstance().language)));
    GlobalMaterialLocalizations.delegate.load(Locale(languageCodeGenerator(SettingsProvider.getInstance().language)));
    GlobalWidgetsLocalizations.delegate.load(Locale(languageCodeGenerator(SettingsProvider.getInstance().language)));
    GlobalCupertinoLocalizations.delegate.load(Locale(languageCodeGenerator(SettingsProvider.getInstance().language)));
    //Refresh the pages
    dashboardPageKey.currentState?.triggerRebuildFeatures();
    timetablePageKey.currentState?.pageRefresh();
    treeholePageKey.currentState?.pageRefresh();
  }

}