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
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Store some important constants, like app id, default color styles, etc.
class Constant {
  /// The number of posts on each pages returned from the server of FDUHole.
  static const POST_COUNT_PER_PAGE = 10;

  static const SPECIAL_DIVISION_FOR_CURRICULUM = "评教";

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

  /// The default start date of a semester.
  // ignore: non_constant_identifier_names
  static final DEFAULT_SEMESTER_START_DATE = DateTime(2022, 2, 21);

  static EventBus eventBus = EventBus(sync: true);
  static const String UIS_URL = "https://uis.fudan.edu.cn/authserver/login";
  static const String UIS_HOST = "uis.fudan.edu.cn";

  static List<String> fduHoleTips = [];

  /// Load in the tips to be shown in the [BBSEditorWidget].
  static Future<List<String>> _loadTips() async {
    String tipsJson = await rootBundle.loadString("assets/texts/tips.dat");
    return tipsJson.split("\n");
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
      ];

  /// Add a Chinese symbol(￥) at the end of [num].
  ///
  /// If [num] is empty, return an empty string.
  static String yuanSymbol(String? num) {
    if (num == null || num.trim().isEmpty) return "";
    return '\u00A5' + num;
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
  static ThemeData lightTheme(bool isCupertino) {
    if (isCupertino) {
      return ThemeData(
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light().copyWith(
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
          style: TextButton.styleFrom(primary: const Color(0xFF007AFF)),
        ),
      );
    }
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      cardTheme: CardTheme(
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        color: ThemeData.light().cardColor,
      ),
    );
  }

