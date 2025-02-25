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

import 'dart:io' show Platform;
import 'dart:math';

import 'package:dan_xi/common/feature_registers.dart';
import 'package:dan_xi/common/pubspec.yaml.g.dart';
import 'package:dan_xi/feature/feature_map.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/dashboard_card.dart';
import 'package:dan_xi/page/dashboard/dashboard_reorder.dart';
import 'package:dan_xi/page/forum/hole_editor.dart';
import 'package:dan_xi/page/subpage_settings.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/app/announcement_repository.dart';
import 'package:dan_xi/util/flutter_app.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Store some important constants, such as app id, default color styles, etc.
class Constant {
  /// The number of posts on each pages returned from the server of Forum.
  static const POST_COUNT_PER_PAGE = 10;

  /// The number of serach results on each pages returned from the server of Danke.
  static const SEARCH_COUNT_PER_PAGE = 10;

  static const SUPPORT_QQ_GROUP = "941342818";

  /// The division name of the curriculum page. We use this to determine whether
  /// we should show the curriculum page (instead of a normal forum division).
  ///
  /// See also:
  ///
  /// * [ListDelegate], which determines the page content per division.
  /// * [PostsType], which can represent a special division.
  /// * [OTDivision], whose name is what we compare with.
  static const SPECIAL_DIVISION_FOR_CURRICULUM = "评教";

  /// The default user agent used by the app.
  ///
  /// Note that this is not the same as the user agent used by the WebView, or the
  /// forum's [Dio]. Those two are set by WebView and [ForumRepository].
  static const String DEFAULT_USER_AGENT =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.51 Safari/537.36";

  static const String APPSTORE_APPID = '1568629997';

  /// A link to the "forget password" page of Forum.
  static const String FORUM_FORGOT_PASSWORD_URL =
      "https://auth.fduhole.com/register?type=forget_password";

  static const String FORUM_REGISTER_URL = "https://auth.fduhole.com/register";

  /// The default start date of a semester.
  static final DEFAULT_SEMESTER_START_DATE = DateTime(2023, 2, 20);

  /// A global queue to send events across the widget tree.
  static EventBus eventBus = EventBus(sync: true);
  static const String UIS_URL = "https://uis.fudan.edu.cn/authserver/login";
  static const String UIS_HOST = "uis.fudan.edu.cn";

  /// The default URLs of [ForumRepository] and [CurriculumBoardHoleRepository].
  ///
  static const String FORUM_BASE_URL_LEGACY = "https://www.fduhole.com/api";
  static const String FORUM_BASE_URL = "https://forum.fduhole.com/api";
  static const String AUTH_BASE_URL = "https://auth.fduhole.com/api";
  static const String IMAGE_BASE_URL = "https://image.fduhole.com";
  static const String DANKE_BASE_URL = "https://danke.fduhole.com/api";

  /// An link to the FAQ page of Danxi.
  static const String FAQ_URL =
      "https://danxi-dev.feishu.cn/wiki/wikcnrPPGDCiTODBYRkdwLlHH65";

  static const LINKIFY_THEME =
      TextStyle(color: Colors.blue, decoration: TextDecoration.none);

  /// Client version descriptor.
  ///
  /// It is used to identify the client in the HTTP request header.
  /// Currently, it is used in the [ForumRepository] to tell the server
  /// about the client version.
  static String get version {
    if (PlatformX.isWeb) {
      // web does not support [Platform] API
      return "Danta/${FlutterApp.versionName}b${Pubspec.version.build.single} (Web)";
    } else {
      return "Danta/${FlutterApp.versionName}b${Pubspec.version.build.single} (${Platform.operatingSystem}; ${Platform.operatingSystemVersion})";
    }
  }

  /// The tips to be shown as hints in the [BBSEditorWidget].
  static List<String> forumTips = [];

  /// Load in the tips in the [BBSEditorWidget].
  static Future<List<String>> _loadTips() async {
    String tipLines = await rootBundle.loadString("assets/texts/tips.dat");
    return tipLines.split("\n");
  }

  /// The stop words to be determined in the [BBSEditorWidget].
  ///
  /// Stop words are used to warn the user when he/she is about to post
  /// something that is not encouraged by the community.
  static List<String> _stopWords = [];

