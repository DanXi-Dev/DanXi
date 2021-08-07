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
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/fudan_app_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/scale_transform.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:permission_handler/permission_handler.dart';

class FudanDailyFeature extends Feature {
  PersonInfo _info;
  ConnectionStatus _status = ConnectionStatus.NONE;
  String _subTitle;
  bool _hasTicked = true;

  //int _countdownRemainingTime = Constant.FUDAN_DAILY_COUNTDOWN_SECONDS; //Value -2 means stop countdown

  Future<void> _loadTickStatus() async {
    _status = ConnectionStatus.CONNECTING;
    // Get the status of reporting
    await FudanCOVID19Repository.getInstance()
        .hasTick(_info)
        .then((bool ticked) {
      _status = ConnectionStatus.DONE;

      if (ticked) {
        _subTitle = S.of(context).fudan_daily_ticked;
      } else {
        if (SettingsProvider.getInstance().debugMode)
          _subTitle = S.of(context).fudan_daily_tick;
        else
          _subTitle = S.of(context).fudan_daily_tick_link;
      }
      _hasTicked = ticked;
      notifyUpdate();
    });
  }

  void tickFudanDaily() {
    if (!_hasTicked) {
      FudanCOVID19Repository.getInstance().tick(_info).then((_) {
        refreshData();
      }, onError: (e) {
        if (e is NotTickYesterdayException) {
          _processForgetTickIssue();
        } else {
          _subTitle = S.of(context).tick_failed;
          notifyUpdate();
          Noticing.showNotice(context, S.of(context).tick_failed);
        }
      });
    }
  }

  /*void startCountdown() {
    _subTitle = S.of(context).fudan_daily_tick_countdown(_countdownRemainingTime.toString());
    notifyUpdate();
    Timer(Duration(seconds: 1), handleTimeout);
  }

  void handleTimeout() {  // callback function
    if (_countdownRemainingTime == 0) {
      tickFudanDaily();
      _countdownRemainingTime = -2;
    }
    else if (_countdownRemainingTime != -2) {
      _countdownRemainingTime--;
      startCountdown();
    }
  }*/

  @override
  void buildFeature([Map<String, dynamic> arguments]) {
    _info = StateProvider.personInfo.value;

    // Only load card data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_status == ConnectionStatus.NONE) {
      _subTitle = S.of(context).loading;
      _loadTickStatus().catchError((error) {
        _status = ConnectionStatus.FAILED;
        _subTitle = S.of(context).failed;
        notifyUpdate();
      });
    }
  }

  @override
  String get mainTitle => S.of(context).fudan_daily;

  @override
  String get subTitle => _subTitle;

  @override
  Widget get customSubtitle => _hasTicked
      ? null
      : Text(
          S.of(context).fudan_daily_tick_link,
          style: TextStyle(color: Colors.red),
        );

  //@override
  //String get tertiaryTitle => S.of(context).fudan_daily_disabled_notice;

  @override
  Widget get icon => PlatformX.isAndroid
      ? const Icon(Icons.cloud_upload)
      : const Icon(SFSymbols.arrow_up_doc);

  void _processForgetTickIssue() {
    showPlatformDialog(
        context: context,
        builder: (_) => PlatformAlertDialog(
              title: Text(S.of(context).fatal_error),
              content: Text(S.of(context).tick_issue_1),
              actions: [
                PlatformDialogAction(
                    child: Text(S.of(context).i_see),
                    onPressed: () => Navigator.of(context).pop())
              ],
            ));
  }

  /*bool get shouldAutomaticallyTickToday {
    DateTime now = new DateTime.now();
    DateTime todayDate = new DateTime(now.year, now.month, now.day);
    return SettingsProvider.of(_preferences).autoTickCancelDate !=
        todayDate.toString();
  }

  set shouldAutomaticallyTickToday(bool value) {
    DateTime now = new DateTime.now();
    DateTime todayDate = new DateTime(now.year, now.month, now.day);
    if (value) {
      SettingsProvider.of(_preferences).autoTickCancelDate = "";
    } else {
      SettingsProvider.of(_preferences).autoTickCancelDate =
          todayDate.toString();
    }
  }*/

  /// Restart the loading process
  void refreshData() {
    _status = ConnectionStatus.NONE;
    _subTitle = S.of(context).loading;
    notifyUpdate();
  }

  @override
  void onTap() async {
    switch (_status) {
      case ConnectionStatus.DONE:
        // If it's counting down, we'll cancel it
        /*if (_countdownRemainingTime >= 0) {
          _countdownRemainingTime = -2;
          _subTitle = S.of(context).fudan_daily_tick;
          //Don't try to tick again today
          shouldAutomaticallyTickToday = false;
          notifyUpdate();
        } else {
          tickFudanDaily();
        }*/
        if (SettingsProvider.getInstance().debugMode)
          tickFudanDaily();
        else {
          if (PlatformX.isMobile) {
            // Request Location Permission
            if (await Permission.locationWhenInUse.request() !=
                PermissionStatus.granted) {
              Noticing.showNotice(
                  context, S.of(context).location_permission_denied_promot);
              return;
            }
          }
          BrowserUtil.openUrl("https://zlapp.fudan.edu.cn/site/ncov/fudanDaily",
              context, FudanCOVID19Repository.getInstance().thisCookies);
        }
        break;
      case ConnectionStatus.FAILED:
        refreshData();
        break;
      case ConnectionStatus.FATAL_ERROR:
      case ConnectionStatus.CONNECTING:
      case ConnectionStatus.NONE:
        break;
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
