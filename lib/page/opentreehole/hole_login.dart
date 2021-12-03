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
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/animation.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/password_util.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/viewport_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';

/// OpenTreeHole login wizard page.
///
class HoleLoginPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  @override
  _HoleLoginPageState createState() => _HoleLoginPageState();

  HoleLoginPage({Key? key, this.arguments}) : super(key: key);
}

class _HoleLoginPageState extends State<HoleLoginPage> {
  late SubStatelessWidget _currentWidget;
  late PersonInfo info;
  LoginInfoModel model = new LoginInfoModel();
  List<SubStatelessWidget> _widgetStack = [];

  /// Indicate the next [_backwardRun] animation should run in the reverse direction,
  /// since we are going back to the previous page.
  int _backwardRun = 0;

  @override
  void initState() {
    super.initState();
    info = widget.arguments!["info"];
    _currentWidget = OTLoginMethodSelectionWidget(
      state: this,
    );
    _widgetStack.add(_currentWidget);
  }

  void jumpTo(SubStatelessWidget nextWidget, {bool putInStack = true}) {
    setState(() {
      _currentWidget = nextWidget;
      if (putInStack) {
        _widgetStack.add(_currentWidget);
      }
    });
  }

  bool jumpBackIgnoringBackable() {
    if (_widgetStack.length <= 1) return false;
    _widgetStack.removeLast();
    setState(() {
      _currentWidget = _widgetStack.last;
      _backwardRun = 2;
    });
    return true;
  }

  bool jumpBackFromLoadingPage() {
    if (_widgetStack.isEmpty) return false;
    setState(() {
      _currentWidget = _widgetStack.last;
      _backwardRun = 2;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_widgetStack.isNotEmpty && !_widgetStack.last.backable)
          return false;
        return !jumpBackIgnoringBackable();
      },
      child: Provider<LoginInfoModel>(
        create: (BuildContext context) => model,
        child: PlatformScaffold(
            iosContentBottomPadding: false,
            iosContentPadding: false,
            body: SafeArea(
              bottom: false,
              child: Material(
                child: AnimatedSwitcher(
                  switchInCurve: Curves.ease,
                  switchOutCurve: Curves.ease,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    var tween =
                        Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0));
                    // reverse the animation if invoked jumpBack().
                    if (_backwardRun > 0) {
                      tween = Tween<Offset>(
                          begin: Offset(-1, 0), end: Offset(0, 0));
                      _backwardRun--;
                    }
                    return MySlideTransition(
                      position: tween.animate(animation),
                      child: child,
                    );
                  },
                  duration: Duration(milliseconds: 250),
                  child: _currentWidget,
                ),
              ),
            )),
      ),
    );
  }
}

abstract class SubStatelessWidget extends StatelessWidget {
  final _HoleLoginPageState state;
  final bool backable = true;

  const SubStatelessWidget({Key? key, required this.state}) : super(key: key);

  Widget buildContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    Size size = ViewportUtils.getMainNavigatorSize(context);
    return Container(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.1, vertical: size.height * 0.1),
          child: Container(
            decoration: ShapeDecoration(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey, width: 0.5),
                    borderRadius: BorderRadius.circular(4))),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: buildContent(context),
            ),
          ),
        ),
      ),
    );
  }
}

class OTLoginMethodSelectionWidget extends SubStatelessWidget {
  const OTLoginMethodSelectionWidget(
      {Key? key, required _HoleLoginPageState state})
      : super(key: key, state: state);

  @override
  Widget buildContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.of(context).select_login_method,
            style: Theme.of(context).textTheme.headline6,
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 32,
          ),
          ListTile(
            title: Text(S.of(context).fudan_uis_quick_login),
            onTap: () => state.jumpTo(OTEmailSelectionWidget(
              state: state,
            )),
          ),
          Divider(),
          ListTile(
            title: Text(S.of(context).login_by_email_password),
            onTap: () => state.jumpTo(OTEmailPasswordLoginWidget(
              state: state,
            )),
          )
        ],
      ),
    );
  }
}

class OTEmailSelectionWidget extends SubStatelessWidget {
  const OTEmailSelectionWidget({Key? key, required _HoleLoginPageState state})
      : super(key: key, state: state);

