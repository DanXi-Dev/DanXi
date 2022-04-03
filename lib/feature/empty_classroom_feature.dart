/*
 *     Copyright (C) 2021 kavinzhao
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
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EmptyClassroomFeature extends Feature {
  @override
  String get mainTitle => S.of(context!).empty_classrooms;

  @override
  String get subTitle => S.of(context!).tap_to_view;

  @override
  Widget get icon => PlatformX.isMaterial(context!)
      ? const Icon(Icons.room)
      : const Icon(CupertinoIcons.building_2_fill);

  @override
  void onTap() async => smartNavigatorPush(context!, '/room/detail');

  @override
  bool get clickable => true;

  @override
  bool get loadOnTap => false;
}
