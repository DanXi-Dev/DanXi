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

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// Simple helper class to show a [SnackBar] on Android or a [CupertinoAlertDialog] on iOS.
class Noticing {
  static showNotice(BuildContext context, String message,
      {String confirmText, String title, bool androidUseSnackbar = true}) {
    if (PlatformX.isMaterial(context) && androidUseSnackbar) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Linkify(text: message)));
    } else {
      showPlatformDialog(
          context: context,
          builder: (BuildContext context) => PlatformAlertDialog(
                title: title == null ? null : Text(title),
                content: Linkify(text: message),
                actions: <Widget>[
                  PlatformDialogAction(
                      child: PlatformText(confirmText ?? S.of(context).i_see),
                      onPressed: () => Navigator.pop(context)),
                ],
              ));
    }
  }
}
