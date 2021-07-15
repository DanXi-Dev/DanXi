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

import 'package:shared_preferences/shared_preferences.dart';

enum UserGroup {
  /// Not logged in
  VISITOR,

  /// Log in as Fudan student
  FUDAN_STUDENT,

  /// Log in as Fudan stuff (Not implemented)
  FUDAN_STUFF,

  /// Log in as SJTU student (Not implemented)
  SJTU_STUDENT
}

Map<UserGroup, Function> kUserGroupDescription = {
  // UserGroup.VISITOR:(BuildContext context)=>S.of(context).
};

class PersonInfo {
  UserGroup group;
  String id, password, name;

  PersonInfo(this.id, this.password, this.name, this.group);

  PersonInfo.createNewInfo(this.id, this.password, this.group) {
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
    return PersonInfo(
        preferences.getString("id"),
        preferences.getString("password"),
        preferences.getString("name"),
        preferences.containsKey("user_group")
            ? UserGroup.values.firstWhere((element) =>
                element.toString() == preferences.getString("user_group"))
            : UserGroup.FUDAN_STUDENT);
  }

  Future<void> saveAsSharedPreferences(SharedPreferences preferences) async {
    await preferences.setString("id", id);
    await preferences.setString("password", password);
    await preferences.setString("name", name);
    await preferences.setString("user_group", group.toString());
  }
}