  /// The care words to be determined in the [BBSEditorWidget] and [OTSearchPage].
  ///
  /// Care words are used to encourage some depressed and show some care from the community
  static List<String> _careWords = [];

  /// Load in the stop words in the [BBSEditorWidget].
  static Future<List<String>> _loadStopWords() async {
    String wordLines =
        await rootBundle.loadString("assets/texts/stop_words.dat");
    return wordLines.split("\n");
  }

  static Future<List<String>> _loadCareWords() async {
    String wordLines =
        await rootBundle.loadString("assets/texts/care_words.dat");
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

  /// Get care words list from
  ///
  /// If failed to get, return an empty string
  static Future<List<String>> get careWords async {
    List<String?>? list;

    try {
      list = AnnouncementRepository.getInstance().getCareWords();
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

    if (_careWords.isEmpty) _careWords = await _loadCareWords();
    return _careWords;
  }

  /// Get a random tip from [_loadTips].
  ///
  /// If failed to get, return an empty string.
  static Future<String> get randomForumTip async {
    if (forumTips.isEmpty) forumTips = await _loadTips();

    if (forumTips.isEmpty) {
      return '';
    } else {
      return forumTips[Random().nextInt(forumTips.length)];
    }
  }

  /// The keys of special cards that are not features, but can be added to the dashboard.
  ///
  /// See also:
  /// - [DashboardCard]
  /// - [registerFeature]

  /// A divider.
  static const FEATURE_DIVIDER = "divider";

  /// Not a displayable feature, but indicates the start of a new card.
  /// i.e. the content below this feature will be shown in a new card.
  static const FEATURE_NEW_CARD = "new_card";

  /// A custom card, allowing user to tap to jump to a web location.
  static const FEATURE_CUSTOM_CARD = "custom_card";

  /// Get i18n names of all features (included special cards, e.g. "divider" or "new_card")
  /// by their representation names.
  /// This is used to display the name of a feature in the settings page.
  ///
  /// See also:
  /// - [DashboardReorderPage]
  /// - [FeatureMap]
  static Map<String, String> getFeatureName(BuildContext context) {
    Map<String, String> names =
        featureDisplayName.map((key, value) => MapEntry(key, value(context)));

    names.addAll({
      FEATURE_NEW_CARD: S.of(context).add_new_card,
      FEATURE_DIVIDER: S.of(context).divider,
    });
    return names;
  }

  /// A default dashboard card list to be shown on the initial startup.
  ///
  /// It will be overwritten by data stored with key [SettingsProvider.KEY_DASHBOARD_WIDGETS].
  static List<DashboardCard> defaultDashboardCardList = List.unmodifiable([
    DashboardCard(FEATURE_NEW_CARD, null, null, true),
    DashboardCard("welcome_feature", null, null, true),
    DashboardCard("next_course_feature", null, null, true),
    DashboardCard(FEATURE_DIVIDER, null, null, true),
    DashboardCard("ecard_balance_feature", null, null, true),
    DashboardCard("dining_hall_crowdedness_feature", null, null, true),
    DashboardCard("fudan_library_crowdedness_feature", null, null, true),
    DashboardCard("aao_notice_feature", null, null, true),
    DashboardCard("empty_classroom_feature", null, null, true),
    DashboardCard("dorm_electricity_feature", null, null, true),
    DashboardCard("bus_feature", null, null, true),
    DashboardCard("pe_feature", null, null, true),
    DashboardCard(FEATURE_NEW_CARD, null, null, true),
    DashboardCard("qr_feature", null, null, true),
  ]);

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
        Developer(
            "Boreas618",
            "assets/graphics/Boreas618.jpg",
            "https://github.com/Boreas618",
            S.of(context).boreas618_description),
        Developer(
            "JingYiJun",
            "assets/graphics/JingYiJun.jpg",
            "https://github.com/JingYiJun",
            S.of(context).jingyijun_description),
        Developer("fsy2001", "assets/graphics/fsy2001.jpg",
            "https://github.com/fsy2001", S.of(context).fsy2001_description),
        Developer("koowz", "assets/graphics/koowz.jpg",
            "https://github.com/koowz", S.of(context).koowz_description),
        Developer(
            "HydrogenC",
            "assets/graphics/HydrogenC.jpg",
            "https://github.com/HydrogenC",
            S.of(context).hydrogenc_description),
      ];

  /// Add a Chinese symbol(￥) at the end of [num].
  ///
  /// If [num] is empty, return an empty string.
  static String yuanSymbol(String? num) {
    if (num == null || num.trim().isEmpty) return "";
    return '\u00A5$num';
  }

  /// An Unicode ZERO WIDTH SPACE wrapper.
  ///
  /// We mainly use it to relieve vertical alignment issues.
  /// See https://github.com/flutter/flutter/issues/128019 for details.
  ///
  /// Remove this method and its usage if the issue has been resolved.
  static String withZwb(String? originalStr) {
    if (originalStr == null) return "";
    return '$originalStr\u200b';
  }

  /// Get the link to update the application.
  static String updateUrl() {
    // Don't use GitHub URL, since access is not guaranteed in China.
    if (PlatformX.isIOS) {
      return "https://apps.apple.com/app/id$APPSTORE_APPID";
    }
    if (PlatformX.isAndroid) {
      return "https://static.fduhole.com/danxi-latest.apk";
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
      Color toggleableActiveColor = const Color(0xFF007AFF);
      var toggleableProperty =
          WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return toggleableActiveColor;
        }
        return null;
      });

