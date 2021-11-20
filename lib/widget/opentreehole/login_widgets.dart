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

import 'package:catcher/catcher.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class OTLoginHelper {
  static final _instance = OTLoginHelper._();
  factory OTLoginHelper.getInstance() => _instance;
  OTLoginHelper._();

  // This lock is to prevent repeated login dialog popping up.
  bool _loginLock = false;

  Future login() async {
    if (_loginLock) {
      return;
    }
    _loginLock = true;
    try {
      return await loginWithUsernamePassword(
          Catcher.navigatorKey!.currentContext!);
    } catch (e) {
      _loginLock = false;
      rethrow;
    }
  }

  static Future<String?> loginWithUsernamePassword(BuildContext context) async {
    final Credentials? credentials = await showPlatformModalSheet(
      context: context,
      builder: (BuildContext context) {
        return Card(
          child: OTUsernamePasswordLoginWidget(),
        );
      },
    );
    if (credentials == null) {
      return null;
    }
    return PostRepository.getInstance()
        .loginWithUsernamePassword(credentials.username, credentials.password);
  }
}

class OTUsernamePasswordLoginWidget extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(
              labelText: S.of(context).login_uis_uid,
              icon: PlatformX.isAndroid
                  ? Icon(Icons.perm_identity)
                  : Icon(CupertinoIcons.person_crop_circle)),
        ),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: S.of(context).login_uis_pwd,
            icon: PlatformX.isAndroid
                ? Icon(Icons.lock_outline)
                : Icon(CupertinoIcons.lock_circle),
          ),
        ),
        ElevatedButton(
          child: Text(S.of(context).login),
          onPressed: () {
            Navigator.of(context).pop(Credentials(
                _usernameController.text, _passwordController.text));
          },
        ),
        ElevatedButton(
          child: Text(S.of(context).cancel),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class Credentials {
  final String username;
  final String password;

  Credentials(this.username, this.password);
}
