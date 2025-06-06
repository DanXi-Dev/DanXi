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

import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:ui';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/celebration.dart';
import 'package:dan_xi/model/dashboard_card.dart';
import 'package:dan_xi/model/extra.dart';
import 'package:dan_xi/model/forum/jwt.dart';
import 'package:dan_xi/model/forum/tag.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/page/forum/hole_editor.dart';
import 'package:dan_xi/util/io/user_agent_interceptor.dart';
import 'package:dan_xi/util/shared_preferences.dart';
import 'package:flutter/material.dart';

/// A class to manage [SharedPreferences] Settings
///
/// Code Integrity Note:
/// Avoid returning [null] in [SettingsProvider]. Return the default value instead.
/// Only return [null] when there is no default value.
class SettingsProvider with ChangeNotifier {
  XSharedPreferences? preferences;
  static final _instance = SettingsProvider._();
  static const String KEY_PREFERRED_CAMPUS = "campus";

  //static const String KEY_AUTOTICK_LAST_CANCEL_DATE =
  //    "autotick_last_cancel_date";
  //static const String KEY_PREFERRED_THEME = "theme";
  static const String KEY_FORUM_TOKEN = "fduhole_token_v3";
  static const String KEY_FORUM_SORTORDER = "fduhole_sortorder";
  static const String KEY_EMPTY_CLASSROOM_LAST_BUILDING_CHOICE =
      "ec_last_choice";
  static const String KEY_FORUM_FOLDBEHAVIOR = "fduhole_foldbehavior";
  static const String KEY_DASHBOARD_WIDGETS = "dashboard_widgets_json";
  static const String KEY_THIS_SEMESTER_START_DATE = "this_semester_start_date";
  static const String KEY_SEMESTER_START_DATES = "semester_start_dates";
  static const String KEY_CLEAN_MODE = "clean_mode";
  static const String KEY_DEBUG_MODE = "DEBUG";
  static const String KEY_AD_ENABLED = "ad_enabled";
  static const String KEY_HIDDEN_TAGS = "hidden_tags";
  static const String KEY_HIDE_FORUM = "hide_fduhole";
  static const String KEY_ACCESSIBILITY_COLORING = "accessibility_coloring";
  static const String KEY_CELEBRATION = "celebration";
  static const String KEY_BACKGROUND_IMAGE_PATH = "background";
  static const String KEY_SEARCH_HISTORY = "search_history";
  static const String KEY_TIMETABLE_SEMESTER = "timetable_semester";
  static const String KEY_CUSTOM_USER_AGENT = "custom_user_agent";
  static const String KEY_BANNER_ENABLED = "banner_enabled";
  static const String KEY_PRIMARY_SWATCH = "primary_swatch";
  static const String KEY_PRIMARY_SWATCH_V2 = "primary_swatch_v2";
  static const String KEY_PREFERRED_LANGUAGE = "language";
  static const String KEY_MANUALLY_ADDED_COURSE = "new_courses";
  static const String KEY_TAG_SUGGESTIONS_ENABLE = "tag_suggestions";
  static const String KEY_LIGHT_WATERMARK_COLOR = "light_watermark_color";
  static const String KEY_DARK_WATERMARK_COLOR = "dark_watermark_color";
  static const String KEY_VISIBLE_WATERMARK_MODE = "visible_watermark";
  static const String KEY_HIDDEN_HOLES = "hidden_holes";
  static const String KEY_HIDDEN_NOTIFICATIONS = "hidden_notifications";
  static const String KEY_THEME_TYPE = "theme_type";
  static const String KEY_MARKDOWN_ENABLED = "markdown_rendering_enabled";
  static const String KEY_VISITED_TIMETABLE = "visited_timetable";
  static const String KEY_FORUM_BASE_URL = "fduhole_base_url";
  static const String KEY_AUTH_BASE_URL = "auth_base_url";
  static const String KEY_IMAGE_BASE_URL = "image_base_url";
  static const String KEY_DANKE_BASE_URL = "danke_base_url";
  static const String KEY_PROXY = "proxy";
  static const String KEY_TIMETABLE_LAST_UPDATED = "timetable_last_updated";
  static const String KEY_USE_WEBVPN = "use_webvpn";
  static const String KEY_VIEW_HISTORY = "view_history";

