/*
 *     Copyright (C) 2021  w568w
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
import 'package:dan_xi/repository/fudan_daily_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:provider/provider.dart';

class FudanDailyFeature extends Feature {
  PersonInfo _info;
  ConnectionStatus _status = ConnectionStatus.NONE;
  String _subTitle;
  bool _hasTicked;

  void _loadTickStatus() {
    _status = ConnectionStatus.CONNECTING;
    FudanDailyRepository.getInstance().hasTick(_info).then((bool value) {
      _status = ConnectionStatus.DONE;
      _subTitle = value
          ? S.of(context).fudan_daily_ticked
          : S.of(context).fudan_daily_tick;
      _hasTicked = value;
      notifyUpdate();
    }, onError: (error) {
      _status = ConnectionStatus.FAILED;
      _subTitle = S.of(context).failed;
      notifyUpdate();
    });
  }

  @override
  void buildFeature() {
    _info = Provider.of<ValueNotifier<PersonInfo>>(context)?.value;

    // Only load card data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_status == ConnectionStatus.NONE) {
      _subTitle = S.of(context).loading;
      _loadTickStatus();
    }
  }

  @override
  String get mainTitle => S.of(context).fudan_daily;

  @override
  String get subTitle => _subTitle;

  @override
  Widget get icon => const Icon(Icons.cloud_upload);

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

  void refreshData() {
    _status = ConnectionStatus.NONE;
    _subTitle = S.of(context).loading;
    notifyUpdate();
  }

  @override
  void onTap() async {
    switch (_status) {
      case ConnectionStatus.DONE:
        if (!_hasTicked) {
          var progressDialog = showProgressDialog(
              loadingText: S.of(context).ticking, context: context);
          await FudanDailyRepository.getInstance().tick(_info).then((value) {
            progressDialog.dismiss();
            refreshData();
          }, onError: (e) {
            progressDialog.dismiss();
            if (e is NotTickYesterdayException) {
              _processForgetTickIssue();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(S.of(context).tick_failed)));
            }
          });
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
  bool get clickable => true;
}
