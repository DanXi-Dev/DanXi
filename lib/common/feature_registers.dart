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
import 'package:dan_xi/page/subpage_dashboard.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:flutter/widgets.dart';

/// A global register table of [Feature]s, which declares their compatible user groups here.
Map<String, List<UserGroup>> _group = {};

/// A global register table of [Feature]s, which declares their creation functions here.
Map<String, Feature Function()> featureFactory = {};

/// A global register table of [Feature]s, which declares their display names here.
Map<String, String Function(BuildContext)> featureDisplayName = {};

/// Register the [feature] with its compatible user [groups].
///
/// The [key] will be used to serialize the feature in settings and
/// [featureFactory] will be used to create the feature.
///
/// By default, only compatible features will be shown in the [HomeSubpage].
/// Others will be hidden without any notice.
///
/// If [groups] not provided, use default groups defined here.
///
/// See also:
/// - [UserGroup]
/// - [Feature]
void registerFeature(String key, Feature Function() featureFactoryFunc,
    String Function(BuildContext) displayNameFunc,
    {List<UserGroup> groups = const [
      UserGroup.FUDAN_UNDERGRADUATE_STUDENT,
      UserGroup.FUDAN_POSTGRADUATE_STUDENT,
      UserGroup.FUDAN_STAFF
    ]}) {
  Feature feature = featureFactoryFunc();
  _group[feature.runtimeType.toString()] = groups;
  featureFactory[key] = featureFactoryFunc;
  featureDisplayName[key] = displayNameFunc;
}

/// Check whether the [group] can use [feature].
bool checkFeature(Feature feature, UserGroup group) =>
    _group.opt(feature.runtimeType.toString(), []).contains(group);

/// Check whether [info] is in the [groups].
///
/// If [info] not provided, use global [StateProvider.personInfo] instead.
bool checkGroup(List<UserGroup> groups, [PersonInfo? info]) =>
    groups.contains((info ?? StateProvider.personInfo.value)?.group);
