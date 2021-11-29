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
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/viewport_utils.dart';
import 'package:dan_xi/widget/opentreehole/login_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// OpenTreeHole Login Wizard UI
///
class HoleLoginPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  @override
  _HoleLoginPageState createState() => _HoleLoginPageState();

  HoleLoginPage({Key? key, this.arguments}) : super(key: key);
}

class _HoleLoginPageState extends State<HoleLoginPage> {
  late Widget _currentWidget;
  late PersonInfo info;
  List<Widget> _widgetStack = [];

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

  void jumpTo(Widget nextWidget, {bool putInStack = true}) {
    setState(() {
      _currentWidget = nextWidget;
      if (putInStack) {
        _widgetStack.add(_currentWidget);
      }
    });
  }

  bool jumpBack() {
    if (_widgetStack.length <= 1) return false;
    _widgetStack.removeLast();
    setState(() {
      _currentWidget = _widgetStack.last;
      _backwardRun = 2;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !jumpBack(),
      child: PlatformScaffold(
          iosContentBottomPadding: false,
          iosContentPadding: false,
          body: SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              switchInCurve: Curves.ease,
              switchOutCurve: Curves.ease,
              transitionBuilder: (Widget child, Animation<double> animation) {
                var tween =
                    Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0));
                // reverse the animation if invoked jumpBack().
                if (_backwardRun > 0) {
                  tween =
                      Tween<Offset>(begin: Offset(-1, 0), end: Offset(0, 0));
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
          )),
    );
  }
}

abstract class SubStatelessWidget extends StatelessWidget {
  final _HoleLoginPageState state;

  const SubStatelessWidget({Key? key, required this.state}) : super(key: key);

  Widget buildContent(BuildContext context);

  @override
  Widget build(BuildContext context) {
    Size size = ViewportUtils.getMainNavigatorSize(context);
    return Container(
      color: Colors.white,
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
            "选择您的登录/注册方式",
            style: Theme.of(context).textTheme.headline6,
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 32,
          ),
          ListTile(
            title: Text("UIS 快捷注册/登录"),
            onTap: () => state.jumpTo(OTEmailSelectionWidget(
              state: state,
            )),
          ),
          Divider(),
          ListTile(
            title: Text("邮箱密码登录"),
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

  Future<void> checkEmailInfo(BuildContext context, String email) async {
    state.jumpTo(
        OTLoadingWidget(
          state: state,
        ),
        putInStack: false);
    String? result =
        await OpenTreeHoleRepository.getInstance().getVerifyCode(email);
    if (result == null) {
      // Registered
      state.jumpTo(OTEmailPasswordLoginWidget(
        state: state,
        initialEmail: email,
      ));
    } else {
      // Not registered
      state.jumpTo(OTRegisterLicenseWidget(result, state: state));
    }
  }

  @override
  Widget buildContent(BuildContext context) {
    List<String> suggestEmail = [
      "${state.info.id}@fudan.edu.cn",
      "${state.info.id}@m.fudan.edu.cn",
      "我的邮箱不在列表中"
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          "UIS 快捷注册/登录",
          style: Theme.of(context).textTheme.headline6,
          textAlign: TextAlign.center,
        ),
        Text(
          "从下面的选项中选择您的邮箱",
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
                    if (e == "我的邮箱不在列表中") {
                      String? email = await showPlatformDialog<String?>(
                          context: context,
                          builder: (cxt) {
                            TextEditingController controller =
                                new TextEditingController();
                            return PlatformAlertDialog(
                              title: Text("输入您的邮箱"),
                              content: TextField(
                                controller: controller,
                              ),
                              actions: [
                                PlatformDialogAction(
                                  child: Text("确认"),
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
                      if (email != null) {
                        checkEmailInfo(context, email).catchError((e) {
                          state.jumpTo(this);
                          Noticing.showNotice(state.context, "当前无法连接到服务器，请重试。");
                        });
                      }
                    } else {
                      checkEmailInfo(context, e).catchError((e) {
                        state.jumpTo(this);
                        Noticing.showNotice(state.context, "当前无法连接到服务器，请重试。");
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

  OTEmailPasswordLoginWidget(
      {Key? key, required _HoleLoginPageState state, String initialEmail = ""})
      : super(key: key, state: state) {
    _usernameController.text = initialEmail;
  }

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          "使用邮箱密码登录",
          style: Theme.of(context).textTheme.headline6,
          textAlign: TextAlign.center,
        ),
        Text(
          "输入您的 FDUHole 账号/密码",
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
            Navigator.of(context).pop(Credentials(
                _usernameController.text, _passwordController.text));
          },
        )
      ],
    );
  }
}

class OTLoadingWidget extends SubStatelessWidget {
  OTLoadingWidget({required _HoleLoginPageState state})
      : super(key: UniqueKey(), state: state);

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          "正在获取信息……",
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
  final String verifyCode;

  const OTRegisterLicenseWidget(this.verifyCode,
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
            "欢迎注册 FDUHole",
            style: Theme.of(context).textTheme.headline6,
            textAlign: TextAlign.center,
          ),
          Text(
            "您需要阅读并同意以下协议",
            style: Theme.of(context).textTheme.caption,
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 32,
          ),
          OTLicenseBody(state: state)
        ],
      ),
    );
  }
}

class OTLicenseBody extends StatefulWidget {
  final _HoleLoginPageState state;

  const OTLicenseBody({Key? key, required this.state}) : super(key: key);

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
              "我已阅读并同意《FDUHole 社区公约》",
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
          child: Text("注册"),
          onPressed: _agreed ? () {} : null,
        )
      ],
    );
  }
}
