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
import 'package:dan_xi/util/shared_preferences.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// [FallbackLoginException] is thrown when both primary and fallback login methods fail.
/// Captures error information from both attempts for better debugging.
class FallbackLoginException implements Exception {
  final Object primaryError;
  final StackTrace primaryStackTrace;
  final Object fallbackError;
  final StackTrace fallbackStackTrace;

  FallbackLoginException({
    required this.primaryError,
    required this.primaryStackTrace,
    required this.fallbackError,
    required this.fallbackStackTrace,
  });

  @override
  String toString() => 'FallbackLoginException: Both login methods failed.\n'
      'Primary error: $primaryError\n'
      'Fallback error: $fallbackError';
}

/// [LoginDialog] is a dialog allowing user to log in by inputting their UIS ID/Password.
///
/// Also contains the logic to process logging in.
class LoginDialog extends HookConsumerWidget {
  final XSharedPreferences sharedPreferences;
  final ValueNotifier<PersonInfo?> personInfo;
  final bool dismissible;
  final bool isGraduate;
  final UserGroup _defaultUserGroup;

  const LoginDialog({super.key, required this.sharedPreferences, required this.personInfo, required this.dismissible, required this.isGraduate}):
    _defaultUserGroup = isGraduate ? UserGroup.FUDAN_POSTGRADUATE_STUDENT : UserGroup.FUDAN_UNDERGRADUATE_STUDENT;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final pwdController = useTextEditingController();
    final currentGroup = useState<UserGroup>(_defaultUserGroup);
    final errorWidget = useState<Widget>(SizedBox.shrink());

    final defaultText =
    Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 12);
    final linkText = Theme.of(context)
        .textTheme
        .bodyMedium!
        .copyWith(color: Theme.of(context).colorScheme.secondary, fontSize: 12);

    final scrollController = PrimaryScrollController.of(context);

    return AlertDialog(
      title: Text(kUserGroupDescription[currentGroup.value]!(context)),
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
              errorWidget.value,
              TextField(
                controller: nameController,
                enabled: true,
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
                controller: pwdController,
                enabled: true,
                decoration: InputDecoration(
                  labelText: S.of(context).login_uis_pwd,
                  icon: PlatformX.isMaterial(context)
                      ? const Icon(Icons.lock_outline)
                      : const Icon(CupertinoIcons.lock_circle),
                ),
                obscureText: true,
                onSubmitted: (_) => _executeLogin(context, nameController, pwdController, errorWidget, currentGroup.value),
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
        if (dismissible)
          TextButton(
              child: Text(S.of(context).cancel),
              onPressed: () {
                Navigator.of(context).pop();
              }),
        TextButton(
          onPressed: () => _executeLogin(context, nameController, pwdController, errorWidget, currentGroup.value),
          child: Text(S.of(context).login),
        ),
      ],
    );
  }

  Future<void> _executeLogin(BuildContext context, TextEditingController nameController, TextEditingController pwdController, ValueNotifier<Widget> errorWidget, UserGroup group) async {
    try {
      await _tryLogin(context, nameController.text, pwdController.text, group);
    } catch (error, stack) {
      if (error is CredentialsInvalidException) {
        pwdController.text = "";
      }
      if (!context.mounted) return;
      errorWidget.value = ErrorPageWidget.buildWidget(
        context,
        error,
        stackTrace: stack,
        buttonText: "", // hide the button
        errorMessageTextStyle: const TextStyle(fontSize: 12, color: Colors.red),
      );
    }
  }

  /// Attempt to log in for verification.
  Future<void> _tryLogin(BuildContext context, String id, String password, UserGroup group) async {
    if (id.length * password.length == 0) {
      return;
    }
    ProgressFuture progressDialog = showProgressDialog(
        loadingText: S.of(context).logining, context: context);
    switch (group) {
      case UserGroup.FUDAN_POSTGRADUATE_STUDENT:
      case UserGroup.FUDAN_UNDERGRADUATE_STUDENT:
        PersonInfo newInfo = PersonInfo.createNewInfo(id, password, group);
        try {
          final stuInfo =
          await FudanEhallRepository.getInstance().getStudentInfo(newInfo);
          newInfo.name = stuInfo.name;
          await newInfo.saveToSharedPreferences(sharedPreferences);
          personInfo.value = newInfo;
          progressDialog.dismiss(showAnim: false);
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        } catch (primaryError, primaryStackTrace) {
          if (primaryError is DioException) {
            progressDialog.dismiss(showAnim: false);
            rethrow;
          }
          try {
            newInfo.name = await CardRepository.getInstance().getName(newInfo);
            await newInfo.saveToSharedPreferences(sharedPreferences);
            personInfo.value = newInfo;
            progressDialog.dismiss(showAnim: false);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          } catch (fallbackError, fallbackStackTrace) {
            progressDialog.dismiss(showAnim: false);
            throw FallbackLoginException(
              primaryError: primaryError,
              primaryStackTrace: primaryStackTrace,
              fallbackError: fallbackError,
              fallbackStackTrace: fallbackStackTrace,
            );
          }
        }
        break;
      case UserGroup.FUDAN_STAFF:
      case UserGroup.SJTU_STUDENT:
        progressDialog.dismiss(showAnim: false);
        break;
    }
  }

  static Future<void> showLoginDialog(BuildContext context, XSharedPreferences preferences,
      ValueNotifier<PersonInfo?> personInfo, bool dismissible, {bool isGraduate = false}) async {
    if (_isShown) return;
    _isShown = true;
    await showPlatformDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => LoginDialog(
            sharedPreferences: preferences,
            personInfo: personInfo,
            dismissible: dismissible,
            isGraduate: isGraduate));
    _isShown = false;
  }


  static bool _isShown = false;

  static bool get dialogShown => _isShown;

}