  /// See [lightTheme] for more details.
  static ThemeData darkTheme(bool isCupertino) {
    if (isCupertino) {
      return ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark().copyWith(
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
          style: TextButton.styleFrom(primary: const Color(0xFF007AFF)),
        ),
        dialogBackgroundColor: const Color.fromRGBO(28, 28, 30, 1.0),
        textTheme: Typography.whiteCupertino,
      );
    }
    return ThemeData(
      brightness: Brightness.dark,
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
  /// It is a copy of [Campus.values] expect [Campus.NONE].
  static const CAMPUS_VALUES = [
    Campus.HANDAN_CAMPUS,
    Campus.FENGLIN_CAMPUS,
    Campus.JIANGWAN_CAMPUS,
    Campus.ZHANGJIANG_CAMPUS
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
}

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
    for (int i = 0; i < _CAMPUS_NAME.length; i++) {
      if (name!.contains(_CAMPUS_NAME[i])) {
        return Constant.CAMPUS_VALUES[i];
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
  String? displayTitle(BuildContext? context) {
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

/// Define a set of possible connection status.
enum ConnectionStatus { NONE, CONNECTING, DONE, FAILED, FATAL_ERROR }

/// Some constants for secure connection.
class SecureConstant {
  static const List<int> PINNED_CERTIFICATE = [
    48,
    130,
    2,
    10,
    2,
    130,
    2,
    1,
    0,
    128,
    18,
    101,
    23,
    54,
    14,
    195,
    219,
    8,
    179,
    208,
    172,
    87,
    13,
    118,
    237,
    205,
    39,
    211,
    76,
    173,
    80,
    131,
    97,
    226,
    170,
    32,
    77,
    9,
    45,
    100,
    9,
    220,
    206,
    137,
    159,
    204,
    61,
    169,
    236,
    246,
    207,
    193,
    220,
    241,
    211,
    177,
    214,
    123,
    55,
    40,
    17,
    43,
    71,
    218,
    57,
    198,
    188,
    58,
    25,
    180,
    95,
    166,
    189,
    125,
    157,
    163,
    99,
    66,
    182,
    118,
    242,
    169,
    59,
    43,
    145,
    248,
    226,
    111,
    208,
    236,
    22,
    32,
    144,
    9,
    62,
    226,
    232,
    116,
    201,
    24,
    180,
    145,
    212,
    98,
    100,
    219,
    127,
    163,
    6,
    241,
    136,
    24,
    106,
    144,
    34,
    60,
    188,
    254,
    19,
    240,
    135,
    20,
    123,
    246,
    228,
    31,
    142,
    212,
    228,
    81,
    198,
    17,
    103,
    70,
    8,
    81,
    203,
    134,
    20,
    84,
    63,
    188,
    51,
    254,
    126,
    108,
    156,
    255,
    22,
    157,
    24,
    189,
    81,
    142,
    53,
    166,
    167,
    102,
    200,
    114,
    103,
    219,
    33,
    102,
    177,
    212,
    155,
    120,
    3,
    192,
    80,
    58,
    232,
    204,
    240,
    220,
    188,
    158,
    76,
    254,
    175,
    5,
    150,
    53,
    31,
    87,
    90,
    183,
    255,
    206,
    249,
    61,
    183,
    44,
    182,
    246,
    84,
    221,
    200,
    231,
    18,
    58,
    77,
    174,
    76,
    138,
    183,
    92,
    154,
    180,
    183,
    32,
    61,
    202,
    127,
    34,
    52,
    174,
    126,
    59,
    104,
    102,
    1,
    68,
    231,
    1,
    78,
    70,
    83,
    155,
    51,
    96,
    247,
    148,
    190,
    83,
    55,
    144,
    115,
    67,
    243,
    50,
    195,
    83,
    239,
    219,
    170,
    254,
    116,
    78,
    105,
    199,
    107,
    140,
    96,
    147,
    222,
    196,
    199,
    12,
    223,
    225,
    50,
    174,
    204,
    147,
    59,
    81,
    120,
    149,
    103,
    139,
    238,
    61,
    86,
    254,
    12,
    208,
    105,
    15,
    27,
    15,
    243,
    37,
    38,
    107,
    51,
    109,
    247,
    110,
    71,
    250,
    115,
    67,
    229,
    126,
    14,
    165,
    102,
    177,
    41,
    124,
    50,
    132,
    99,
    85,
    137,
    196,
    13,
    193,
    147,
    84,
    48,
    25,
    19,
    172,
    211,
    125,
    55,
    167,
    235,
    93,
    58,
    108,
    53,
    92,
    219,
    65,
    215,
    18,
    218,
    169,
    73,
    11,
    223,
    216,
    128,
    138,
    9,
    147,
    98,
    142,
    181,
    102,
    207,
    37,
    136,
    205,
    132,
    184,
    177,
    63,
    164,
    57,
    15,
    217,
    2,
    158,
    235,
    18,
    76,
    149,
    124,
    243,
    107,
    5,
    169,
    94,
    22,
    131,
    204,
    184,
    103,
    226,
    232,
    19,
    157,
    204,
    91,
    130,
    211,
    76,
    179,
    237,
    91,
    255,
    222,
    229,
    115,
    172,
    35,
    59,
    45,
    0,
    191,
    53,
    85,
    116,
    9,
    73,
    216,
    73,
    88,
    26,
    127,
    146,
    54,
    230,
    81,
    146,
    14,
    243,
    38,
    125,
    28,
    77,
    23,
    188,
    201,
    236,
    67,
    38,
    208,
    191,
    65,
    95,
    64,
    169,
    68,
    68,
    244,
    153,
    231,
    87,
    135,
    158,
    80,
    31,
    87,
    84,
    168,
    62,
    253,
    116,
    99,
    47,
    177,
    80,
    101,
    9,
    230,
    88,
    66,
    46,
    67,
    26,
    76,
    180,
    240,
    37,
    71,
    89,
    250,
    4,
    30,
    147,
    212,
    38,
    70,
    74,
    80,
    129,
    178,
    222,
    190,
    120,
    183,
    252,
    103,
    21,
    225,
    201,
    87,
    132,
    30,
    15,
    99,
    214,
    233,
    98,
    186,
    214,
    95,
    85,
    46,
    234,
    92,
    198,
    40,
    8,
    4,
    37,
    57,
    184,
    14,
    43,
    169,
    242,
    76,
    151,
    28,
    7,
    63,
    13,
    82,
    245,
    237,
    239,
    47,
    130,
    15,
    2,
    3,
    1,
    0,
    1
  ];
}
