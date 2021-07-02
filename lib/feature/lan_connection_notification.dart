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
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class LanConnectionNotification extends Feature {
  @override
  String get mainTitle => S.of(context).lan_connection_issue_1;

  @override
  bool get removable => true;

  @override
  String get subTitle => S.of(context).lan_connection_issue_1_description;

  @override
  Widget get icon => Icon(Icons.signal_wifi_connected_no_internet_4);

  @override
  Widget get trailing {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        PlatformTextButton(
          child: Text(S.of(context).lan_connection_issue_1_action),
          // User needs to download the vpn software. Open an external browser.
          onPressed: () => launch(
              "https://stuvpn.fudan.edu.cn/com/installClient.html#auto-common"),
        ),
      ],
    );
  }
}
