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
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class OTWelcomeWidget extends StatelessWidget {
  final void Function() loginCallback;

  const OTWelcomeWidget({Key? key, required this.loginCallback})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: Text(
                S.of(context).welcome_title,
                style: TextStyle(fontSize: 28.0),
              ),
            ),
            Column(
              children: [
                ListTile(
                  leading: Icon(
                    PlatformX.isMaterial(context)
                        ? Icons.notifications
                        : CupertinoIcons.bell,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  title: Text(S.of(context).welcome_1),
                  subtitle: Text(S.of(context).welcome_1s),
                ),
                ListTile(
                  leading: Icon(
                    PlatformX.isMaterial(context)
                        ? Icons.forum
                        : CupertinoIcons.bubble_right,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  title: Text(S.of(context).welcome_2),
                  subtitle: Text(S.of(context).welcome_2s),
                ),
                ListTile(
                  leading: Icon(
                    PlatformX.isMaterial(context)
                        ? Icons.superscript
                        : CupertinoIcons.textformat_superscript,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  title: Text(S.of(context).welcome_3),
                  subtitle: Text(S.of(context).welcome_3s),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: PlatformElevatedButton(
                child: Text(S.of(context).login),
                onPressed: loginCallback,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