  /// Check [email] usability.
  ///
  /// if [isRecommendedEmail], get the verify code straightly.
  /// Otherwise request an email OTP code.
  Future<void> checkEmailInfo(
      BuildContext context, String email, bool isRecommendedEmail) async {
    var model = Provider.of<LoginInfoModel>(context, listen: false);
    state.jumpTo(
        OTLoadingWidget(
          state: state,
        ),
        putInStack: false);
    bool registered =
        await OpenTreeHoleRepository.getInstance().checkRegisterStatus(email);
    if (registered) {
      state.jumpTo(OTEmailPasswordLoginWidget(
        state: state,
      ));
    } else {
      if (isRecommendedEmail) {
        model.verifyCode =
            await OpenTreeHoleRepository.getInstance().getVerifyCode(email);
        state.jumpTo(OTRegisterLicenseWidget(state: state));
      } else {
        model.verifyCode = null;
        state.jumpTo(OTRegisterLicenseWidget(state: state));
      }
    }
  }

  @override
  Widget buildContent(BuildContext context) {
    final EmailProvider provider = EmailProviderImpl();
    final String? recommendedEmail =
        provider.getRecommendedEmailList(state.info);
    final List<String> optionalEmail =
        provider.getOptionalEmailList(state.info);
    List<String> suggestEmail = [
      ...optionalEmail,
      S.of(context).my_email_not_in_list
    ];
    if (recommendedEmail != null) suggestEmail.insert(0, recommendedEmail);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          S.of(context).fudan_uis_quick_login,
          style: Theme.of(context).textTheme.headline6,
          textAlign: TextAlign.center,
        ),
        Text(
          S.of(context).choose_your_email_below,
          style: Theme.of(context).textTheme.caption,
          textAlign: TextAlign.center,
        ),
        SizedBox(
          height: 32,
        ),
        ...suggestEmail
            .map<Widget>((e) => ListTile(
                  title: Text(e),
                  onTap: () async {
                    String? email = e;
                    if (e == S.of(context).my_email_not_in_list) {
                      email = await showPlatformDialog<String?>(
                          context: context,
                          builder: (cxt) {
                            TextEditingController controller =
                                new TextEditingController();
                            return PlatformAlertDialog(
                              title: Text(S.of(context).input_your_email),
                              content: TextField(
                                controller: controller,
                              ),
                              actions: [
                                PlatformDialogAction(
                                  child: Text(S.of(context).i_see),
                                  onPressed: () {
                                    if (controller.text.trim().isNotEmpty) {
                                      Navigator.pop(
                                          cxt, controller.text.trim());
                                    }
                                  },
                                ),
                                PlatformDialogAction(
                                  child: Text(S.of(context).cancel),
                                  onPressed: () => Navigator.pop(cxt, null),
                                )
                              ],
                            );
                          });
                    }
                    Provider.of<LoginInfoModel>(context, listen: false)
                        .selectedEmail = email;
                    if (email != null) {
                      checkEmailInfo(context, email, email == recommendedEmail)
                          .catchError((e) {
                        state.jumpBackFromLoadingPage();
                        Noticing.showNotice(state.context,
                            S.of(context).unable_to_connect_to_server);
                      });
                    }
                  },
                ))
            .toList()
            .joinElement(() => Divider())!
      ],
    );
  }
}

class OTEmailPasswordLoginWidget extends SubStatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  OTEmailPasswordLoginWidget({Key? key, required _HoleLoginPageState state})
      : super(key: key, state: state);

  Future<void> executeLogin(BuildContext context) async {
    var model = Provider.of<LoginInfoModel>(context, listen: false);
    state.jumpTo(OTLoadingWidget(state: state), putInStack: false);
    await OpenTreeHoleRepository.getInstance()
        .loginWithUsernamePassword(model.selectedEmail!, model.password!);
    state.jumpTo(OTLoginSuccessWidget(state: state));
  }

  @override
  Widget buildContent(BuildContext context) {
    final model = Provider.of<LoginInfoModel>(context, listen: false);
    if (_usernameController.text.isEmpty) {
      _usernameController.text = model.selectedEmail ?? "";
    }
    return Column(
      children: <Widget>[
        Text(
          S.of(context).login_by_email_password,
          style: Theme.of(context).textTheme.headline6,
          textAlign: TextAlign.center,
        ),
        Text(
          S.of(context).input_your_email_password,
          style: Theme.of(context).textTheme.caption,
          textAlign: TextAlign.center,
        ),
        SizedBox(
          height: 32,
        ),
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
        SizedBox(
          height: 16,
        ),
        PlatformElevatedButton(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(S.of(context).login),
          ),
          onPressed: () {
            model.selectedEmail = _usernameController.text;
            model.password = _passwordController.text;
            if (_passwordController.text.length > 0 &&
                _usernameController.text.length > 0) {
              executeLogin(context).catchError((e, st) {
                state.jumpBackFromLoadingPage();
                Noticing.showNotice(
                    state.context, S.of(context).login_problem_occurred);
              });
            }
          },
        )
      ],
    );
  }
}

