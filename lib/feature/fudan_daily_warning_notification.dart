/*
 *     Copyright (C) 2022  DanXi-Dev
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
import 'package:dan_xi/feature/fudan_daily_feature.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class FudanDailyWarningNotification extends Feature {
  @override
  String get mainTitle => S.of(context!).fudan_daily_warning_notification;

  @override
  bool get removable => true;

  @override
  Widget get icon => Icon(
        PlatformX.isMaterial(context!)
            ? Icons.cloud_off
            : CupertinoIcons.arrow_up_doc,
        color: Theme.of(context!).errorColor,
      );

  @override
  Widget get customSubtitle {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      PlatformTextButton(
        padding: EdgeInsets.zero,
        child: Text(
          S.of(context!).fudan_daily_warning_notification_action,
          style: TextStyle(color: Theme.of(context!).errorColor),
        ),
        onPressed: () => FudanDailyFeature.pushFudanDailyWebPage(context!),
      ),
    ]);
  }
}
