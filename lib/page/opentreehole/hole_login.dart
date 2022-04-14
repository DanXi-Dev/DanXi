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

import 'package:clipboard/clipboard.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/animation.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/viewport_utils.dart';
import 'package:dan_xi/widget/libraries/material_x.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';

/// OpenTreeHole login wizard page.
///
class HoleLoginPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  @override
  _HoleLoginPageState createState() => _HoleLoginPageState();

  const HoleLoginPage({Key? key, this.arguments}) : super(key: key);
}

class _HoleLoginPageState extends State<HoleLoginPage> {
  late SubStatelessWidget _currentWidget;
  late PersonInfo info;
  LoginInfoModel model = LoginInfoModel();
  final List<SubStatelessWidget> _widgetStack = [];

  /// Indicate the next [_backwardRun] animation should run in the reverse direction,
  /// since we are going back to the previous page.
  int _backwardRun = 0;

  @override
  void initState() {
    super.initState();
    info = widget.arguments!["info"];
    _currentWidget = OTLoginMethodSelectionWidget(state: this);
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
        if (_widgetStack.isNotEmpty && !_widgetStack.last.backable) {
          return false;
        }
        return !jumpBackIgnoringBackable();
      },
      child: Provider<LoginInfoModel>(
        create: (BuildContext context) => model,
        child: PlatformScaffold(
            material: (_, __) =>
                MaterialScaffoldData(resizeToAvoidBottomInset: false),
            cupertino: (_, __) =>
                CupertinoPageScaffoldData(resizeToAvoidBottomInset: false),
            iosContentBottomPadding: false,
            iosContentPadding: false,
            body: SafeArea(
              child: Material(
                child: AnimatedSwitcher(
                  switchInCurve: Curves.ease,
                  switchOutCurve: Curves.ease,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    var tween = Tween<Offset>(
                        begin: const Offset(1, 0), end: const Offset(0, 0));
                    // reverse the animation if invoked jumpBack().
                    if (_backwardRun > 0) {
                      tween = Tween<Offset>(
                          begin: const Offset(-1, 0), end: const Offset(0, 0));
                      _backwardRun--;
                    }
                    return MySlideTransition(
                      position: tween.animate(animation),
                      child: child,
                    );
                  },
                  duration: const Duration(milliseconds: 250),
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
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.1, vertical: size.height * 0.1),
        child: Container(
          decoration: ShapeDecoration(
              color: Colors.transparent,
              shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey, width: 0.5),
                  borderRadius: BorderRadius.circular(4))),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (backable) const ThemedMaterial(child: BackButton()),
                buildContent(context),
              ],
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
          const SizedBox(
            height: 32,
          ),
          ListTile(
            title: Text(S.of(context).fudan_uis_quick_login),
            onTap: () => state.jumpTo(OTEmailSelectionWidget(
              state: state,
            )),
          ),
          const Divider(),
          ListTile(
            title: Text(S.of(context).login_by_email_password),
            onTap: () => state.jumpTo(OTEmailPasswordLoginWidget(
              state: state,
            )),
          ),
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
    state.jumpTo(OTLoadingWidget(state: state), putInStack: false);
    bool? registered =
        await OpenTreeHoleRepository.getInstance().checkRegisterStatus(email);
    if (registered!) {
      state.jumpTo(OTEmailPasswordLoginWidget(state: state));
    } else {
      if (isRecommendedEmail) {
        model.verifyCode =
            await OpenTreeHoleRepository.getInstance().getVerifyCode(email);
        state.jumpTo(OTSetPasswordWidget(state: state));
      } else {
        model.verifyCode = null;
        state.jumpTo(OTSetPasswordWidget(state: state));
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
        const SizedBox(
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
                              TextEditingController();
                          return PlatformAlertDialog(
                            title: Text(S.of(context).input_your_email),
                            content: PlatformTextField(controller: controller),
                            actions: [
                              PlatformDialogAction(
                                  child: Text(S.of(context).i_see),
                                  onPressed: () {
                                    if (controller.text.trim().isNotEmpty) {
                                      Navigator.pop(
                                          cxt, controller.text.trim());
                                    }
                                  }),
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
                        .catchError((e, st) {
                      state.jumpBackFromLoadingPage();
                      Noticing.showErrorDialog(state.context, e, trace: st);
                    });
                  }
                }))
            .toList()
            .joinElement(() => const Divider())!
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
    void _doLogin() {
      model.selectedEmail = _usernameController.text;
      model.password = _passwordController.text;
      if (_passwordController.text.isNotEmpty &&
          _usernameController.text.isNotEmpty) {
        executeLogin(context).catchError((e, st) {
          state.jumpBackFromLoadingPage();
          Noticing.showErrorDialog(state.context, e, trace: st);
        });
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Image.asset("assets/graphics/ot_logo.png"),
        const SizedBox(height: 8),
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
        const SizedBox(
          height: 32,
        ),
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(
              labelText: S.of(context).email,
              icon: PlatformX.isMaterial(context)
                  ? const Icon(Icons.perm_identity)
                  : const Icon(CupertinoIcons.person_crop_circle)),
        ),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: S.of(context).password,
            icon: PlatformX.isMaterial(context)
                ? const Icon(Icons.lock_outline)
                : const Icon(CupertinoIcons.lock_circle),
          ),
          onSubmitted: (_) => _doLogin(),
        ),
        const SizedBox(height: 16),
        Text(
          S.of(context).tip_that_fduhole_is_not_fdu,
          style: Theme.of(context).textTheme.caption,
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.spaceAround,
          children: [
            PlatformTextButton(
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(S.of(context).forgot_password)),
              onPressed: () => BrowserUtil.openUrl(
                  Constant.OPEN_TREEHOLE_FORGOT_PASSWORD_URL, context),
            ),
            PlatformElevatedButton(
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(S.of(context).login)),
              onPressed: _doLogin,
            ),
          ],
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
        const SizedBox(
          height: 32,
        ),
        Center(
          child: PlatformCircularProgressIndicator(),
        )
      ],
    );
  }
}

