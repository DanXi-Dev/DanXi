/*
 *     Copyright (C) 2021  DanXi-Dev
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:math';

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/dashboard_card.dart';
import 'package:dan_xi/page/opentreehole/hole_editor.dart';
import 'package:dan_xi/page/subpage_settings.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/app/announcement_repository.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Store some important constants, like app id, default color styles, etc.
class Constant {
  /// The number of posts on each pages returned from the server of FDUHole.
  static const POST_COUNT_PER_PAGE = 10;

  static const SUPPORT_QQ_GROUP = "941342818";

  static const SPECIAL_DIVISION_FOR_CURRICULUM = "评教";

  static String get DEFAULT_USER_AGENT =>
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.51 Safari/537.36";

  /// The Bmob verification keys.
  static const BMOB_APP_ID = "d651f7399053222e2b4d2575f7ca8ddb";
  static const BMOB_API_KEY = "bd9e3d90d593c053d4832c817b620890";

  static const String APPSTORE_APPID = '1568629997';

  static const String ADMOB_APP_ID_ANDROID =
      "ca-app-pub-4420475240805528~7573357474";
  static const String ADMOB_APP_ID_IOS =
      "ca-app-pub-4420475240805528~1122982272";

  /// One unit id for each Ad placement.
  /// Respectively, Dashboard, TreeHole, Agenda, Settings.
  static const List<String> ADMOB_UNIT_ID_LIST_ANDROID = [
    "ca-app-pub-4420475240805528/9095994576",
    "ca-app-pub-4420475240805528/5760203038",
    "ca-app-pub-4420475240805528/9738976495",
    "ca-app-pub-4420475240805528/4447121366",
  ];
  static const List<String> ADMOB_UNIT_ID_LIST_IOS = [
    "ca-app-pub-4420475240805528/6845054570",
    "ca-app-pub-4420475240805528/6065507131",
    "ca-app-pub-4420475240805528/6308694497",
    "ca-app-pub-4420475240805528/4752425464",
  ];

  /// A link to the "forget password" page of FDUHole.
  static const String OPEN_TREEHOLE_FORGOT_PASSWORD_URL =
      "https://www.fduhole.com/#/forgetpassword";

  static const String KEY_MANUALLY_ADDED_COURSE = "new_courses";

  /// The default start date of a semester.
  // ignore: non_constant_identifier_names
  static final DEFAULT_SEMESTER_START_DATE = DateTime(2022, 2, 21);

  static EventBus eventBus = EventBus(sync: true);
  static const String UIS_URL = "https://uis.fudan.edu.cn/authserver/login";
  static const String UIS_HOST = "uis.fudan.edu.cn";

  static List<String> fduHoleTips = [];

  /// Load in the tips to be shown in the [BBSEditorWidget].
  static Future<List<String>> _loadTips() async {
    String tipLines = await rootBundle.loadString("assets/texts/tips.dat");
    return tipLines.split("\n");
  }

  static List<String> _stopWords = [];

  /// Load in the stop words to be shown in the [BBSEditorWidget].
  static Future<List<String>> _loadStopWords() async {
    String wordLines =
        await rootBundle.loadString("assets/texts/stop_words.dat");
    return wordLines.split("\n");
  }

  /// Get stop word list from [_loadStopWords].
  ///
  /// If failed to get, return an empty string.
  static Future<List<String>> get stopWords async {
    List<String?>? list;

    // Try to fetch a stop word list online
    try {
      list = AnnouncementRepository.getInstance().getStopWords();
    } catch (_) {}
    if (list != null) {
      List<String> filterList = list
          .filter((e) => e != null && e.trim().isNotEmpty)
          .map((e) => e!)
          .toList();
      if (filterList.isNotEmpty) {
        return filterList;
      }
    }

    // Fall back to local copy
    if (_stopWords.isEmpty) _stopWords = await _loadStopWords();
    return _stopWords;
  }

  /// Get a random tip from [_loadTips].
  ///
  /// If failed to get, return an empty string.
  static Future<String> get randomFDUHoleTip async {
    if (fduHoleTips.isEmpty) fduHoleTips = await _loadTips();

    if (fduHoleTips.isEmpty) {
      return '';
    } else {
      return fduHoleTips[Random().nextInt(fduHoleTips.length)];
    }
  }

  /// Get i18n names of all features.
  ///
  /// For any feature newly added, its representation name should be added here.
  static Map<String, String> getFeatureName(BuildContext context) => {
        'welcome_feature': S.of(context).welcome_feature,
        'next_course_feature': S.of(context).today_course,
        'divider': S.of(context).divider,
        'ecard_balance_feature': S.of(context).ecard_balance,
        'dining_hall_crowdedness_feature':
            S.of(context).dining_hall_crowdedness,
        'fudan_library_crowdedness_feature':
            S.of(context).fudan_library_crowdedness,
        'aao_notice_feature': S.of(context).fudan_aao_notices,
        'empty_classroom_feature': S.of(context).empty_classrooms,
        'fudan_daily_feature': S.of(context).fudan_daily,
        'new_card': S.of(context).add_new_card,
        'qr_feature': S.of(context).fudan_qr_code,
        'pe_feature': S.of(context).pe_exercises,
        'bus_feature': S.of(context).bus_query,
        'dorm_electricity_feature': S.of(context).dorm_electricity,
      };

  /// A default dashboard card list to be shown on the initial startup.
  ///
  /// It will be overwritten by data stored with key [SettingsProvider.KEY_DASHBOARD_WIDGETS]
  static List<DashboardCard> defaultDashboardCardList = [
    DashboardCard("new_card", null, null, true),
    DashboardCard("welcome_feature", null, null, true),
    DashboardCard("next_course_feature", null, null, true),
    DashboardCard("divider", null, null, true),
    DashboardCard("ecard_balance_feature", null, null, true),
    DashboardCard("dining_hall_crowdedness_feature", null, null, true),
    DashboardCard("fudan_library_crowdedness_feature", null, null, true),
    DashboardCard("aao_notice_feature", null, null, true),
    DashboardCard("empty_classroom_feature", null, null, true),
    DashboardCard("dorm_electricity_feature", null, null, true),
    DashboardCard("bus_feature", null, null, true),
    DashboardCard("pe_feature", null, null, true),
    DashboardCard("new_card", null, null, true),
    DashboardCard("fudan_daily_feature", null, null, true),
    DashboardCard("new_card", null, null, true),
    DashboardCard("qr_feature", null, null, true),
  ];

  /// Information about developers.
  ///
  /// The field "description" is not used at the moment.
  static List<Developer> getDevelopers(BuildContext context) => [
        Developer("w568w", "assets/graphics/w568w.jpeg",
            "https://github.com/w568w", S.of(context).w568w_description),
        Developer(
            "singularity-s0",
            "assets/graphics/kavinzhao.jpeg",
            "https://github.com/singularity-s0",
            S.of(context).singularity_s0_description),
        Developer("KYLN24", "assets/graphics/kyln24.jpeg",
            "https://github.com/KYLN24", S.of(context).KYLN24_description),
        Developer("hasbai", "assets/graphics/hasbai.jpeg",
            "https://github.com/hasbai", S.of(context).hasbai_description),
        Developer("Dest1n1", "assets/graphics/Dest1n1.jpg",
            "https://github.com/dest1n1s", S.of(context).Dest1n1_description),
        Developer(
            "Frankstein73",
            "assets/graphics/Frankstein73.jpg",
            "https://github.com/Frankstein73",
            S.of(context).Frankstein73_description),
        Developer("Ivan Fei", "assets/graphics/ivanfei.jpg",
            "https://github.com/ivanfei-1", S.of(context).ivanfei_description),
        Developer("Boreas618", "assets/graphics/Boreas618.jpg",
        "https://github.com/Sunyi618", S.of(context).boreas618_description),
      ];

  /// Add a Chinese symbol(￥) at the end of [num].
  ///
  /// If [num] is empty, return an empty string.
  static String yuanSymbol(String? num) {
    if (num == null || num.trim().isEmpty) return "";
    return '\u00A5$num';
  }

  /// Get the link to update the application.
  static String updateUrl() {
    // Don't use GitHub URL, since access is not guaranteed
    if (PlatformX.isIOS) {
      return "https://apps.apple.com/app/id$APPSTORE_APPID";
    }
    return "https://danxi.fduhole.com";
  }

  /// The light theme used by Material widgets in the app.
  ///
  /// It returns nearly default theme on Material environment, but do some special
  /// configurations on Cupertino environment used by iOS.
  ///
  /// Also see:
  /// * [darkTheme]
  static ThemeData lightTheme(bool isCupertino, MaterialColor color) {
    if (isCupertino) {
      return ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light().copyWith(
            tertiary: const Color(0xFF007AFF),
            secondary: const Color(0xFF007AFF),
            primary: const Color(0xFF007AFF)),
        toggleableActiveColor: const Color(0xFF007AFF),
        indicatorColor: const Color(0xFF007AFF),
        canvasColor: const Color.fromRGBO(242, 242, 247, 1),
        backgroundColor: const Color.fromRGBO(242, 242, 247, 1),
        scaffoldBackgroundColor: const Color.fromRGBO(242, 242, 247, 1),
        cardTheme: CardTheme(
          margin: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          color: ThemeData.light().cardColor,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF007AFF)),
        ),
      );
    }
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: color,
      cardTheme: CardTheme(
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        color: ThemeData.light().cardColor,
      ),
    );
  }

  /// See [lightTheme] for more details.
  static ThemeData darkTheme(bool isCupertino, MaterialColor color) {
    if (isCupertino) {
      return ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark().copyWith(
            tertiary: const Color(0xFF007AFF),
            secondary: const Color(0xFF007AFF),
            primary: const Color(0xFF007AFF)),
        indicatorColor: const Color(0xFF007AFF),
        toggleableActiveColor: const Color(0xFF007AFF),
        scaffoldBackgroundColor: Colors.black,
        canvasColor: Colors.black,
        backgroundColor: Colors.black,
        cardTheme: CardTheme(
          margin: const EdgeInsets.fromLTRB(7, 8, 7, 8),
          color: const Color.fromRGBO(28, 28, 30, 1),
          //color: Color.fromRGBO(30, 30, 33, 0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF007AFF)),
        ),
        dialogBackgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
        textTheme: Typography.whiteCupertino,
      );
    }
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: color,
      cardTheme: CardTheme(
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        color: ThemeData.dark().cardColor,
      ),
    );
  }

  /// A list of tag colors used by FDUHole.
  static const List<String> TAG_COLOR_LIST = [
    'red',
    'pink',
    'purple',
    'deep-purple',
    'indigo',
    'blue',
    'light-blue',
    'cyan',
    'teal',
    'green',
    'light-green',
    'lime',
    'yellow',
    'amber',
    'orange',
    'deep-orange',
    'brown',
    'blue-grey',
    'grey'
  ];

  /// Get a random color string from [TAG_COLOR_LIST].
  static String get randomColor =>
      TAG_COLOR_LIST[Random().nextInt(TAG_COLOR_LIST.length)];

  /// Get the corresponding [Color] from a color string.
  static MaterialColor getColorFromString(String? color) {
    switch (color) {
      case 'red':
        return Colors.red;
      case 'pink':
        return Colors.pink;
      case 'purple':
        return Colors.purple;
      case 'deep-purple':
        return Colors.deepPurple;
      case 'indigo':
        return Colors.indigo;
      case 'blue':
        return Colors.blue;
      case 'light-blue':
        return Colors.lightBlue;
      case 'cyan':
        return Colors.cyan;
      case 'teal':
        return Colors.teal;
      case 'green':
        return Colors.green;
      case 'light-green':
        return Colors.lightGreen;
      case 'lime':
        return Colors.lime;
      case 'yellow':
        return Colors.yellow;
      case 'amber':
        return Colors.amber;
      case 'orange':
        return Colors.orange;
      case 'deep-orange':
        return Colors.deepOrange;
      case 'brown':
        return Colors.brown;
      case 'blue-grey':
        return Colors.blueGrey;
      case 'grey':
        return Colors.grey;
    }
    return Colors.red;
  }

  /// A list of Fudan campus.
  ///
  /// It is a copy of [Campus.values] except [Campus.NONE].
  static const CAMPUS_VALUES = [
    Campus.HANDAN_CAMPUS,
    Campus.FENGLIN_CAMPUS,
    Campus.JIANGWAN_CAMPUS,
    Campus.ZHANGJIANG_CAMPUS
  ];

  ///A list of provided languages
  ///
  /// It is a copy of [Language.values] except [Language.NONE].
  static const LANGUAGE_VALUES = [
    Language.SIMPLE_CHINESE,
    Language.ENGLISH,
    Language.JAPANESE
  ];

  /// A default configuration JSON string for setting special days to celebrate
  /// in lunar calendar.
  ///
  /// It is only used as a fallback when [AnnouncementRepository] cannot obtain the config from
  /// server.
  static const String SPECIAL_DAYS = '''
  [
    {
        "type": 1,
        "date": "除夕",
        "celebrationWords": [
            "万物迎春送残腊，一年结局在今宵。🎇",
            "鼓角梅花添一部，五更欢笑拜新年。🎇",
            "冬尽今宵促，年开明日长。🎇",
            "春风来不远，只在屋东头。"
        ]
    },
    {
        "type": 1,
        "date": "春节",
        "celebrationWords": [
            "爆竹声中一岁除，春风送暖入屠苏。🎆",
            "不须迎向东郊去，春在千门万户中。🎆",
            "松竹含新秋，轩窗有余清。"
        ]
    }
  ]
  ''';

  static const WeekDays = ["周一","周二","周三","周四","周五","周六","周日"];
}

/// A list of Fudan campus.
enum Campus {
  HANDAN_CAMPUS,
  FENGLIN_CAMPUS,
  JIANGWAN_CAMPUS,
  ZHANGJIANG_CAMPUS,
  NONE
}

enum Language { SIMPLE_CHINESE, ENGLISH, JAPANESE, NONE }

extension CampusEx on Campus? {
  static const _CAMPUS_NAME = ["邯郸", "枫林", "江湾", "张江"];

  /// Find the corresponding [Campus] from its Chinese name in [_CAMPUS_NAME].
  static Campus fromChineseName(String? name) {
    if (name != null) {
      for (int i = 0; i < _CAMPUS_NAME.length; i++) {
        if (name.contains(_CAMPUS_NAME[i])) {
          return Constant.CAMPUS_VALUES[i];
        }
      }
    }
    return Campus.NONE;
  }

  /// Get the teaching buildings of this campus.
  List<String>? getTeachingBuildings() {
    switch (this) {
      case Campus.HANDAN_CAMPUS:
        return ['HGX', 'H2', 'H3', 'H4', 'H5', 'H6'];
      case Campus.FENGLIN_CAMPUS:
        return ['F1', 'F2'];
      case Campus.JIANGWAN_CAMPUS:
        return ['JA', 'JB'];
      case Campus.ZHANGJIANG_CAMPUS:
        return ['Z2'];
      case Campus.NONE:
      case null:
      default:
        return ['?'];
    }
  }

  /// Get the i18n name of this campus for display.
  String displayTitle(BuildContext? context) {
    switch (this) {
      case Campus.HANDAN_CAMPUS:
        return S.of(context!).handan_campus;
      case Campus.FENGLIN_CAMPUS:
        return S.of(context!).fenglin_campus;
      case Campus.JIANGWAN_CAMPUS:
        return S.of(context!).jiangwan_campus;
      case Campus.ZHANGJIANG_CAMPUS:
        return S.of(context!).zhangjiang_campus;
      // Select area when it's none
      case Campus.NONE:
        return S.of(context!).choose_area;
      case null:
        return "?";
    }
  }
}

extension LanguageEx on Language? {
  static const _LANGUAGE = ["简体中文", "English", "日本語"];

  /// Find the corresponding [Language] from its Chinese name in [_LANGUAGE].
  static Language fromChineseName(String name) {
    for (int i = 0; i < _LANGUAGE.length; i++) {
      if (name.contains(_LANGUAGE[i])) {
        return Constant.LANGUAGE_VALUES[i];
      }
    }
    return Language.NONE;
  }

  /// Get the i18n name of this language for display.
  String displayTitle(BuildContext? context) {
    switch (this) {
      case Language.SIMPLE_CHINESE:
        return S.of(context!).simplified_chinese_languae;
      case Language.ENGLISH:
        return S.of(context!).english_languae;
      case Language.JAPANESE:
        return S.of(context!).japanese_languae;
      case Language.NONE:
        return "?";
      case null:
        return "?";
    }
  }
}

/// Define a set of possible connection status.
enum ConnectionStatus { NONE, CONNECTING, DONE, FAILED, FATAL_ERROR }