  static const int MAX_VIEW_HISTORY = 250;

  SettingsProvider._();

  /// Get a global instance of [SettingsProvider].
  ///
  /// Never use it anywhere expect [main.dart], where we put it into a [ChangeNotifierProvider] on the top
  /// of widget tree.
  /// If you need to get access to a [SettingsProvider], call [context.read<SettingsProvider>()] instead.
  factory SettingsProvider.getInstance() => _instance;

  DateTime? get timetableLastUpdated {
    if (preferences!.containsKey(KEY_TIMETABLE_LAST_UPDATED)) {
      String? timetableLastUpdated =
          preferences!.getString(KEY_TIMETABLE_LAST_UPDATED);
      if (timetableLastUpdated != null) {
        return DateTime.tryParse(timetableLastUpdated);
      }
    }
    return null;
  }

  set timetableLastUpdated(DateTime? value) {
    if (value != null) {
      preferences!
          .setString(KEY_TIMETABLE_LAST_UPDATED, value.toIso8601String());
    } else {
      preferences!.remove(KEY_TIMETABLE_LAST_UPDATED);
    }
    notifyListeners();
  }

  String? get proxy {
    if (preferences!.containsKey(KEY_PROXY)) {
      return preferences!.getString(KEY_PROXY);
    }
    return null;
  }

  set proxy(String? value) {
    if (value != null) {
      preferences!.setString(KEY_PROXY, value);
    } else {
      preferences!.remove(KEY_PROXY);
    }
    notifyListeners();
  }

  List<String> get searchHistory {
    if (preferences!.containsKey(KEY_SEARCH_HISTORY)) {
      return preferences!.getStringList(KEY_SEARCH_HISTORY) ??
          List<String>.empty();
    }
    return List<String>.empty();
  }

  set searchHistory(List<String>? value) {
    if (value != null) {
      preferences!.setStringList(KEY_SEARCH_HISTORY, value);
    } else if (preferences!.containsKey(KEY_SEARCH_HISTORY)) {
      preferences!.remove(KEY_SEARCH_HISTORY);
    }
    notifyListeners();
  }

  String? get timetableSemester {
    if (preferences!.containsKey(KEY_TIMETABLE_SEMESTER)) {
      return preferences!.getString(KEY_TIMETABLE_SEMESTER);
    }
    return null;
  }

  set timetableSemester(String? value) {
    preferences!.setString(KEY_TIMETABLE_SEMESTER, value!);
    notifyListeners();
  }

  FileImage? get backgroundImage {
    final path = backgroundImagePath;
    if (path == null) return null;
    try {
      final File image = File(path);
      return FileImage(image);
    } catch (ignored) {
      return null;
    }
  }

  /// Set and get _BASE_URL, _BASE_AUTH_URL, _IMAGE_BASE_URL, _DANKE_BASE_URL for debug
  String get forumBaseUrl {
    if (preferences!.containsKey(KEY_FORUM_BASE_URL)) {
      String? url = preferences!.getString(KEY_FORUM_BASE_URL);

      // Override the legacy server address
      if (url == Constant.FORUM_BASE_URL_LEGACY) {
        preferences!.setString(KEY_FORUM_BASE_URL, Constant.FORUM_BASE_URL);
        return Constant.FORUM_BASE_URL;
      }

      if (url != null) {
        return url;
      }
    }
    return Constant.FORUM_BASE_URL;
  }

  set forumBaseUrl(String? value) {
    if (value != null) {
      preferences!.setString(KEY_FORUM_BASE_URL, value);
    } else {
      preferences!.setString(KEY_FORUM_BASE_URL, Constant.FORUM_BASE_URL);
    }
    notifyListeners();
  }

