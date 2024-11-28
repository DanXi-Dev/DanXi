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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/fdu/ecard_repository.dart';
import 'package:dan_xi/repository/fdu/ehall_repository.dart';
import 'package:dan_xi/repository/fdu/uis_login_tool.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/shared_preferences.dart';
import 'package:dan_xi/widget/libraries/platform_context_menu.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';

const kCompatibleUserGroup = [
  UserGroup.FUDAN_UNDERGRADUATE_STUDENT,
  UserGroup.FUDAN_POSTGRADUATE_STUDENT,
  UserGroup.VISITOR
];

/// [LoginDialog] is a dialog allowing user to log in by inputting their UIS ID/Password.
///
/// Also contains the logic to process logging in.
class LoginDialog extends StatefulWidget {
  final XSharedPreferences? sharedPreferences;
  final ValueNotifier<PersonInfo?> personInfo;
  final bool dismissible;
  static bool _isShown = false;

  static bool get dialogShown => _isShown;

  static showLoginDialog(BuildContext context, XSharedPreferences? preferences,
      ValueNotifier<PersonInfo?> personInfo, bool dismissible) async {
    if (_isShown) return;
    _isShown = true;
    await showPlatformDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => LoginDialog(
            sharedPreferences: preferences,
            personInfo: personInfo,
            dismissible: dismissible));
    _isShown = false;
  }

  const LoginDialog(
      {super.key,
      required this.sharedPreferences,
      required this.personInfo,
      required this.dismissible});

  @override
  LoginDialogState createState() => LoginDialogState();
}

