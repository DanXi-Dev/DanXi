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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/celebration.dart';
import 'package:dan_xi/model/dashboard_card.dart';
import 'package:dan_xi/model/extra.dart';
import 'package:dan_xi/model/opentreehole/tag.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A class to manage [SharedPreferences] Settings
///
/// Code Integrity Note:
/// Avoid returning [null] in [SettingsProvider]. Return the default value instead.
/// Only return [null] when there is no default value.
class SettingsProvider with ChangeNotifier {
  SharedPreferences? preferences;
  static final _instance = SettingsProvider._();
  static const String KEY_PREFERRED_CAMPUS = "campus";

  //static const String KEY_AUTOTICK_LAST_CANCEL_DATE =
  //    "autotick_last_cancel_date";
  //static const String KEY_PREFERRED_THEME = "theme";
  static const String KEY_FDUHOLE_TOKEN = "fduhole_token_v2";
  static const String KEY_FDUHOLE_SORTORDER = "fduhole_sortorder";
  static const String KEY_EMPTY_CLASSROOM_LAST_BUILDING_CHOICE =
      "ec_last_choice";
  static const String KEY_FDUHOLE_FOLDBEHAVIOR = "fduhole_foldbehavior";
  static const String KEY_DASHBOARD_WIDGETS = "dashboard_widgets_json";
  static const String KEY_THIS_SEMESTER_START_DATE = "this_semester_start_date";
  static const String KEY_SEMESTER_START_DATES = "semester_start_dates";
  static const String KEY_CLEAN_MODE = "clean_mode";
  static const String KEY_DEBUG_MODE = "DEBUG";
  static const String KEY_AD_ENABLED = "ad_enabled";
  static const String KEY_HIDDEN_TAGS = "hidden_tags";
  static const String KEY_HIDDEN_HOLE = "hidden_hole";
  static const String KEY_ACCESSIBILITY_COLORING = "accessibility_coloring";
  static const String KEY_CELEBRATION = "celebration";
  static const String KEY_BACKGROUND_IMAGE_PATH = "background";
  static const String KEY_SEARCH_HISTORY = "search_history";
  static const String KEY_TIMETABLE_SEMESTER = "timetable_semester";

  SettingsProvider._();

  factory SettingsProvider.getInstance() => _instance;

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
      preferences = await SharedPreferences.getInstance();

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
    return Constant.defaultDashboardCardList;
  }

  set dashboardWidgetsSequence(List<DashboardCard>? value) {
    preferences!.setString(KEY_DASHBOARD_WIDGETS, jsonEncode(value));
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
    campus = Campus.HANDAN_CAMPUS;
    return Campus.HANDAN_CAMPUS;
  }

  set campus(Campus campus) {
    preferences!.setString(KEY_PREFERRED_CAMPUS, campus.toString());
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

  //Token
  String? get fduholeToken {
    if (preferences!.containsKey(KEY_FDUHOLE_TOKEN)) {
      return preferences!.getString(KEY_FDUHOLE_TOKEN)!;
    }
    return null;
  }

  set fduholeToken(String? value) {
    if (value != null) {
      preferences!.setString(KEY_FDUHOLE_TOKEN, value);
    } else {
      preferences!.remove(KEY_FDUHOLE_TOKEN);
    }
    notifyListeners();
  }

  void deleteAllFduholeData() {
    preferences!.remove(KEY_FDUHOLE_TOKEN);
    //preferences!.remove(KEY_LAST_PUSH_TOKEN);
    preferences!.remove(KEY_FDUHOLE_FOLDBEHAVIOR);
    preferences!.remove(KEY_FDUHOLE_SORTORDER);
    preferences!.remove(KEY_HIDDEN_HOLE);
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

  //FDUHOLE Default Sorting Order
  SortOrder? get fduholeSortOrder {
    if (preferences!.containsKey(KEY_FDUHOLE_SORTORDER)) {
      String? str = preferences!.getString(KEY_FDUHOLE_SORTORDER);
      if (str == SortOrder.LAST_CREATED.getInternalString()) {
        return SortOrder.LAST_CREATED;
      } else if (str == SortOrder.LAST_REPLIED.getInternalString()) {
        return SortOrder.LAST_REPLIED;
      }
    }
    return null;
  }

  set fduholeSortOrder(SortOrder? value) {
    preferences!.setString(KEY_FDUHOLE_SORTORDER, value.getInternalString()!);
    notifyListeners();
  }

  /// FDUHOLE Folded Post Behavior

  /// NOTE: This getter defaults to a FOLD and won't return [null]
  FoldBehavior get fduholeFoldBehavior {
    if (preferences!.containsKey(KEY_FDUHOLE_FOLDBEHAVIOR)) {
      int? savedPref = preferences!.getInt(KEY_FDUHOLE_FOLDBEHAVIOR);
      return FoldBehavior.values.firstWhere(
        (element) => element.index == savedPref,
        orElse: () => FoldBehavior.FOLD,
      );
    }
    return FoldBehavior.FOLD;
  }

  set fduholeFoldBehavior(FoldBehavior value) {
    preferences!.setInt(KEY_FDUHOLE_FOLDBEHAVIOR, value.index);
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

  /// Hide FDUHole
  bool get hideHole {
    if (preferences!.containsKey(KEY_HIDDEN_HOLE)) {
      return preferences!.getBool(KEY_HIDDEN_HOLE)!;
    } else {
      return false;
    }
  }

  set hideHole(bool mode) {
    preferences!.setBool(KEY_HIDDEN_HOLE, mode);
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
        return "last_updated";
      case SortOrder.LAST_CREATED:
        return "last_created";
      case null:
        return null;
    }
  }
}

//FDUHOLE Folded Post Behavior
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

enum OTNotificationTypes { MENTION, FAVORITE, REPORT }

extension OTNotificationTypesEx on OTNotificationTypes {
  String? displayTitle(BuildContext context) {
    switch (this) {
      case OTNotificationTypes.MENTION:
        return S.of(context).notification_mention;
      case OTNotificationTypes.FAVORITE:
        return S.of(context).notification_favorite;
      case OTNotificationTypes.REPORT:
        return S.of(context).notification_reported;
    }
  }

  String? displayShortTitle(BuildContext context) {
    switch (this) {
      case OTNotificationTypes.MENTION:
        return S.of(context).notification_mention_s;
      case OTNotificationTypes.FAVORITE:
        return S.of(context).notification_favorite_s;
      case OTNotificationTypes.REPORT:
        return S.of(context).notification_reported_s;
    }
  }

  String internalString() {
    switch (this) {
      case OTNotificationTypes.MENTION:
        return 'mention';
      case OTNotificationTypes.FAVORITE:
        return 'favorite';
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
      return OTNotificationTypes.FAVORITE;
    case 'report':
      return OTNotificationTypes.REPORT;
    default:
      return null;
  }
}