  String get authBaseUrl {
    if (preferences!.containsKey(KEY_AUTH_BASE_URL)) {
      String? authBaseUrl = preferences!.getString(KEY_AUTH_BASE_URL);
      if (authBaseUrl != null) {
        return authBaseUrl;
      }
    }
    return Constant.AUTH_BASE_URL;
  }

  set authBaseUrl(String? value) {
    if (value != null) {
      preferences!.setString(KEY_AUTH_BASE_URL, value);
    } else {
      preferences!.setString(KEY_AUTH_BASE_URL, Constant.AUTH_BASE_URL);
    }
    notifyListeners();
  }

  String get imageBaseUrl {
    if (preferences!.containsKey(KEY_IMAGE_BASE_URL)) {
      String? imageBaseUrl = preferences!.getString(KEY_IMAGE_BASE_URL);
      if (imageBaseUrl != null) {
        return imageBaseUrl;
      }
    }
    return Constant.IMAGE_BASE_URL;
  }

  set imageBaseUrl(String? value) {
    if (value != null) {
      preferences!.setString(KEY_IMAGE_BASE_URL, value);
    } else {
      preferences!.setString(KEY_IMAGE_BASE_URL, Constant.IMAGE_BASE_URL);
    }
    notifyListeners();
  }

  String get dankeBaseUrl {
    if (preferences!.containsKey(KEY_DANKE_BASE_URL)) {
      String? dankeBaseUrl = preferences!.getString(KEY_DANKE_BASE_URL);
      if (dankeBaseUrl != null) {
        return dankeBaseUrl;
      }
    }
    return Constant.DANKE_BASE_URL;
  }

  set dankeBaseUrl(String? value) {
    if (value != null) {
      preferences!.setString(KEY_DANKE_BASE_URL, value);
    } else {
      preferences!.setString(KEY_DANKE_BASE_URL, Constant.DANKE_BASE_URL);
    }
    notifyListeners();
  }

  String? get backgroundImagePath {
    if (preferences!.containsKey(KEY_BACKGROUND_IMAGE_PATH)) {
      return preferences!.getString(KEY_BACKGROUND_IMAGE_PATH)!;
    }
    return null;
  }

  set backgroundImagePath(String? value) {
    if (value != null) {
      preferences!.setString(KEY_BACKGROUND_IMAGE_PATH, value);
    } else {
      preferences!.remove(KEY_BACKGROUND_IMAGE_PATH);
    }
    notifyListeners();
  }

  Future<void> init() async =>
      preferences = await XSharedPreferences.getInstance();

  @Deprecated(
      "SettingsProvider do not need a BuildContext any more. Use SettingsProvider.getInstance() instead")
  factory SettingsProvider.of(_) => SettingsProvider.getInstance();

  bool get useAccessibilityColoring {
    if (preferences!.containsKey(KEY_ACCESSIBILITY_COLORING)) {
      return preferences!.getBool(KEY_ACCESSIBILITY_COLORING)!;
    }
    return false;
  }

  set useAccessibilityColoring(bool value) {
    preferences!.setBool(KEY_ACCESSIBILITY_COLORING, value);
    notifyListeners();
  }

  /// Whether user has opted-in to Ads
  bool get isAdEnabled {
    if (preferences!.containsKey(KEY_AD_ENABLED)) {
      return preferences!.getBool(KEY_AD_ENABLED)!;
    }
    return false;
  }

  set isAdEnabled(bool value) {
    preferences!.setBool(KEY_AD_ENABLED, value);
    notifyListeners();
  }

  bool get hasVisitedTimeTable {
    if (preferences!.containsKey(KEY_VISITED_TIMETABLE)) {
      return preferences!.getBool(KEY_VISITED_TIMETABLE)!;
    }
    return false;
  }

  set hasVisitedTimeTable(bool value) {
    preferences!.setBool(KEY_VISITED_TIMETABLE, value);
    notifyListeners();
  }

  int get lastECBuildingChoiceRepresentation {
    if (preferences!.containsKey(KEY_EMPTY_CLASSROOM_LAST_BUILDING_CHOICE)) {
      return preferences!.getInt(KEY_EMPTY_CLASSROOM_LAST_BUILDING_CHOICE)!;
    }
    return 0;
  }

