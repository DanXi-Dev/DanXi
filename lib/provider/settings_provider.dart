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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/feature/base_feature.dart';
import 'package:dan_xi/feature/welcome_feature.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/widget/feature_item/feature_list_item.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider {
  SharedPreferences _preferences;

  static const String KEY_PREFERRED_CAMPUS = "campus";
  //static const String KEY_AUTOTICK_LAST_CANCEL_DATE =
  //    "autotick_last_cancel_date";
  //static const String KEY_PREFERRED_THEME = "theme";
  static const String KEY_FDUHOLE_TOKEN = "fduhole_token";
  static const String KEY_FDUHOLE_SORTORDER = "fduhole_sortorder";
  static const String KEY_FDUHOLE_FOLDBEHAVIOR = "fduhole_foldbehavior";
  static const String KEY_DASHBOARD_WIDGETS = "dashboard_widgets";

  SettingsProvider._(this._preferences);

  factory SettingsProvider.of(SharedPreferences preferences) {
    return SettingsProvider._(preferences);
  }

  /// User's preferences of Dashboard Widgets
  /// This getter always return a non-null value, defaults to default setting
  List<String> get dashboardWidgetsSequence {
    if (_preferences.containsKey(KEY_DASHBOARD_WIDGETS)) {
      return _preferences.getStringList(KEY_DASHBOARD_WIDGETS);
    }
    return [
      'n:new_card',
      'n:welcome_feature',
      'n:next_course_feature',
      'n:divider',
      'n:ecard_balance_feature',
      'n:dining_hall_crowdedness_feature',
      'n:aao_notice_feature',
      'n:empty_classroom_feature',
      'n:new_card',
      'n:fudan_daily_feature',
      'n:new_card',
      'n:qr_feature'
    ];
  }

  set dashboardWidgetsSequence(List<String> value) {
    _preferences.setStringList(KEY_DASHBOARD_WIDGETS, value);
  }

  Campus get campus {
    if (_preferences.containsKey(KEY_PREFERRED_CAMPUS)) {
      String value = _preferences.getString(KEY_PREFERRED_CAMPUS);
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
    _preferences.setString(KEY_PREFERRED_CAMPUS, campus.toString());
  }

  //FudanDaily AutoTick
  /*
  String get autoTickCancelDate {
    if (_preferences.containsKey(KEY_AUTOTICK_LAST_CANCEL_DATE)) {
      return _preferences.getString(KEY_AUTOTICK_LAST_CANCEL_DATE);
    }
    return null;
  }

  set autoTickCancelDate(String datetime) {
    _preferences.setString(KEY_AUTOTICK_LAST_CANCEL_DATE, datetime.toString());
  }

  //Theme
  //int: 0 for Material, 1 for Cupertino
  int get theme {
    if (_preferences.containsKey(KEY_PREFERRED_THEME)) {
      return _preferences.getInt(KEY_PREFERRED_THEME);
    }
    return null;
  }

  set theme(int theme) {
    _preferences.setInt(KEY_PREFERRED_THEME, theme);
  }*/

  //Token
  String get fduholeToken {
    if (_preferences.containsKey(KEY_FDUHOLE_TOKEN)) {
      return _preferences.getString(KEY_FDUHOLE_TOKEN);
    }
    return null;
  }

  set fduholeToken(String value) =>
      _preferences.setString(KEY_FDUHOLE_TOKEN, value);

  void deleteSavedFduholeToken() => _preferences.remove(KEY_FDUHOLE_TOKEN);

  //Debug Mode
  bool get debugMode => _preferences.containsKey("DEBUG");

  //FDUHOLE Default Sorting Order
  SortOrder get fduholeSortOrder {
    if (_preferences.containsKey(KEY_FDUHOLE_SORTORDER)) {
      String str = _preferences.getString(KEY_FDUHOLE_SORTORDER);
      if (str == SortOrder.LAST_CREATED.getInternalString())
        return SortOrder.LAST_CREATED;
      else if (str == SortOrder.LAST_REPLIED.getInternalString())
        return SortOrder.LAST_REPLIED;
    }
    return null;
  }

  set fduholeSortOrder(SortOrder value) =>
      _preferences.setString(KEY_FDUHOLE_SORTORDER, value.getInternalString());

  //FDUHOLE Folded Post Behavior

  //NOTE: This getter defaults to a FOLD and won't return [null]
  FoldBehavior get fduholeFoldBehavior {
    if (_preferences.containsKey(KEY_FDUHOLE_FOLDBEHAVIOR)) {
      int savedPref = _preferences.getInt(KEY_FDUHOLE_FOLDBEHAVIOR);
      return FoldBehavior.values.firstWhere(
        (element) => element.index == savedPref,
        orElse: () => FoldBehavior.FOLD,
      );
    }
    return FoldBehavior.FOLD;
  }

  set fduholeFoldBehavior(FoldBehavior value) =>
      _preferences.setInt(KEY_FDUHOLE_FOLDBEHAVIOR, value.index);
}

enum SortOrder { LAST_REPLIED, LAST_CREATED }

extension SortOrderEx on SortOrder {
  String displayTitle(BuildContext context) {
    switch (this) {
      case SortOrder.LAST_REPLIED:
        return S.of(context).last_replied;
        break;
      case SortOrder.LAST_CREATED:
        return S.of(context).last_created;
        break;
    }
    return null;
  }

  String getInternalString() {
    switch (this) {
      case SortOrder.LAST_REPLIED:
        return "last_updated";
        break;
      case SortOrder.LAST_CREATED:
        return "last_created";
        break;
    }
    return null;
  }
}

//FDUHOLE Folded Post Behavior
enum FoldBehavior { SHOW, FOLD, HIDE }

extension FoldBehaviorEx on FoldBehavior {
  String displayTitle(BuildContext context) {
    switch (this) {
      case FoldBehavior.FOLD:
        return S.of(context).fold;
        break;
      case FoldBehavior.HIDE:
        return S.of(context).hide;
        break;
      case FoldBehavior.SHOW:
        return S.of(context).show;
        break;
    }
    return null;
  }
}
