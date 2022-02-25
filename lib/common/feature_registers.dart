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
import 'package:dan_xi/provider/state_provider.dart';

/// A global register table of [Feature], which declares its compatible user groups here.
Map<String, List<UserGroup>> _kRegister = {};

void registerFeature(Feature feature,
    {List<UserGroup> groups = const [
      UserGroup.FUDAN_UNDERGRADUATE_STUDENT,
      UserGroup.FUDAN_POSTGRADUATE_STUDENT,
      UserGroup.FUDAN_STAFF
    ]}) {
  _kRegister[feature.runtimeType.toString()] = groups;
}

/// Check whether the [group] can use [feature].
bool checkFeature(Feature feature, UserGroup group) {
  if (_kRegister.containsKey(feature.runtimeType.toString())) {
    return _kRegister[feature.runtimeType.toString()]!.contains(group);
  } else {
    return false;
  }
}

/// Check whether [info] is in the [groups].
///
/// If [info] not provided, use global [StateProvider.personInfo] instead.
bool checkGroup(List<UserGroup> groups, [PersonInfo? info]) =>
    groups.contains((info ?? StateProvider.personInfo.value)?.group);