  set lastECBuildingChoiceRepresentation(int value) {
    preferences!.setInt(KEY_EMPTY_CLASSROOM_LAST_BUILDING_CHOICE, value);
    notifyListeners();
  }

  String? get thisSemesterStartDate {
    if (preferences!.containsKey(KEY_THIS_SEMESTER_START_DATE)) {
      return preferences!.getString(KEY_THIS_SEMESTER_START_DATE)!;
    }
    return null;
  }

  set thisSemesterStartDate(String? value) {
    preferences!.setString(KEY_THIS_SEMESTER_START_DATE, value!);
    notifyListeners();
  }

  TimeTableExtra? get semesterStartDates {
    if (preferences!.containsKey(KEY_SEMESTER_START_DATES)) {
      return TimeTableExtra.fromJson(
          jsonDecode(preferences!.getString(KEY_SEMESTER_START_DATES)!));
    }
    return null;
  }

  set semesterStartDates(TimeTableExtra? value) {
    preferences!.setString(KEY_SEMESTER_START_DATES, jsonEncode(value!));
    notifyListeners();
  }

  /// User's preferences of Dashboard Widgets
  /// This getter always return a non-null value, defaults to default setting
  List<DashboardCard> get dashboardWidgetsSequence {
    if (preferences!.containsKey(KEY_DASHBOARD_WIDGETS)) {
      var rawCardList =
          (json.decode(preferences!.getString(KEY_DASHBOARD_WIDGETS)!) as List)
              .map((i) => DashboardCard.fromJson(i))
              .toList();
      // Merge new features which are added in the new version.
      for (var element in Constant.defaultDashboardCardList) {
        if (!element.isSpecialCard &&
            !rawCardList
                .any((card) => card.internalString == element.internalString)) {
          rawCardList.add(element);
        }
      }
      return rawCardList;
    }
    // [defaultDashboardCardList] is an immutable list, do not
    // return it directly!
    // Make a copy instead.
    return Constant.defaultDashboardCardList.toList();
  }

  set dashboardWidgetsSequence(List<DashboardCard>? value) {
    preferences!.setString(KEY_DASHBOARD_WIDGETS, jsonEncode(value));
    notifyListeners();
  }

  List<Course> get manualAddedCourses {
    if (preferences!.containsKey(KEY_MANUALLY_ADDED_COURSE)) {
      var courseList =
          (json.decode(preferences!.getString(KEY_MANUALLY_ADDED_COURSE)!)
                  as List)
              .map((i) => Course.fromJson(i))
              .toList();

      return courseList;
    }
    return List<Course>.empty();
  }

  set manualAddedCourses(List<Course>? value) {
    if (value != null) {
      preferences!.setString(KEY_MANUALLY_ADDED_COURSE, jsonEncode(value));
    } else if (preferences!.containsKey(KEY_MANUALLY_ADDED_COURSE)) {
      preferences!.remove(KEY_MANUALLY_ADDED_COURSE);
    }
    notifyListeners();
  }

  Campus get campus {
    if (preferences!.containsKey(KEY_PREFERRED_CAMPUS)) {
      String? value = preferences!.getString(KEY_PREFERRED_CAMPUS);
      return Constant.CAMPUS_VALUES
          .firstWhere((element) => element.toString() == value, orElse: () {
        campus = Campus.HANDAN_CAMPUS;
        return Campus.HANDAN_CAMPUS;
      });
    }
    return Campus.HANDAN_CAMPUS;
  }

  set campus(Campus campus) {
    preferences!.setString(KEY_PREFERRED_CAMPUS, campus.toString());
    notifyListeners();
  }

  Language get defaultLanguage {
    Locale locale = PlatformDispatcher.instance.locale;
    if (locale.languageCode == 'en') {
      return Language.ENGLISH;
    } else if (locale.languageCode == 'ja') {
      return Language.JAPANESE;
    } else if (locale.languageCode == 'zh') {
      return Language.SIMPLE_CHINESE;
    } else {
      return Language.NONE;
    }
  }

