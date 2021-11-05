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
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/card_repository.dart';
import 'package:dan_xi/repository/fudan_ehall_repository.dart';
import 'package:dan_xi/repository/uis_login_tool.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/with_scrollbar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kCompatibleUserGroup = [
  UserGroup.FUDAN_UNDERGRADUATE_STUDENT,
  UserGroup.FUDAN_POSTGRADUATE_STUDENT,
  UserGroup.VISITOR
];

/// [LoginDialog] is a dialog allowing user to log in by inputting their UIS ID/Password.
///
/// Also contains the logic to process logging in.
class LoginDialog extends StatefulWidget {
  final SharedPreferences? sharedPreferences;
  final ValueNotifier<PersonInfo?> personInfo;
  final bool dismissible;
  static bool _isShown = false;

  static bool get dialogShown => _isShown;

  static showLoginDialog(BuildContext context, SharedPreferences? _preferences,
      ValueNotifier<PersonInfo?> personInfo, bool dismissible) async {
    if (_isShown) return;
    _isShown = true;
    await showPlatformDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => LoginDialog(
            sharedPreferences: _preferences,
            personInfo: personInfo,
            dismissible: dismissible));
    _isShown = false;
  }

  const LoginDialog(
      {Key? key,
      required this.sharedPreferences,
      required this.personInfo,
      required this.dismissible})
      : super(key: key);

  @override
  _LoginDialogState createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  TextEditingController _nameController = new TextEditingController();
  TextEditingController _pwdController = new TextEditingController();
  String _errorText = "";
  UserGroup _group = UserGroup.FUDAN_UNDERGRADUATE_STUDENT;

  Future<bool> _deleteAllData() async =>
      await widget.sharedPreferences!.clear();

  /// Attempt to log in for verification.
  Future<void> _tryLogin(String id, String password) async {
    if (id.length * password.length == 0) {
      return;
    }
    ProgressFuture progressDialog = showProgressDialog(
        loadingText: S.of(context).logining, context: context);
    switch (_group) {
      case UserGroup.VISITOR:
        PersonInfo newInfo =
            PersonInfo(id, password, "Visitor", UserGroup.VISITOR);
        _deleteAllData().then((value) async {
          await newInfo.saveAsSharedPreferences(widget.sharedPreferences!);
          widget.personInfo.value = newInfo;
          progressDialog.dismiss(showAnim: false);
          Navigator.of(context).pop();
        });
        break;
      case UserGroup.FUDAN_POSTGRADUATE_STUDENT:
      case UserGroup.FUDAN_UNDERGRADUATE_STUDENT:
        PersonInfo newInfo = PersonInfo.createNewInfo(id, password, _group);
        try {
          final stuInfo =
              await FudanEhallRepository.getInstance().getStudentInfo(newInfo);
          newInfo.name = stuInfo.name;
          await _deleteAllData();
          await newInfo.saveAsSharedPreferences(widget.sharedPreferences!);
          widget.personInfo.value = newInfo;
          progressDialog.dismiss(showAnim: false);
          Navigator.of(context).pop();
        } catch (e) {
          try {
            await CardRepository.getInstance().init(newInfo);
            newInfo.name = await CardRepository.getInstance().getName();
            if (newInfo.name?.isNotEmpty == true)
              throw GeneralLoginFailedException();
            await _deleteAllData();
            await newInfo.saveAsSharedPreferences(widget.sharedPreferences!);
            widget.personInfo.value = newInfo;
            progressDialog.dismiss(showAnim: false);
            Navigator.of(context).pop();
          } catch (error) {
            progressDialog.dismiss(showAnim: false);
            rethrow;
          }
        }
        break;
      case UserGroup.FUDAN_STAFF:
      case UserGroup.SJTU_STUDENT:
        progressDialog.dismiss(showAnim: false);
        break;
    }
  }

  void requestInternetAccess() async {
    //This webpage only returns plain-text 'SUCCESS' and is ideal for testing connection
    try {
      await Dio().head('http://captive.apple.com');
    } catch (ignored) {}
  }

  List<Widget> _buildLoginAsList() {
    List<Widget> widgets = [];
    kCompatibleUserGroup.forEach((e) {
      if (e != _group) {
        widgets.add(PlatformWidget(
          cupertino: (_, __) => CupertinoActionSheetAction(
            onPressed: () => _switchLoginGroup(e),
            child: Text(kUserGroupDescription[e]!(context)),
          ),
          material: (_, __) => ListTile(
            title: Text(kUserGroupDescription[e]!(context)),
            onTap: () => _switchLoginGroup(e),
          ),
        ));
      }
    });
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    var defaultText =
        Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 12);
    var linkText = Theme.of(context)
        .textTheme
        .bodyText2!
        .copyWith(color: Theme.of(context).accentColor, fontSize: 12);

    //Tackle #25
    if (!widget.dismissible) {
      requestInternetAccess();
    }

    final scrollController = PrimaryScrollController.of(context);

    return AlertDialog(
      title: Text(kUserGroupDescription[_group]!(context)),
      content: WithScrollbar(
        controller: scrollController,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(S.of(context).login_uis_description),
              Text(
                _errorText,
                textAlign: TextAlign.start,
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
              TextField(
                controller: _nameController,
                enabled: _group != UserGroup.VISITOR,
                keyboardType: TextInputType.number,
                //material: (_, __) => MaterialTextFieldData(
                decoration: InputDecoration(
                    labelText: S.of(context).login_uis_uid,
                    icon: PlatformX.isAndroid
                        ? Icon(Icons.perm_identity)
                        : Icon(CupertinoIcons.person_crop_circle)),
                //),
                /*cupertino: (_, __) => CupertinoTextFieldData(
                placeholder: S.of(context).login_uis_uid),*/
                autofocus: true,
              ),
              if (!PlatformX.isMaterial(context)) const SizedBox(height: 2),
              TextField(
                controller: _pwdController,
                enabled: _group != UserGroup.VISITOR,
                //material: (_, __) => MaterialTextFieldData(
                decoration: InputDecoration(
                  labelText: S.of(context).login_uis_pwd,
                  icon: PlatformX.isAndroid
                      ? Icon(Icons.lock_outline)
                      : Icon(CupertinoIcons.lock_circle),
                ),
                //)),
                /*cupertino: (_, __) => CupertinoTextFieldData(
                placeholder: S.of(context).login_uis_pwd),*/
                obscureText: true,
                onSubmitted: (_) {
                  _tryLogin(_nameController.text, _pwdController.text)
                      .catchError((e) {
                    if (e is CredentialsInvalidException) {
                      _pwdController.text = "";
                      _errorText = S.of(context).credentials_invalid;
                    } else if (e is CaptchaNeededException) {
                      _errorText = S.of(context).captcha_needed;
                    } else if (e is GeneralLoginFailedException) {
                      _errorText = S.of(context).weak_password;
                    } else {
                      _errorText = S.of(context).connection_failed;
                    }
                    // _pwdController.text = "";
                    refreshSelf();
                  });
                },
              ),
              const SizedBox(
                height: 24,
              ),
              //Legal
              RichText(
                  text: TextSpan(children: [
                TextSpan(
                  style: defaultText,
                  text: S.of(context).terms_and_conditions_content,
                ),
                TextSpan(
                    style: linkText,
                    text: S.of(context).privacy_policy,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        await BrowserUtil.openUrl(
                            S.of(context).privacy_policy_url, context);
                      }),
                TextSpan(
                  style: defaultText,
                  text: S.of(context).terms_and_conditions_content_end,
                ),
              ])),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.dismissible)
          TextButton(
              child: Text(S.of(context).cancel),
              onPressed: () {
                Navigator.of(context).pop();
              }),
        TextButton(
          child: Text(S.of(context).login),
          onPressed: () {
            _tryLogin(_nameController.text, _pwdController.text)
                .catchError((e) {
              if (e is CredentialsInvalidException) {
                _errorText = S.of(context).credentials_invalid;
              } else if (e is CaptchaNeededException) {
                _errorText = S.of(context).captcha_needed;
              } else if (e is GeneralLoginFailedException) {
                _errorText = S.of(context).weak_password;
              } else {
                _errorText = S.of(context).connection_failed;
              }
              _pwdController.text = "";
              refreshSelf();
            });
          },
        ),
        TextButton(
            onPressed: () {
              showPlatformModalSheet(
                  context: context,
                  builder: (_) => PlatformWidget(
                        cupertino: (_, __) => CupertinoActionSheet(
                          actions: _buildLoginAsList(),
                          cancelButton: CupertinoActionSheetAction(
                            child: Text(S.of(context).cancel),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                        material: (_, __) => Container(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: _buildLoginAsList()),
                        ),
                      ));
            },
            child: Text(S.of(context).login_as_others))
      ],
    );
  }

  /// Change the login group and rebuild the dialog.
  _switchLoginGroup(UserGroup e) {
    // Close the dialog
    Navigator.of(context).pop();
    if (e == UserGroup.VISITOR) {
      _nameController.text = _pwdController.text = "visitor";
    } else {
      _nameController.text = _pwdController.text = "";
    }
    setState(() => _group = e);
  }
}
