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

import 'dart:async';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/feature/base_feature.dart';
import 'package:dan_xi/feature/fudan_daily_warning_notification.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/provider/notification_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/fdu/zlapp_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/scale_transform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class FudanDailyFeature extends Feature {
  PersonInfo? _info;
  ConnectionStatus _status = ConnectionStatus.NONE;
  bool _hasTicked = true;

  //int _countdownRemainingTime = Constant.FUDAN_DAILY_COUNTDOWN_SECONDS; //Value -2 means stop countdown

  Future<void> _loadTickStatus() async {
    _status = ConnectionStatus.CONNECTING;
    // Get the status of reporting
    await FudanCOVID19Repository.getInstance()
        .hasTick(_info)
        .then((bool ticked) {
      _status = ConnectionStatus.DONE;
      _hasTicked = ticked;
      if (_hasTicked) {
        context!
            .read<NotificationProvider>()
            .removeNotification(FudanDailyWarningNotification());
      } else {
        context!
            .read<NotificationProvider>()
            .addNotification(FudanDailyWarningNotification());
      }
      notifyUpdate();
    });
  }

  @override
  void buildFeature([Map<String, dynamic>? arguments]) {
    _info = StateProvider.personInfo.value;

    // Only load card data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_status == ConnectionStatus.NONE) {
      _status = ConnectionStatus.CONNECTING;
      _loadTickStatus().catchError((error) {
        _status = ConnectionStatus.FAILED;
        notifyUpdate();
      });
    }
  }

  @override
  String get mainTitle => S.of(context!).fudan_daily;

  @override
  String? get subTitle {
    switch (_status) {
      case ConnectionStatus.NONE:
      case ConnectionStatus.CONNECTING:
        return S.of(context!).loading;
      case ConnectionStatus.FAILED:
        return S.of(context!).failed;
      case ConnectionStatus.FATAL_ERROR:
        return S.of(context!).tick_failed;
      case ConnectionStatus.DONE:
        if (_hasTicked) {
          return S.of(context!).fudan_daily_ticked;
        }
        return S.of(context!).fudan_daily_tick_link;
    }
  }

  @override
  Widget? get customSubtitle => _hasTicked
      ? null
      : Text(
          S.of(context!).fudan_daily_tick_link,
          style: const TextStyle(color: Colors.red),
        );

  //@override
  //String get tertiaryTitle => S.of(context).fudan_daily_disabled_notice;

  @override
  Widget get icon => PlatformX.isMaterial(context!)
      ? const Icon(Icons.cloud_upload)
      : const Icon(CupertinoIcons.arrow_up_doc);

  /// Restart the loading process
  void refreshData() {
    _status = ConnectionStatus.NONE;
    notifyUpdate();
  }

  static pushFudanDailyWebPage(BuildContext context) async {
    if (PlatformX.isMobile) {
      // Request Location Permission
      if (await Permission.locationWhenInUse.request() !=
          PermissionStatus.granted) {
        Noticing.showNotice(
            context, S.of(context).location_permission_denied_promot);
        return;
      }
    }
    BrowserUtil.openUrl(
        "https://zlapp.fudan.edu.cn/site/ncov/fudanDaily", context, null, true);
  }

  @override
  void onTap() async {
    switch (_status) {
      case ConnectionStatus.DONE:
        pushFudanDailyWebPage(context!);
        break;
      case ConnectionStatus.FATAL_ERROR:
      case ConnectionStatus.FAILED:
        refreshData();
        break;
      case ConnectionStatus.CONNECTING:
      case ConnectionStatus.NONE:
        break;
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
  bool get clickable => true;
}