  Language get language {
    if (preferences!.containsKey(KEY_PREFERRED_LANGUAGE)) {
      String? value = preferences!.getString(KEY_PREFERRED_LANGUAGE);
      return Constant.LANGUAGE_VALUES
          .firstWhere((element) => element.toString() == value, orElse: () {
        return defaultLanguage;
      });
    }
    return defaultLanguage;
  }

  set language(Language language) {
    preferences!.setString(KEY_PREFERRED_LANGUAGE, language.toString());
    notifyListeners();
  }

  /*Push Token
  String? get lastPushToken {
    if (preferences!.containsKey(KEY_LAST_PUSH_TOKEN)) {
      return preferences!.getString(KEY_LAST_PUSH_TOKEN)!;
    }
    return null;
  }

  set lastPushToken(String? value) =>
      preferences!.setString(KEY_LAST_PUSH_TOKEN, value!);*/

  // Token. If token is invalid, return null.
  JWToken? get forumToken {
    if (preferences!.containsKey(KEY_FORUM_TOKEN)) {
      try {
        return JWToken.fromJsonWithVerification(
            jsonDecode(preferences!.getString(KEY_FORUM_TOKEN)!));
      } catch (_) {}
    }
    return null;
  }

  set forumToken(JWToken? value) {
    if (value != null) {
      preferences!.setString(KEY_FORUM_TOKEN, jsonEncode(value));
    } else {
      preferences!.remove(KEY_FORUM_TOKEN);
    }
    notifyListeners();
  }

  void deleteAllForumData() {
    preferences!.remove(KEY_FORUM_TOKEN);
    //preferences!.remove(KEY_LAST_PUSH_TOKEN);
    preferences!.remove(KEY_FORUM_FOLDBEHAVIOR);
    preferences!.remove(KEY_FORUM_SORTORDER);
    preferences!.remove(KEY_HIDE_FORUM);
    preferences!.remove(KEY_HIDDEN_TAGS);
  }

  //Debug Mode
  bool get debugMode {
    if (preferences!.containsKey(KEY_DEBUG_MODE)) {
      return preferences!.getBool(KEY_DEBUG_MODE)!;
    } else {
      return false;
    }
  }

  set debugMode(bool mode) {
    preferences!.setBool(KEY_DEBUG_MODE, mode);
    notifyListeners();
  }

  //Forum Default Sorting Order
  SortOrder? get forumSortOrder {
    if (preferences!.containsKey(KEY_FORUM_SORTORDER)) {
      String? str = preferences!.getString(KEY_FORUM_SORTORDER);
      if (str == SortOrder.LAST_CREATED.getInternalString()) {
        return SortOrder.LAST_CREATED;
      } else if (str == SortOrder.LAST_REPLIED.getInternalString()) {
        return SortOrder.LAST_REPLIED;
      }
    }
    return null;
  }

  set forumSortOrder(SortOrder? value) {
    preferences!.setString(KEY_FORUM_SORTORDER, value.getInternalString()!);
    notifyListeners();
  }

  /// Forum Folded Post Behavior

  /// NOTE: This getter defaults to a FOLD and won't return [null]
  FoldBehavior get forumFoldBehavior {
    if (preferences!.containsKey(KEY_FORUM_FOLDBEHAVIOR)) {
      int? savedPref = preferences!.getInt(KEY_FORUM_FOLDBEHAVIOR);
      return FoldBehavior.values.firstWhere(
        (element) => element.index == savedPref,
        orElse: () => FoldBehavior.FOLD,
      );
    }
    return FoldBehavior.FOLD;
  }

  set forumFoldBehavior(FoldBehavior value) {
    preferences!.setInt(KEY_FORUM_FOLDBEHAVIOR, value.index);
    notifyListeners();
  }

  /// Clean Mode
  bool get cleanMode {
    if (preferences!.containsKey(KEY_CLEAN_MODE)) {
      return preferences!.getBool(KEY_CLEAN_MODE)!;
    } else {
      return false;
    }
  }

