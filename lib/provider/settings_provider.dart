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
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider {
  SharedPreferences _preferences;

  static const String KEY_PREFERRED_CAMPUS = "campus";
  //static const String KEY_AUTOTICK_LAST_CANCEL_DATE =
  //    "autotick_last_cancel_date";
  //static const String KEY_PREFERRED_THEME = "theme";
  static const String KEY_FDUHOLE_TOKEN = "fduhole_token";
  static const String KEY_FDUHOLE_SORTORDER = "fduhole_sortorder";

  SettingsProvider._(this._preferences);

  factory SettingsProvider.of(SharedPreferences preferences) {
    return SettingsProvider._(preferences);
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
}