      return ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light().copyWith(
            tertiary: const Color(0xFF007AFF),
            secondary: const Color(0xFF007AFF),
            primary: const Color(0xFF007AFF),
            surface: const Color.fromRGBO(242, 242, 247, 1)),
        switchTheme: SwitchThemeData(
          thumbColor: toggleableProperty,
          trackColor: toggleableProperty,
        ),
        radioTheme: RadioThemeData(fillColor: toggleableProperty),
        indicatorColor: const Color(0xFF007AFF),
        canvasColor: const Color.fromRGBO(242, 242, 247, 1),
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
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: color),
      cardTheme: CardTheme(
        elevation: 0.5,
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        color: ThemeData.light().cardColor,
      ),
      dividerTheme: const DividerThemeData(thickness: 0.2),
    );
  }

  /// See [lightTheme] for more details.
  static ThemeData darkTheme(bool isCupertino, MaterialColor color) {
    if (isCupertino) {
      Color toggleableActiveColor = const Color(0xFF007AFF);
      var toggleableProperty =
          WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return null;
        }
        if (states.contains(WidgetState.selected)) {
          return toggleableActiveColor;
        }
        return null;
      });
      return ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark().copyWith(
            tertiary: const Color(0xFF007AFF),
            secondary: const Color(0xFF007AFF),
            primary: const Color(0xFF007AFF),
            surface: Colors.black),
        indicatorColor: const Color(0xFF007AFF),
        switchTheme: SwitchThemeData(
          thumbColor: toggleableProperty,
          trackColor: toggleableProperty,
        ),
        radioTheme: RadioThemeData(fillColor: toggleableProperty),
        scaffoldBackgroundColor: Colors.black,
        canvasColor: Colors.black,
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
        textTheme: Typography.whiteCupertino, dialogTheme: DialogThemeData(backgroundColor: const Color.fromRGBO(28, 28, 30, 1.0)),
      );
    }
    return ThemeData(
      useMaterial3: true,
      colorScheme:
          ColorScheme.fromSeed(seedColor: color, brightness: Brightness.dark),
      cardTheme: CardTheme(
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        color: ThemeData.dark().cardColor,
      ),
      dividerTheme: const DividerThemeData(thickness: 0.2),
    );
  }

  /// A list of tag colors used by Forum.
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

  static const WeekDays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"];
}

enum Language { SIMPLE_CHINESE, ENGLISH, JAPANESE, NONE }

/// A list of Fudan campus.
enum Campus {
  HANDAN_CAMPUS,
  FENGLIN_CAMPUS,
  JIANGWAN_CAMPUS,
  ZHANGJIANG_CAMPUS,
  NONE
}

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
  String displayTitle(BuildContext context) {
    switch (this) {
      case Campus.HANDAN_CAMPUS:
        return S.of(context).handan_campus;
      case Campus.FENGLIN_CAMPUS:
        return S.of(context).fenglin_campus;
      case Campus.JIANGWAN_CAMPUS:
        return S.of(context).jiangwan_campus;
      case Campus.ZHANGJIANG_CAMPUS:
        return S.of(context).zhangjiang_campus;
      // Select area when it's none
      case Campus.NONE:
        return S.of(context).choose_area;
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
