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
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:url_launcher/url_launcher.dart';

class CustomShortcutFeature extends Feature {
  final String? title;
  final String? link;
  CustomShortcutFeature({this.title, this.link});

  @override
  String? get mainTitle => title;

  @override
  String? get subTitle => link;

  @override
  Widget get icon => Icon(CupertinoIcons.bookmark);

  @override
  void onTap() async {
    if (await canLaunch(link!)) {
      BrowserUtil.openUrl(link!, context);
    } else {
      Noticing.showNotice(context!, S.of(context!).cannot_launch_url);
    }
  }

  @override
  bool get clickable => true;
}