  set cleanMode(bool mode) {
    preferences!.setBool(KEY_CLEAN_MODE, mode);
    notifyListeners();
  }

  /// Hidden tags
  List<OTTag>? get hiddenTags {
    try {
      var json = jsonDecode(preferences!.getString(KEY_HIDDEN_TAGS)!);
      if (json is Iterable) {
        return json.map((e) => OTTag.fromJson(e)).toList();
      }
    } catch (ignored) {}
    return null;
  }

  set hiddenTags(List<OTTag>? tags) {
    if (tags == null) return;
    preferences!.setString(KEY_HIDDEN_TAGS, jsonEncode(tags));
    notifyListeners();
  }

  /// Hide Forum
  bool get hideHole {
    if (preferences!.containsKey(KEY_HIDE_FORUM)) {
      return preferences!.getBool(KEY_HIDE_FORUM)!;
    } else {
      return false;
    }
  }

  set hideHole(bool mode) {
    preferences!.setBool(KEY_HIDE_FORUM, mode);
    notifyListeners();
  }

  /// Celebration words
  List<Celebration> get celebrationWords =>
      jsonDecode(preferences!.containsKey(KEY_CELEBRATION)
              ? preferences!.getString(KEY_CELEBRATION)!
              : Constant.SPECIAL_DAYS)
          .map<Celebration>((e) => Celebration.fromJson(e))
          .toList();

  set celebrationWords(List<Celebration> lists) {
    preferences!.setString(KEY_CELEBRATION, jsonEncode(lists));
    notifyListeners();
  }

  /// Custom User Agent
  ///
  /// See:
  /// - [UserAgentInterceptor]
  /// - [BaseRepositoryWithDio]
  String? get customUserAgent {
    if (preferences!.containsKey(KEY_CUSTOM_USER_AGENT)) {
      return preferences!.getString(KEY_CUSTOM_USER_AGENT)!;
    }
    return null;
  }

  set customUserAgent(String? value) {
    if (value != null) {
      preferences!.setString(KEY_CUSTOM_USER_AGENT, value);
    } else {
      preferences!.remove(KEY_CUSTOM_USER_AGENT);
    }
    notifyListeners();
  }

  /// Whether user has opted-in to banners
  bool get isBannerEnabled {
    if (preferences!.containsKey(KEY_BANNER_ENABLED)) {
      return preferences!.getBool(KEY_BANNER_ENABLED)!;
    }
    return true;
  }

  set isBannerEnabled(bool value) {
    preferences!.setBool(KEY_BANNER_ENABLED, value);
    notifyListeners();
  }

  bool get isTagSuggestionEnabled {
    if (preferences!.containsKey(KEY_TAG_SUGGESTIONS_ENABLE)) {
      return preferences!.getBool(KEY_TAG_SUGGESTIONS_ENABLE)!;
    }
    return false;
  }

  set isTagSuggestionEnabled(bool value) {
    preferences!.setBool(KEY_TAG_SUGGESTIONS_ENABLE, value);
    notifyListeners();
  }

  bool tagSuggestionAvailable = false;

  Future<bool> isTagSuggestionAvailable() async {
    return await getTagSuggestions('test') != null;
  }

  /// Primary color used by the app.
  int get primarySwatch {
    if (preferences!.containsKey(KEY_PRIMARY_SWATCH_V2)) {
      int? color = preferences!.getInt(KEY_PRIMARY_SWATCH_V2);
      return Color(color!).value;
    }
    return Colors.blue.value;
  }

  /// Set primary swatch by color name defined in [Constant.TAG_COLOR_LIST].
  void setPrimarySwatch(int value) {
    preferences!.setInt(KEY_PRIMARY_SWATCH_V2, Color(value).value);
    notifyListeners();
  }

  int get lightWatermarkColor {
    if (preferences!.containsKey(KEY_LIGHT_WATERMARK_COLOR)) {
      int? color = preferences!.getInt(KEY_LIGHT_WATERMARK_COLOR);
      return Color(color!).value;
    }
    return 0x03000000;
  }

