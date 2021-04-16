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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/feature/base_feature.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/scale_transform.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:provider/provider.dart';

class EmptyClassroomFeature extends Feature {
  PersonInfo _info;
  ConnectionStatus _status = ConnectionStatus.NONE;
  String _subTitle;

  @override
  void buildFeature() {
    _info = Provider.of<ValueNotifier<PersonInfo>>(context)?.value;

    // Only load data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_status == ConnectionStatus.NONE) {
      _subTitle = S.of(context).loading;
    }
    _subTitle = "TODO: is a stub";
  }

  @override
  String get mainTitle => S.of(context).empty_classrooms;

  @override
  Widget get icon => PlatformX.isAndroid
      ? const Icon(Icons.room)
      : const Icon(SFSymbols.building_2_fill);

  void refreshData() {
    _status = ConnectionStatus.NONE;
    _subTitle = S.of(context).loading;
    notifyUpdate();
  }

  @override
  void onTap() async {
    Navigator.of(context)
        .pushNamed('/room/detail', arguments: {'personInfo': _info});
  }

  @override
  Widget get trailing {
    if (_status == ConnectionStatus.CONNECTING) {
      return ScaleTransform(
        scale: 0.5,
        child: CircularProgressIndicator(),
      );
    }
    return null;
  }

  @override
  bool get clickable => true;
}
