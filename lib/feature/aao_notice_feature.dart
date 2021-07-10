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
import 'package:dan_xi/master_detail/master_detail_view.dart';
import 'package:dan_xi/repository/fudan_aao_repository.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/scale_transform.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:dan_xi/public_extension_methods.dart';

class FudanAAONoticesFeature extends Feature {
  List<Notice> _initialData;
  ConnectionStatus _status = ConnectionStatus.NONE;

  Future<void> _loadNotices() async {
    _status = ConnectionStatus.CONNECTING;
    _initialData = await FudanAAORepository.getInstance().getNotices(
        FudanAAORepository.TYPE_NOTICE_ANNOUNCEMENT, 1, context.personInfo);
    _status = ConnectionStatus.DONE;
    notifyUpdate();
  }

  @override
  void buildFeature([Map<String, dynamic> arguments]) {
    // Only load data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_status == ConnectionStatus.NONE) {
      _loadNotices().catchError((e) {
        _status = ConnectionStatus.FAILED;
        notifyUpdate();
      });
    }
  }

  @override
  String get mainTitle => S.of(context).fudan_aao_notices;

  @override
  String get subTitle {
    return '关于2020级试验班学生专业分流工作安排的通知';
  }

  void refreshData() {
    _status = ConnectionStatus.NONE;
    notifyUpdate();
  }

  @override
  Widget get icon => PlatformX.isAndroid
      ? Icon(Icons.developer_board)
      : Icon(SFSymbols.info_circle);

  @override
  void onTap() {
    if (_initialData != null) {
      smartNavigatorPush(context, "/notice/aao/list", arguments: {
        "initialData": _initialData,
        "personInfo": context.personInfo
      });
    } else {
      refreshData();
    }
  }

  @override
  Widget get trailing {
    if (_status == ConnectionStatus.CONNECTING) {
      return ScaleTransform(
        scale: PlatformX.isMaterial(context) ? 0.5 : 1.0,
        child: PlatformCircularProgressIndicator(),
      );
    }
    return null;
  }

  @override
  bool get clickable => true;
}
