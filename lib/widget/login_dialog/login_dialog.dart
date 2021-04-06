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

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/card_repository.dart';
import 'package:dan_xi/util/flutter_app.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginDialog extends StatefulWidget {
  final SharedPreferences sharedPreferences;
  final ValueNotifier<PersonInfo> personInfo;
  final bool forceLogin;

  const LoginDialog(
      {Key key,
      @required this.sharedPreferences,
      @required this.personInfo,
      @required this.forceLogin})
      : super(key: key);

  @override
  _LoginDialogState createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  TextEditingController _nameController = new TextEditingController();
  TextEditingController _pwdController = new TextEditingController();
  String _errorText = "";

  /// Attempt to log in for verification.
  Future<void> _tryLogin(String id, String password) async {
    if (id.length * password.length == 0) {
      return;
    }
    var progressDialog = showProgressDialog(
        loadingText: S.of(context).logining, context: context);
    PersonInfo newInfo = PersonInfo.createNewInfo(id, password);
    await CardRepository.getInstance().login(newInfo).then((_) async {
      newInfo.name = await CardRepository.getInstance().getName();
      await newInfo.saveAsSharedPreferences(widget.sharedPreferences);
      setState(() => widget.personInfo.value = newInfo);
      progressDialog.dismiss();
      Navigator.of(context).pop();
    }, onError: (e) {
      progressDialog.dismiss();
      throw e;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PlatformAlertDialog(
      title: Text(S.of(context).login_uis),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _errorText,
            textAlign: TextAlign.start,
            style: TextStyle(fontSize: 12, color: Colors.red),
          ),
          PlatformTextField(
            controller: _nameController,
            keyboardType: TextInputType.number,
            material: (_, __) => MaterialTextFieldData(
                decoration: InputDecoration(
                    labelText: S.of(context).login_uis_uid,
                    icon: PlatformX.isAndroid ? Icon(Icons.perm_identity) : Icon(SFSymbols.person_crop_circle))),
            cupertino: (_, __) => CupertinoTextFieldData(
                placeholder: S.of(context).login_uis_uid),
            autofocus: true,
          ),
          PlatformTextField(
            controller: _pwdController,
            material: (_, __) => MaterialTextFieldData(
              decoration: InputDecoration(
                  labelText: S.of(context).login_uis_pwd,
                  icon: PlatformX.isAndroid ? Icon(Icons.lock_outline) : Icon(SFSymbols.lock_circle),
            )),
            cupertino: (_, __) => CupertinoTextFieldData(
                placeholder: S.of(context).login_uis_pwd),
            obscureText: true,
            onSubmitted: (_) {
              _tryLogin(_nameController.text, _pwdController.text)
                  .catchError((e) {
                _errorText = S.of(context).login_failed;
                _pwdController.text = "";
                refreshSelf();
              });
            },
          )
        ],
      ),
      actions: [
        PlatformDialogAction(
          child: Text(S.of(context).cancel),
          onPressed: () {
            if (widget.forceLogin) {
              Navigator.of(context).pop();
            } else {
              FlutterApp.exitApp();
            }
          },
        ),
        PlatformDialogAction(
          child: Text(S.of(context).login),
          onPressed: () {
            _tryLogin(_nameController.text, _pwdController.text)
                .catchError((e) {
              _errorText = S.of(context).login_failed;
              _pwdController.text = "";
              refreshSelf();
            });
          },
        )
      ],
    );
  }
}
