/*
 *     Copyright (C) 2021  w568w
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

import 'package:shared_preferences/shared_preferences.dart';

class PersonInfo {
  String id, password, name;

  PersonInfo(this.id, this.password, this.name);

  PersonInfo.createNewInfo(this.id, this.password) {
    name = "";
  }

  static bool verifySharedPreferences(SharedPreferences preferences) {
    return preferences.containsKey("id") &&
        preferences.containsKey("password") &&
        preferences.containsKey("name") &&
        preferences.getString("id") != null &&
        preferences.getString("password") != null &&
        preferences.getString("name") != null;
  }

  factory PersonInfo.fromSharedPreferences(SharedPreferences preferences) {
    return PersonInfo(preferences.getString("id"),
        preferences.getString("password"), preferences.getString("name"));
  }

  Future<void> saveAsSharedPreferences(SharedPreferences preferences) async {
    await preferences.setString("id", id);
    await preferences.setString("password", password);
    await preferences.setString("name", name);
  }
}
