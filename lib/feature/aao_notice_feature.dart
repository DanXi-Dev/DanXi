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
import 'package:dan_xi/page/dashboard/aao_notices.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/fdu/aao_repository.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/feature_item/feature_progress_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A feature that shows the latest notice on Fudan AAO.
class FudanAAONoticesFeature extends Feature {
  /// Stored notices on the first page of Fudan AAO notice webpage.
  /// So we can pass it to [AAONoticesList] page.
  List<Notice>? _initialData;

  /// The status of the feature.
  ConnectionStatus _status = ConnectionStatus.NONE;

  Future<void> _loadNotices() async {
    _status = ConnectionStatus.CONNECTING;
    _initialData = await FudanAAORepository.getInstance().getNotices(
        FudanAAORepository.TYPE_NOTICE_ANNOUNCEMENT,
        1,
        StateProvider.personInfo.value);
    _status = ConnectionStatus.DONE;
    notifyUpdate();
  }

  @override
  void buildFeature([Map<String, dynamic>? arguments]) {
    // Only load data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_status == ConnectionStatus.NONE) {
      _loadNotices().catchError((error) {
        _status = ConnectionStatus.FAILED;
        notifyUpdate();
      });
    }
  }

  @override
  String get mainTitle => S.of(context!).fudan_aao_notices;

  @override
  String? get subTitle {
    switch (_status) {
      case ConnectionStatus.NONE:
      case ConnectionStatus.CONNECTING:
        return S.of(context!).loading;
      case ConnectionStatus.DONE:
        if (_initialData != null) {
          return _initialData!.isNotEmpty ? _initialData!.first.title : null;
        } else {
          return null;
        }
      case ConnectionStatus.FAILED:
      case ConnectionStatus.FATAL_ERROR:
        return S.of(context!).failed;
    }
  }

  @override
  bool get loadOnTap => false;

  void refreshData() {
    _status = ConnectionStatus.NONE;
    notifyUpdate();
  }

  @override
  Widget get icon => PlatformX.isMaterial(context!)
      ? const Icon(Icons.developer_board)
      : const Icon(CupertinoIcons.info_circle);

  @override
  void onTap() {
    if (_initialData != null) {
      smartNavigatorPush(context!, "/notice/aao/list",
          arguments: {"initialData": _initialData});
    } else {
      refreshData();
    }
  }

  @override
  Widget? get trailing {
    if (_status == ConnectionStatus.CONNECTING) {
      return const FeatureProgressIndicator();
    }
    return null;
  }

  @override
  bool get clickable => true;
}
