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
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/fudan_dorm_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/scale_transform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class DormElectricityFeature extends Feature {
  ElectricityItem? _electricity;

  /// Status of the request.
  ConnectionStatus _status = ConnectionStatus.NONE;

  void _loadData() async {
    _status = ConnectionStatus.CONNECTING;
    try {
      _electricity = await FudanDormRepository.getInstance()
          .loadElectricityInfo(StateProvider.personInfo.value);
      _status = ConnectionStatus.DONE;
    } catch (e) {
      _status = ConnectionStatus.FAILED;
    }
    notifyUpdate();
  }

  @override
  void buildFeature([Map<String, dynamic>? arguments]) {
    // Only load data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_status == ConnectionStatus.NONE) {
      _electricity = null;
      _loadData();
    }
  }

  @override
  String get mainTitle => S.of(context!).dorm_electricity;

  @override
  String get subTitle {
    switch (_status) {
      case ConnectionStatus.NONE:
      case ConnectionStatus.CONNECTING:
        return S.of(context!).loading;
      case ConnectionStatus.DONE:
        return S.of(context!).dorm_electricity_subtitle(
            _electricity!.available, _electricity!.used);
      case ConnectionStatus.FAILED:
      case ConnectionStatus.FATAL_ERROR:
        return S.of(context!).failed;
    }
  }

  @override
  Widget? get trailing {
    if (_status == ConnectionStatus.CONNECTING) {
      return ScaleTransform(
        scale: PlatformX.isMaterial(context!) ? 0.5 : 1.0,
        child: PlatformCircularProgressIndicator(),
      );
    }
    return null;
  }

  @override
  Widget get icon => PlatformX.isMaterial(context!)
      ? const Icon(Icons.bolt)
      : const Icon(CupertinoIcons.bolt);

  void refreshData() {
    _status = ConnectionStatus.NONE;
    notifyUpdate();
  }

  @override
  void onTap() {
    if (_status == ConnectionStatus.DONE) {
      final String body = _electricity!.dormName +
          '\n' +
          S.of(context!).dorm_electricity_subtitle(
              _electricity!.available, _electricity!.used) +
          '\n\n' +
          S.of(context!).last_updated(_electricity!.updateTime.toString());
      Noticing.showModalNotice(context!,
          message: body, title: S.of(context!).dorm_electricity);
    } else {
      refreshData();
    }
  }

  @override
  bool get clickable => true;
}