class OTSetPasswordWidget extends SubStatelessWidget {
  final TextEditingController _passwordController = TextEditingController();

  OTSetPasswordWidget({Key? key, required _HoleLoginPageState state})
      : super(key: key, state: state);

  @override
  Widget buildContent(BuildContext context) {
    final model = Provider.of<LoginInfoModel>(context, listen: false);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          S.of(context).set_password,
          style: Theme.of(context).textTheme.headline6,
          textAlign: TextAlign.center,
        ),
        Text(
          S.of(context).set_your_fduhole_password,
          style: Theme.of(context).textTheme.caption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: S.of(context).password,
            icon: PlatformX.isMaterial(context)
                ? const Icon(Icons.lock_outline)
                : const Icon(CupertinoIcons.lock_circle),
          ),
        ),
        const SizedBox(height: 16),
        PlatformElevatedButton(
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(S.of(context).next)),
          onPressed: () {
            model.password = _passwordController.text;
            if (_passwordController.text.isNotEmpty) {
              state.jumpTo(OTRegisterLicenseWidget(state: state));
            }
          },
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
    await OpenTreeHoleRepository.getInstance()
        .register(model.selectedEmail!, model.password!, model.verifyCode!);
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
          const SizedBox(height: 32),
          OTLicenseBody(
            registerCallback: () {
              executeRegister(context, state).catchError((e, st) {
                state.jumpBackFromLoadingPage();
                Noticing.showErrorDialog(state.context, e, trace: st);
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
            onChanged: (newValue) {
              setState(() {
                _agreed = newValue!;
                if (_agreed) {
                  BrowserUtil.openUrl(
                      "https://www.fduhole.com/#/license", context);
                }
              });
            }),
        PlatformElevatedButton(
          material: (_, __) => MaterialElevatedButtonData(
              icon: const Icon(Icons.app_registration)),
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
          S.of(context).secure_verification,
          style: Theme.of(context).textTheme.headline6,
          textAlign: TextAlign.center,
        ),
        Text(
          S.of(context).input_your_email_secure_code,
          style: Theme.of(context).textTheme.caption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Text(S.of(context).secure_verification_description),
        const SizedBox(height: 8),
        TextField(
          controller: _verifyCodeController,
          decoration: InputDecoration(
              labelText: S.of(context).secure_code,
              icon: PlatformX.isMaterial(context)
                  ? const Icon(Icons.perm_identity)
                  : const Icon(CupertinoIcons.person_crop_circle)),
        ),
        const SizedBox(height: 16),
        PlatformElevatedButton(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(S.of(context).next),
          ),
          onPressed: () {
            model.verifyCode = _verifyCodeController.text;
            if (_verifyCodeController.text.isNotEmpty) {
              OTRegisterLicenseWidget.executeRegister(context, state)
                  .catchError((e, st) {
                state.jumpBackFromLoadingPage();
                Noticing.showErrorDialog(state.context, e, trace: st);
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

  const OTRegisterSuccessWidget({Key? key, required _HoleLoginPageState state})
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
        const SizedBox(height: 32),
        Text(
          S.of(context).email,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(model.selectedEmail!),
        const SizedBox(height: 8),
        Text(
          S.of(context).password,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(model.password!),
        const SizedBox(height: 16),
        Column(
          children: [
            PlatformTextButton(
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(S.of(context).copy_password)),
              onPressed: () async {
                await FlutterClipboard.copy(model.password!);
                if (PlatformX.isMaterial(context)) {
                  await Noticing.showNotice(
                      context, S.of(context).copy_success);
                }
              },
            ),
            PlatformElevatedButton(
              material: (_, __) =>
                  MaterialElevatedButtonData(icon: const Icon(Icons.done)),
              child: Text(S.of(context).i_see),
              onPressed: () {
                Navigator.pop(state.context);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class OTLoginSuccessWidget extends SubStatelessWidget {
  @override
  final bool backable = false;

  const OTLoginSuccessWidget({Key? key, required _HoleLoginPageState state})
      : super(key: key, state: state);

  @override
  Widget buildContent(BuildContext context) {
    //var model = Provider.of<LoginInfoModel>(context, listen: false);
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
        const SizedBox(height: 32),
        PlatformElevatedButton(
          material: (_, __) =>
              MaterialElevatedButtonData(icon: const Icon(Icons.done)),
          child: Text(S.of(context).i_see),
          onPressed: () => Navigator.pop(state.context),
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
