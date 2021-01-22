// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values

class S {
  S();

  static S current;

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      S.current = S();

      return S.current;
    });
  }

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `DanXi`
  String get app_name {
    return Intl.message(
      'DanXi',
      name: 'app_name',
      desc: '',
      args: [],
    );
  }

  /// `ECard Code`
  String get fudan_qr_code {
    return Intl.message(
      'ECard Code',
      name: 'fudan_qr_code',
      desc: '',
      args: [],
    );
  }

  /// `Welcome, {name}!`
  String welcome(Object name) {
    return Intl.message(
      'Welcome, $name!',
      name: 'welcome',
      desc: '',
      args: [name],
    );
  }

  /// `Connectivity`
  String get current_connection {
    return Intl.message(
      'Connectivity',
      name: 'current_connection',
      desc: '',
      args: [],
    );
  }

  /// `Ecard balance`
  String get ecard_balance {
    return Intl.message(
      'Ecard balance',
      name: 'ecard_balance',
      desc: '',
      args: [],
    );
  }

  /// `Dining hall crowdedness`
  String get dining_hall_crowdedness {
    return Intl.message(
      'Dining hall crowdedness',
      name: 'dining_hall_crowdedness',
      desc: '',
      args: [],
    );
  }

  /// `Fudan daily`
  String get fudan_daily {
    return Intl.message(
      'Fudan daily',
      name: 'fudan_daily',
      desc: '',
      args: [],
    );
  }

  /// `You have reported today!`
  String get fudan_daily_ticked {
    return Intl.message(
      'You have reported today!',
      name: 'fudan_daily_ticked',
      desc: '',
      args: [],
    );
  }

  /// `Click to report`
  String get fudan_daily_tick {
    return Intl.message(
      'Click to report',
      name: 'fudan_daily_tick',
      desc: '',
      args: [],
    );
  }

  /// `Loading...`
  String get loading {
    return Intl.message(
      'Loading...',
      name: 'loading',
      desc: '',
      args: [],
    );
  }

  /// `Failed to obtain WiFi information`
  String get current_connection_failed {
    return Intl.message(
      'Failed to obtain WiFi information',
      name: 'current_connection_failed',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'zh'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);

  @override
  Future<S> load(Locale locale) => S.load(locale);

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    if (locale != null) {
      for (var supportedLocale in supportedLocales) {
        if (supportedLocale.languageCode == locale.languageCode) {
          return true;
        }
      }
    }
    return false;
  }
}