  set lightWatermarkColor(int value) {
    preferences!.setInt(KEY_LIGHT_WATERMARK_COLOR, Color(value).value);
    notifyListeners();
  }

  int get darkWatermarkColor {
    if (preferences!.containsKey(KEY_DARK_WATERMARK_COLOR)) {
      int? color = preferences!.getInt(KEY_DARK_WATERMARK_COLOR);
      return Color(color!).value;
    }
    return 0x09000000;
  }

  set darkWatermarkColor(int value) {
    preferences!.setInt(KEY_DARK_WATERMARK_COLOR, Color(value).value);
    notifyListeners();
  }

  bool get visibleWatermarkMode {
    if (preferences!.containsKey(KEY_VISIBLE_WATERMARK_MODE)) {
      return preferences!.getBool(KEY_VISIBLE_WATERMARK_MODE)!;
    } else {
      return false;
    }
  }

  set visibleWatermarkMode(bool mode) {
    preferences!.setBool(KEY_VISIBLE_WATERMARK_MODE, mode);
    notifyListeners();
  }

  List<int> get hiddenHoles {
    if (preferences!.containsKey(KEY_HIDDEN_HOLES)) {
      return jsonDecode(preferences!.getString(KEY_HIDDEN_HOLES)!)
          .map<int>((e) => e as int)
          .toList();
    } else {
      return [];
    }
  }

  set hiddenHoles(List<int> list) {
    preferences!.setString(KEY_HIDDEN_HOLES, jsonEncode(list));
    notifyListeners();
  }

  List<String> get hiddenNotifications {
    if (preferences!.containsKey(KEY_HIDDEN_NOTIFICATIONS)) {
      return jsonDecode(preferences!.getString(KEY_HIDDEN_NOTIFICATIONS)!)
          .map<String>((e) => e as String)
          .toList();
    } else {
      return [];
    }
  }

  set hiddenNotifications(List<String> list) {
    preferences!.setString(KEY_HIDDEN_NOTIFICATIONS, jsonEncode(list));
    notifyListeners();
  }

  ThemeType get themeType {
    if (preferences!.containsKey(KEY_THEME_TYPE)) {
      return themeTypeFromInternalString(
              preferences!.getString(KEY_THEME_TYPE)) ??
          ThemeType.SYSTEM;
    } else {
      return ThemeType.SYSTEM;
    }
  }

  set themeType(ThemeType type) {
    preferences!.setString(KEY_THEME_TYPE, type.internalString());
    notifyListeners();
  }

  bool get isMarkdownRenderingEnabled {
    if (preferences!.containsKey(KEY_MARKDOWN_ENABLED)) {
      return preferences!.getBool(KEY_MARKDOWN_ENABLED)!;
    }
    return true;
  }

  set isMarkdownRenderingEnabled(bool value) {
    preferences!.setBool(KEY_MARKDOWN_ENABLED, value);
    notifyListeners();
  }

  bool get useWebvpn {
    if (preferences!.containsKey(KEY_USE_WEBVPN)) {
      return preferences!.getBool(KEY_USE_WEBVPN)!;
    }
    return true;
  }

  set useWebvpn(bool value) {
    preferences!.setBool(KEY_USE_WEBVPN, value);
    notifyListeners();
  }

  List<int> get viewHistory {
    if (preferences!.containsKey(KEY_VIEW_HISTORY)) {
      return preferences!.getIntList(KEY_VIEW_HISTORY)!;
    }
    return [];
  }

  set viewHistory(List<int> value) {
    preferences!.setIntList(KEY_VIEW_HISTORY, value);
    notifyListeners();
  }
}

enum SortOrder { LAST_REPLIED, LAST_CREATED }

extension SortOrderEx on SortOrder? {
  String? displayTitle(BuildContext context) {
    switch (this) {
      case SortOrder.LAST_REPLIED:
        return S.of(context).last_replied;
      case SortOrder.LAST_CREATED:
        return S.of(context).last_created;
      case null:
        return null;
    }
  }

