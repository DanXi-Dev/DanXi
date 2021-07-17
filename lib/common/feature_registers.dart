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

import 'package:dan_xi/feature/base_feature.dart';
import 'package:dan_xi/model/person.dart';
import 'package:flutter/cupertino.dart';
import 'package:dan_xi/public_extension_methods.dart';

/// A static register table of [Feature], declaring its compatibility of user group.
Map<String, List<UserGroup>> _kRegister = {};

void registerFeature(Feature feature,
    {List<UserGroup> groups = const [
      UserGroup.FUDAN_STUDENT,
      UserGroup.FUDAN_STAFF
    ]}) {
  _kRegister[feature.runtimeType.toString()] = groups;
}

bool checkFeature(Feature feature, UserGroup group) {
  if (_kRegister.containsKey(feature.runtimeType.toString())) {
    return _kRegister[feature.runtimeType.toString()].contains(group);
  } else {
    return false;
  }
}

bool checkGroup(List<UserGroup> groups, PersonInfo info) =>
    groups != null && info != null && groups.contains(info.group);

bool checkGroupByContext(List<UserGroup> groups, BuildContext context) =>
    checkGroup(groups, context.personInfo);
