import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/widget/dialogs/login_dialog.dart';
import 'package:flutter/material.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Color _primary = const Color(0xFF5660C9);
  final Color _tint = const Color(0xFFE7E9FC);

  @override
  Widget build(BuildContext context) {
    final bool forumLoggedIn =
        context.watch<SettingsProvider>().forumToken != null;

    return ValueListenableBuilder<dynamic>(
      valueListenable: StateProvider.personInfo,
      builder: (context, personInfo, child) {
        final bool uisLoggedIn = personInfo != null;
        final bool canEnter = uisLoggedIn || forumLoggedIn;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6FF),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _loginCard(
                        title: S.of(context).login_uis,
                        subtitle: S.of(context).identity_service,
                        logged: uisLoggedIn,
                        buttons: [
                          _gradientBtn(
                            label: S.of(context).login_undergraduate,
                            tint: _primary,
                            enabled: !uisLoggedIn,
                            onTap: () => LoginDialog.showLoginDialog(
                                context,
                                SettingsProvider.getInstance().preferences,
                                StateProvider.personInfo,
                                true,
                                showFullOptions: false),
                          ),
                          _gradientBtn(
                            label: S.of(context).login_postgraduate,
                            tint: _primary,
                            enabled: !uisLoggedIn,
                            onTap: () => LoginDialog.showLoginDialog(
                                context,
                                SettingsProvider.getInstance().preferences,
                                StateProvider.personInfo,
                                true,
                                showFullOptions: false,
                                isGraduate: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _loginCard(
                        title: S.of(context).login_danta_account,
                        subtitle: S.of(context).login_danta_community,
                        logged: forumLoggedIn,
                        buttons: [
                          _gradientBtn(
                            label: S.of(context).login_by_email_password,
                            tint: _primary,
                            enabled: !forumLoggedIn,
                            onTap: () async {
                              await smartNavigatorPush(context, "/bbs/login",
                                  arguments: {
                                    "info": StateProvider.personInfo.value
                                  });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text.rich(
                      TextSpan(
                        text: S.of(context).login_agreement,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: GestureDetector(
                              onTap: () {
                                BrowserUtil.openUrl(
                                    Constant.TERMS_AND_CONDITIONS_URL, context);
                              },
                              child: Text(
                                S.of(context).terms_and_privacy,
                                style: const TextStyle(
                                  fontSize: 12,
                                  // color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: FilledButton(
                    onPressed: canEnter
                        ? () {
                            SettingsProvider.getInstance().isLoggedIn = true;
                            StateProvider.isLoggedIn.value = true;
                            showFAQ();
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: canEnter ? _primary : _tint,
                      foregroundColor: canEnter ? Colors.white : Colors.black38,
                      disabledBackgroundColor: _tint,
                    ),
                    child: Text(S.of(context).enter_app,
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _loginCard({
    required String title,
    required String subtitle,
    required List<Widget> buttons,
    required bool logged,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                if (logged) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, color: Colors.green, size: 22),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              logged ? S.of(context).logged_in : subtitle,
              style: TextStyle(
                color: logged ? Colors.green : Colors.black54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ..._interleave(buttons, const SizedBox(height: 14)),
          ],
        ),
      ),
    );
  }

  Widget _gradientBtn({
    required String label,
    required VoidCallback? onTap,
    required bool enabled,
    Color? tint,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: onTap,
      child: Ink(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: enabled
              ? LinearGradient(
                  colors: [
                    tint ?? _tint,
                    tint != null ? tint.withOpacity(0.8) : _tint,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: enabled ? null : _tint,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? Colors.white : Colors.black38,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _interleave(List<Widget> children, Widget separator) {
    if (children.isEmpty) return [];
    final List<Widget> output = [];
    for (var i = 0; i < children.length; i++) {
      output.add(children[i]);
      if (i != children.length - 1) output.add(separator);
    }
    return output;
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
}