  String? getInternalString() {
    switch (this) {
      case SortOrder.LAST_REPLIED:
        return "time_updated";
      case SortOrder.LAST_CREATED:
        return "time_created";
      case null:
        return null;
    }
  }
}

//Forum Folded Post Behavior
enum FoldBehavior { SHOW, FOLD, HIDE }

extension FoldBehaviorEx on FoldBehavior {
  String? displayTitle(BuildContext context) {
    switch (this) {
      case FoldBehavior.FOLD:
        return S.of(context).fold;
      case FoldBehavior.HIDE:
        return S.of(context).hide;
      case FoldBehavior.SHOW:
        return S.of(context).show;
    }
  }

  String? internalString() {
    switch (this) {
      case FoldBehavior.FOLD:
        return 'fold';
      case FoldBehavior.HIDE:
        return 'hide';
      case FoldBehavior.SHOW:
        return 'show';
    }
  }
}

FoldBehavior foldBehaviorFromInternalString(String? str) {
  switch (str) {
    case 'fold':
      return FoldBehavior.FOLD;
    case 'hide':
      return FoldBehavior.HIDE;
    case 'show':
      return FoldBehavior.SHOW;
    default:
      return FoldBehavior.FOLD;
  }
}

enum OTNotificationTypes { MENTION, SUBSCRIPTION, REPORT }

extension OTNotificationTypesEx on OTNotificationTypes {
  String? displayTitle(BuildContext context) {
    switch (this) {
      case OTNotificationTypes.MENTION:
        return S.of(context).notification_mention;
      case OTNotificationTypes.SUBSCRIPTION:
        return S.of(context).notification_subscription;
      case OTNotificationTypes.REPORT:
        return S.of(context).notification_reported;
    }
  }

  String? displayShortTitle(BuildContext context) {
    switch (this) {
      case OTNotificationTypes.MENTION:
        return S.of(context).notification_mention_s;
      case OTNotificationTypes.SUBSCRIPTION:
        return S.of(context).notification_subscription_s;
      case OTNotificationTypes.REPORT:
        return S.of(context).notification_reported_s;
    }
  }

  String internalString() {
    switch (this) {
      case OTNotificationTypes.MENTION:
        return 'mention';
      case OTNotificationTypes.SUBSCRIPTION:
        return 'favorite'; // keep 'favorite' here for backward support
      case OTNotificationTypes.REPORT:
        return 'report';
    }
  }
}

OTNotificationTypes? notificationTypeFromInternalString(String str) {
  switch (str) {
    case 'mention':
      return OTNotificationTypes.MENTION;
    case 'favorite':
      return OTNotificationTypes.SUBSCRIPTION;
    case 'report':
      return OTNotificationTypes.REPORT;
    default:
      return null;
  }
}

enum ThemeType { LIGHT, DARK, SYSTEM }

extension ThemeTypeEx on ThemeType {
  String? displayTitle(BuildContext context) {
    switch (this) {
      case ThemeType.LIGHT:
        return S.of(context).theme_type_light;
      case ThemeType.DARK:
        return S.of(context).theme_type_dark;
      case ThemeType.SYSTEM:
        return S.of(context).theme_type_system;
    }
  }

  String internalString() {
    switch (this) {
      case ThemeType.LIGHT:
        return 'light';
      case ThemeType.DARK:
        return 'dark';
      case ThemeType.SYSTEM:
        return 'system';
    }
  }

  Brightness getBrightness() {
    switch (this) {
      case ThemeType.LIGHT:
        return Brightness.light;
      case ThemeType.DARK:
        return Brightness.dark;
      case ThemeType.SYSTEM:
        return WidgetsBinding.instance.window.platformBrightness;
    }
  }
}

ThemeType? themeTypeFromInternalString(String? str) {
  switch (str) {
    case 'light':
      return ThemeType.LIGHT;
    case 'dark':
      return ThemeType.DARK;
    case 'system':
      return ThemeType.SYSTEM;
    default:
      return null;
  }
}