class LoginDialogState extends State<LoginDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pwdController = TextEditingController();
  String _errorText = "";
  static const DEFAULT_USERGROUP = UserGroup.FUDAN_UNDERGRADUATE_STUDENT;
  UserGroup _group = DEFAULT_USERGROUP;

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
            PersonInfo(id, password, "No User Account", UserGroup.VISITOR);
        await newInfo.saveToSharedPreferences(widget.sharedPreferences!);
        widget.personInfo.value = newInfo;
        progressDialog.dismiss(showAnim: false);
        Navigator.of(context).pop();
        showFAQ();
        break;
      case UserGroup.FUDAN_POSTGRADUATE_STUDENT:
      case UserGroup.FUDAN_UNDERGRADUATE_STUDENT:
        PersonInfo newInfo = PersonInfo.createNewInfo(id, password, _group);
        try {
          final stuInfo =
              await FudanEhallRepository.getInstance().getStudentInfo(newInfo);
          newInfo.name = stuInfo.name;
          await newInfo.saveToSharedPreferences(widget.sharedPreferences!);
          widget.personInfo.value = newInfo;
          progressDialog.dismiss(showAnim: false);
          Navigator.of(context).pop();
          showFAQ();
        } catch (e) {
          if (e is DioException) {
            progressDialog.dismiss(showAnim: false);
            rethrow;
          }
          try {
            newInfo.name = await CardRepository.getInstance().getName(newInfo);
            if (newInfo.name?.isEmpty ?? true) {
              throw GeneralLoginFailedException();
            }
            await newInfo.saveToSharedPreferences(widget.sharedPreferences!);
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

  Future<bool?> showFAQ() {
    return showPlatformDialog(
        context: context,
        builder: (BuildContext context) => PlatformAlertDialog(
              title: PlatformText(
                S.of(context).welcome_feature,
                textAlign: TextAlign.center,
              ),
              content: PlatformText(
                S.of(context).welcome_prompt,
                textAlign: TextAlign.center,
              ),
              actions: <Widget>[
                PlatformDialogAction(
                    child: PlatformText(S.of(context).skip),
                    onPressed: () => Navigator.pop(context)),
                PlatformDialogAction(
                    child: PlatformText(S.of(context).i_see),
                    onPressed: () {
                      BrowserUtil.openUrl(Constant.FAQ_URL, context);
                    }),
              ],
            ));
  }

  void requestInternetAccess() async {
    // This webpage only returns plain-text 'SUCCESS' and is ideal for testing connection.
    try {
      // fixme: use a privacy-friendly captive portal detection method.
      await DioUtils.newDioWithProxy().head('http://captive.apple.com');
    } catch (ignored) {}
  }

  List<Widget> _buildLoginAsList(BuildContext menuContext) {
    List<Widget> widgets = [];
    for (var e in kCompatibleUserGroup) {
      if (e != _group) {
        widgets.add(PlatformContextMenuItem(
          menuContext: menuContext,
          onPressed: () => _switchLoginGroup(e),
          child: Text(kUserGroupDescription[e]!(menuContext)),
        ));
      }
    }
    return widgets;
  }

  void _executeLogin() {
    _tryLogin(_nameController.text, _pwdController.text).catchError((error) {
      if (error is CredentialsInvalidException) {
        _pwdController.text = "";
        _errorText = S.of(context).credentials_invalid;
      } else if (error is CaptchaNeededException) {
        _errorText = S.of(context).captcha_needed;
      } else if (error is NetworkMaintenanceException) {
        _errorText = S.of(context).under_maintenance;
      } else if (error is GeneralLoginFailedException) {
        _errorText = S.of(context).weak_password;
      } else {
        _errorText = S.of(context).connection_failed;
      }
      refreshSelf();
    });
  }

  @override
  Widget build(BuildContext context) {
    var defaultText =
        Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 12);
    var linkText = Theme.of(context)
        .textTheme
        .bodyMedium!
        .copyWith(color: Theme.of(context).colorScheme.secondary, fontSize: 12);

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).login_uis_description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_group == DEFAULT_USERGROUP) ...[
                GestureDetector(
                  child: Text(
                    S.of(context).not_undergraduate,
                    style: linkText,
                  ),
                  onTap: () => _showSwitchGroupModal(),
                ),
                GestureDetector(
                  child: Text(
                    S.of(context).try_visitor_mode,
                    style: linkText,
                  ),
                  onTap: () => _showSwitchGroupModal(),
                ),
              ],

              Text(
                _errorText,
                textAlign: TextAlign.start,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
              TextField(
                controller: _nameController,
                enabled: _group != UserGroup.VISITOR,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                    labelText: S.of(context).login_uis_uid,
                    icon: PlatformX.isMaterial(context)
                        ? const Icon(Icons.perm_identity)
                        : const Icon(CupertinoIcons.person_crop_circle)),
                autofocus: true,
              ),
              if (!PlatformX.isMaterial(context)) const SizedBox(height: 2),
              TextField(
                controller: _pwdController,
                enabled: _group != UserGroup.VISITOR,
                decoration: InputDecoration(
                  labelText: S.of(context).login_uis_pwd,
                  icon: PlatformX.isMaterial(context)
                      ? const Icon(Icons.lock_outline)
                      : const Icon(CupertinoIcons.lock_circle),
                ),
                obscureText: true,
                onSubmitted: (_) => _executeLogin(),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                child: Text(
                  S.of(context).cant_login,
                  style: linkText,
                ),
                onTap: () => Noticing.showNotice(context,
                    S.of(context).login_problem(Constant.SUPPORT_QQ_GROUP),
                    title: S.of(context).cant_login,
                    useSnackBar: false,
                    customActions: [
                      CustomDialogActionItem(S.of(context).read_announcements,
                          () {
                        while (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                        smartNavigatorPush(context, '/announcement/list',
                            forcePushOnMainNavigator: true);
                      }),
                      CustomDialogActionItem(
                          S.of(context).copy_qq_group_id,
                          () => Clipboard.setData(const ClipboardData(
                              text: Constant.SUPPORT_QQ_GROUP))),
                    ]),
              ),
              const SizedBox(height: 12),
              //Legal
              Text.rich(TextSpan(children: [
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
          onPressed: _executeLogin,
          child: Text(S.of(context).login),
        ),
        TextButton(
            onPressed: () {
              _showSwitchGroupModal();
            },
            child: Text(S.of(context).login_as_others))
      ],
    );
  }

  _showSwitchGroupModal() {
    return showPlatformModalSheet(
        context: context,
        builder: (context) => PlatformContextMenu(
            actions: _buildLoginAsList(context),
            cancelButton: CupertinoActionSheetAction(
              child: Text(S.of(context).cancel),
              onPressed: () => Navigator.of(context).pop(),
            )));
  }

  /// Change the login group and rebuild the dialog.
  _switchLoginGroup(UserGroup e) {
    if (e == UserGroup.VISITOR) {
      _nameController.text = _pwdController.text = "[ Forum Only ]";
    } else {
      _nameController.text = _pwdController.text = "";
    }
    setState(() => _group = e);
  }
}
