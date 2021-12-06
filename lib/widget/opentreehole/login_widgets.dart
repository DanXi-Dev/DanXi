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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Text(
              "FDUHole 2.0",
              style: TextStyle(fontSize: 32.0),
            ),
            Column(
              children: [
                ListTile(
                  leading: Icon(CupertinoIcons.bell),
                  title: Text("Notifications"),
                  subtitle:
                      Text("Receive notifications when new data is available"),
                ),
                ListTile(
                  leading: Icon(CupertinoIcons.textformat_superscript),
                  title: Text("LaTeX Support"),
                  subtitle: Text("Use LaTeX in your notes"),
                ),
                ListTile(
                  leading: Icon(CupertinoIcons.hand_thumbsup),
                  title: Text("Like and Division"),
                  subtitle: Text("Like floors and different divisions"),
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