class OTLoadingWidget extends SubStatelessWidget {
  @override
  final bool backable = false;

  OTLoadingWidget({required _HoleLoginPageState state})
      : super(key: UniqueKey(), state: state);

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          S.of(context).obtaining_information,
          style: Theme.of(context).textTheme.headline6,
          textAlign: TextAlign.center,
        ),
        SizedBox(
          height: 32,
        ),
        Center(
          child: PlatformCircularProgressIndicator(),
        )
      ],
    );
  }
}

class OTRegisterLicenseWidget extends SubStatelessWidget {
  const OTRegisterLicenseWidget({Key? key, required _HoleLoginPageState state})
      : super(key: key, state: state);

  static Future<void> executeRegister(
      BuildContext context, _HoleLoginPageState state) async {
    var model = Provider.of<LoginInfoModel>(context, listen: false);
    state.jumpTo(OTLoadingWidget(state: state), putInStack: false);
    if (model.verifyCode == null) {
      await OpenTreeHoleRepository.getInstance()
          .requestEmailVerifyCode(model.selectedEmail!);
      state.jumpTo(OTEmailVerifyCodeWidget(state: state));
      return;
    }
    String generatedPassword = PasswordUtil.generateNormalPassword(8);
    model.password = generatedPassword;
    await OpenTreeHoleRepository.getInstance()
        .register(model.selectedEmail!, generatedPassword, model.verifyCode!);
    state.jumpTo(OTRegisterSuccessWidget(state: state));
  }

  @override
  Widget buildContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            S.of(context).welcome_to_fduhole,
            style: Theme.of(context).textTheme.headline6,
            textAlign: TextAlign.center,
          ),
          Text(
            S.of(context).agree_license_tip,
            style: Theme.of(context).textTheme.caption,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          OTLicenseBody(
            registerCallback: () {
              executeRegister(context, state).catchError((e, st) {
                state.jumpBackFromLoadingPage();
                Noticing.showNotice(
                    state.context, S.of(context).unable_to_connect_to_server);
              });
            },
          )
        ],
      ),
    );
  }
}

class OTLicenseBody extends StatefulWidget {
  final VoidCallback registerCallback;

  const OTLicenseBody({Key? key, required this.registerCallback})
      : super(key: key);

  @override
  _OTLicenseBodyState createState() => _OTLicenseBodyState();
}

class _OTLicenseBodyState extends State<OTLicenseBody> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckboxListTile(
            title: Text(
              S.of(context).i_have_read_and_agreed("《社区公约》"),
              style: Theme.of(context).textTheme.subtitle2,
            ),
            controlAffinity: ListTileControlAffinity.leading,
            value: _agreed,
            onChanged: (newValue) => setState(() {
                  _agreed = newValue!;
                })),
        PlatformElevatedButton(
          material: (_, __) =>
              MaterialElevatedButtonData(icon: Icon(Icons.app_registration)),
          child: Text(S.of(context).next),
          onPressed: _agreed ? widget.registerCallback : null,
        )
      ],
    );
  }
}

class OTEmailVerifyCodeWidget extends SubStatelessWidget {
  final TextEditingController _verifyCodeController = TextEditingController();

  OTEmailVerifyCodeWidget({Key? key, required _HoleLoginPageState state})
      : super(key: key, state: state);

  @override
  Widget buildContent(BuildContext context) {
    var model = Provider.of<LoginInfoModel>(context, listen: false);
    return Column(
      children: <Widget>[
        Text(
          "安全验证",
          style: Theme.of(context).textTheme.headline6,
          textAlign: TextAlign.center,
        ),
        Text(
          "请输入您的邮箱验证码",
          style: Theme.of(context).textTheme.caption,
          textAlign: TextAlign.center,
        ),
        SizedBox(
          height: 32,
        ),
        Text(
          "我们刚刚向您发送了一封含有一次性验证码的邮件，请输入您得到的验证码。",
        ),
        SizedBox(
          height: 8,
        ),
        TextField(
          controller: _verifyCodeController,
          decoration: InputDecoration(
              labelText: "验证码",
              icon: PlatformX.isAndroid
                  ? Icon(Icons.perm_identity)
                  : Icon(CupertinoIcons.person_crop_circle)),
        ),
        SizedBox(
          height: 16,
        ),
        PlatformElevatedButton(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(S.of(context).next),
          ),
          onPressed: () {
            model.verifyCode = _verifyCodeController.text;
            if (_verifyCodeController.text.length > 0) {
              OTRegisterLicenseWidget.executeRegister(context, state)
                  .catchError((e, st) {
                state.jumpBackFromLoadingPage();
                Noticing.showNotice(
                    state.context, S.of(context).login_problem_occurred);
              });
            }
          },
        )
      ],
    );
  }
}

