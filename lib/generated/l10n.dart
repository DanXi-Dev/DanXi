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

  /// `Ecard balance detail`
  String get ecard_balance_log {
    return Intl.message(
      'Ecard balance detail',
      name: 'ecard_balance_log',
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

  /// `Choose your location`
  String get choose_area {
    return Intl.message(
      'Choose your location',
      name: 'choose_area',
      desc: '',
      args: [],
    );
  }

  /// `It's not time for a meal at the moment!`
  String get out_of_dining_time {
    return Intl.message(
      'It\'s not time for a meal at the moment!',
      name: 'out_of_dining_time',
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

  /// `Load failed, click to retry`
  String get failed {
    return Intl.message(
      'Load failed, click to retry',
      name: 'failed',
      desc: '',
      args: [],
    );
  }

  /// `ERROR`
  String get fatal_error {
    return Intl.message(
      'ERROR',
      name: 'fatal_error',
      desc: '',
      args: [],
    );
  }

  /// `Report failed. Danxi can't get the last report record.\nThis error is most likely due to the fact that it is your first time to use Danxi and you forgot to report yesterday.\nYou need complete the first report via Wechat manually, and Danxi will be able to handle the same situation properly from the next day.`
  String get tick_issue_1 {
    return Intl.message(
      'Report failed. Danxi can\'t get the last report record.\nThis error is most likely due to the fact that it is your first time to use Danxi and you forgot to report yesterday.\nYou need complete the first report via Wechat manually, and Danxi will be able to handle the same situation properly from the next day.',
      name: 'tick_issue_1',
      desc: '',
      args: [],
    );
  }

  /// `I know`
  String get i_see {
    return Intl.message(
      'I know',
      name: 'i_see',
      desc: '',
      args: [],
    );
  }

  /// `Reporting...`
  String get ticking {
    return Intl.message(
      'Reporting...',
      name: 'ticking',
      desc: '',
      args: [],
    );
  }

  /// `Report failed. Check your connection.`
  String get tick_failed {
    return Intl.message(
      'Report failed. Check your connection.',
      name: 'tick_failed',
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

  /// `Not connect to any WiFi`
  String get current_connection_no_wifi {
    return Intl.message(
      'Not connect to any WiFi',
      name: 'current_connection_no_wifi',
      desc: '',
      args: [],
    );
  }

  /// `Login Fudan UIS`
  String get login_uis {
    return Intl.message(
      'Login Fudan UIS',
      name: 'login_uis',
      desc: '',
      args: [],
    );
  }

  /// `UIS ID`
  String get login_uis_uid {
    return Intl.message(
      'UIS ID',
      name: 'login_uis_uid',
      desc: '',
      args: [],
    );
  }

  /// `UIS Password`
  String get login_uis_pwd {
    return Intl.message(
      'UIS Password',
      name: 'login_uis_pwd',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get login {
    return Intl.message(
      'Login',
      name: 'login',
      desc: '',
      args: [],
    );
  }

  /// `Logging in...`
  String get logining {
    return Intl.message(
      'Logging in...',
      name: 'logining',
      desc: '',
      args: [],
    );
  }

  /// `Change account`
  String get change_account {
    return Intl.message(
      'Change account',
      name: 'change_account',
      desc: '',
      args: [],
    );
  }

  /// `Loading ECard Code...\nIt may take more than 5 seconds.`
  String get loading_qr_code {
    return Intl.message(
      'Loading ECard Code...\nIt may take more than 5 seconds.',
      name: 'loading_qr_code',
      desc: '',
      args: [],
    );
  }

  /// `Last 7 days`
  String get last_7_days {
    return Intl.message(
      'Last 7 days',
      name: 'last_7_days',
      desc: '',
      args: [],
    );
  }

  /// `Last 15 days`
  String get last_15_days {
    return Intl.message(
      'Last 15 days',
      name: 'last_15_days',
      desc: '',
      args: [],
    );
  }

  /// `Last 30 days`
  String get last_30_days {
    return Intl.message(
      'Last 30 days',
      name: 'last_30_days',
      desc: '',
      args: [],
    );
  }

  /// `Dashboard`
  String get dashboard {
    return Intl.message(
      'Dashboard',
      name: 'dashboard',
      desc: '',
      args: [],
    );
  }

  /// `FD Forum`
  String get forum {
    return Intl.message(
      'FD Forum',
      name: 'forum',
      desc: '',
      args: [],
    );
  }

  /// `New Post`
  String get new_post {
    return Intl.message(
      'New Post',
      name: 'new_post',
      desc: '',
      args: [],
    );
  }

  /// `Sign in the forum as:`
  String get login_with_uis {
    return Intl.message(
      'Sign in the forum as:',
      name: 'login_with_uis',
      desc: '',
      args: [],
    );
  }

  /// `Reply {name}`
  String reply_to(Object name) {
    return Intl.message(
      'Reply $name',
      name: 'reply_to',
      desc: '',
      args: [name],
    );
  }

  /// `Every dawn is a new sunrise.`
  String get good_morning {
    return Intl.message(
      'Every dawn is a new sunrise.',
      name: 'good_morning',
      desc: '',
      args: [],
    );
  }

  /// `Middy receives a full of light.`
  String get good_noon {
    return Intl.message(
      'Middy receives a full of light.',
      name: 'good_noon',
      desc: '',
      args: [],
    );
  }

  /// `It's when lights show up from the city.`
  String get good_afternoon {
    return Intl.message(
      'It\'s when lights show up from the city.',
      name: 'good_afternoon',
      desc: '',
      args: [],
    );
  }

  /// `So night comes, leaving a frail moonlight.`
  String get good_night {
    return Intl.message(
      'So night comes, leaving a frail moonlight.',
      name: 'good_night',
      desc: '',
      args: [],
    );
  }

  /// `With the night oil burning, I'm with you here.`
  String get late_night {
    return Intl.message(
      'With the night oil burning, I\'m with you here.',
      name: 'late_night',
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