class OTRegisterSuccessWidget extends SubStatelessWidget {
  @override
  final bool backable = false;

  OTRegisterSuccessWidget({Key? key, required _HoleLoginPageState state})
      : super(key: key, state: state);

  @override
  Widget buildContent(BuildContext context) {
    var model = Provider.of<LoginInfoModel>(context, listen: false);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          S.of(context).registration_succeed,
          style: Theme.of(context).textTheme.headline6,
          textAlign: TextAlign.center,
        ),
        Text(
          S.of(context).save_your_information,
          style: Theme.of(context).textTheme.caption,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32),
        Text(
          S.of(context).email,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(model.selectedEmail!),
        SizedBox(height: 8),
        Text(
          S.of(context).password,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(model.password!),
        SizedBox(height: 16),
        PlatformElevatedButton(
          material: (_, __) =>
              MaterialElevatedButtonData(icon: Icon(Icons.done)),
          child: Text(S.of(context).i_see),
          onPressed: () {
            Navigator.pop(state.context);
          },
        )
      ],
    );
  }
}

class OTLoginSuccessWidget extends SubStatelessWidget {
  @override
  final bool backable = false;

  OTLoginSuccessWidget({Key? key, required _HoleLoginPageState state})
      : super(key: key, state: state);

  @override
  Widget buildContent(BuildContext context) {
    var model = Provider.of<LoginInfoModel>(context, listen: false);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          S.of(context).welcome_back,
          style: Theme.of(context).textTheme.headline6,
          textAlign: TextAlign.center,
        ),
        Text(
          S.of(context).account_is_set,
          style: Theme.of(context).textTheme.caption,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32),
        PlatformElevatedButton(
          material: (_, __) =>
              MaterialElevatedButtonData(icon: Icon(Icons.done)),
          child: Text(S.of(context).i_see),
          onPressed: () {
            Navigator.pop(state.context);
          },
        )
      ],
    );
  }
}

/// EmailProvider is to provide an email list for user in [OTEmailSelectionWidget].
///
/// If return null, the corresponding [ListView] will be hidden.
abstract class EmailProvider {
  String? getRecommendedEmailList(PersonInfo info);

  List<String> getOptionalEmailList(PersonInfo info);
}

class EmailProviderImpl extends EmailProvider {
  @override
  List<String> getOptionalEmailList(PersonInfo info) {
    List<String> emailList = [];
    switch (info.group) {
      case UserGroup.FUDAN_UNDERGRADUATE_STUDENT:
      case UserGroup.FUDAN_POSTGRADUATE_STUDENT:
        if (info.id!.length >= 2) {
          int year = int.tryParse(info.id!.substring(0, 2)) ?? 0;
          if (year >= 21) {
            emailList.add(info.id! + "@fudan.edu.cn");
          } else {
            emailList.add(info.id! + "@m.fudan.edu.cn");
          }
        }
        break;
      case UserGroup.VISITOR:
      case UserGroup.FUDAN_STAFF:
      case UserGroup.SJTU_STUDENT:
        break;
    }
    return emailList;
  }

  @override
  String? getRecommendedEmailList(PersonInfo info) {
    switch (info.group) {
      case UserGroup.FUDAN_UNDERGRADUATE_STUDENT:
      case UserGroup.FUDAN_POSTGRADUATE_STUDENT:
        if (info.id!.length >= 2) {
          int year = int.tryParse(info.id!.substring(0, 2)) ?? 0;
          if (year >= 21) {
            return info.id! + "@m.fudan.edu.cn";
          } else {
            return info.id! + "@fudan.edu.cn";
          }
        }
        break;
      case UserGroup.VISITOR:
      case UserGroup.FUDAN_STAFF:
      case UserGroup.SJTU_STUDENT:
        break;
    }
    return null;
  }
}

class LoginInfoModel {
  String? selectedEmail;
  String? password;
  String? verifyCode;
}
