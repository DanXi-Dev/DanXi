/*
 *     Copyright (C) 2021 kavinzhao
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

import 'dart:ui';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/page/open_source_license.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/page/subpage_main.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/login_dialog/login_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

class SettingsSubpage extends PlatformSubpage {
  @override
  bool get needPadding => true;

  @override
  bool get needBottomPadding => true;

  @override
  _SettingsSubpageState createState() => _SettingsSubpageState();

  SettingsSubpage({Key key});
}

class _SettingsSubpageState extends State<SettingsSubpage> {
  /// All open-source license for the app.
  static const List<LicenseItem> _LICENSE_ITEMS = [
    LicenseItem("asn1lib", LICENSE_BSD, "https://github.com/wstrange/asn1lib"),
    LicenseItem("auto_size_text", LICENSE_MIT,
        "hhttps://github.com/leisim/auto_size_text"),
    LicenseItem("beautifulsoup", LICENSE_APACHE_2_0,
        "https://github.com/Sach97/beautifulsoup.dart"),
    LicenseItem("build_runner", LICENSE_BSD,
        "https://github.com/dart-lang/build/tree/master/build_runner"),
    LicenseItem(
        "catcher", LICENSE_APACHE_2_0, "https://github.com/jhomlala/catcher"),
    LicenseItem("cupertino_icons", LICENSE_MIT,
        "https://github.com/flutter/cupertino_icons"),
    LicenseItem("desktop_window", LICENSE_MIT,
        "https://github.com/mix1009/desktop_window"),
    LicenseItem("dio", LICENSE_MIT, "https://github.com/flutterchina/dio"),
    LicenseItem("dio_cookie_manager", LICENSE_MIT,
        "https://github.com/flutterchina/dio"),
    LicenseItem(
        "EFQRCode", LICENSE_MIT, "https://github.com/EFPrefix/EFQRCode"),
    LicenseItem("event_bus", LICENSE_MIT,
        "https://github.com/marcojakob/dart-event-bus"),
    LicenseItem("flutter", LICENSE_BSD_3_0_CLAUSE,
        "https://github.com/flutter/flutter"),
    LicenseItem("flutter_email_sender", LICENSE_APACHE_2_0,
        "https://github.com/sidlatau/flutter_email_sender"),
    LicenseItem("flutter_inappwebview", LICENSE_APACHE_2_0,
        "https://github.com/pichillilorenzo/flutter_inappwebview"),
    LicenseItem("flutter_localizations", LICENSE_BSD_3_0_CLAUSE,
        "https://api.flutter.dev/flutter/flutter_localizations/flutter_localizations-library.html"),
    LicenseItem("flutter_phoenix", LICENSE_MIT,
        "https://github.com/mobiten/flutter_phoenix"),
    LicenseItem("flutter_platform_widgets", LICENSE_MIT,
        "https://github.com/stryder-dev/flutter_platform_widgets"),
    LicenseItem("flutter_progress_dialog", LICENSE_APACHE_2_0,
        "https://github.com/wuzhendev/flutter_progress_dialog"),
    LicenseItem("flutter_sfsymbols", LICENSE_APACHE_2_0,
        "https://github.com/virskor/flutter_sfsymbols"),
    LicenseItem("flutter_test", LICENSE_BSD_3_0_CLAUSE,
        "https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html"),
    LicenseItem("flutter_timetable_view", LICENSE_MIT,
        "https://github.com/yamarkz/flutter_timetable_view"),
    LicenseItem("flutter_widget_from_html_core", LICENSE_MIT,
        "https://github.com/daohoangson/flutter_widget_from_html"),
    LicenseItem("http", LICENSE_BSD, "https://github.com/dart-lang/http"),
    LicenseItem("ical", LICENSE_BSD, "https://github.com/dartclub/ical"),
    LicenseItem("intl", LICENSE_BSD, "https://github.com/dart-lang/intl"),
    LicenseItem("json_serializable", LICENSE_BSD,
        "https://github.com/google/json_serializable.dart/tree/master/json_serializable"),
    LicenseItem(
        "package_info", LICENSE_BSD, "https://github.com/flutter/plugins"),
    LicenseItem(
        "path_provider", LICENSE_BSD, "https://github.com/flutter/plugins"),
    LicenseItem("permission_handler", LICENSE_MIT,
        "https://github.com/baseflowit/flutter-permission-handler"),
    LicenseItem(
        "provider", LICENSE_MIT, "https://github.com/rrousselGit/provider"),
    LicenseItem(
        "qr_flutter", LICENSE_BSD, "https://github.com/theyakka/qr.flutter"),
    LicenseItem(
        "quick_actions", LICENSE_BSD, "https://github.com/flutter/plugins"),
    LicenseItem("screen", LICENSE_MIT,
        "https://github.com/clovisnicolas/flutter_screen"),
    LicenseItem("share", LICENSE_BSD, "https://github.com/flutter/plugins"),
    LicenseItem("shared_preferences", LICENSE_BSD,
        "https://github.com/flutter/plugins"),
    LicenseItem(
        "url_launcher", LICENSE_BSD, "https://github.com/flutter/plugins"),
  ];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _deleteAllDataAndExit() async {
    SharedPreferences _preferences = await SharedPreferences.getInstance();
    await _preferences.clear().then((value) => {Phoenix.rebirth(context)});
  }

  SharedPreferences _preferences;

  void initLogin({bool forceLogin = false}) {
    _showLoginDialog(forceLogin: forceLogin);
  }

  /// Pop up a dialog where user can give his name & password.
  void _showLoginDialog({bool forceLogin = false}) {
    ValueNotifier<PersonInfo> _infoNotifier =
        Provider.of<ValueNotifier<PersonInfo>>(context, listen: false);
    showPlatformDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => LoginDialog(
            sharedPreferences: _preferences,
            personInfo: _infoNotifier,
            forceLogin: forceLogin));
  }

  List<Widget> _buildCampusAreaList() {
    List<Widget> list = [];
    Function onTapListener = (Campus campus) {
      SettingsProvider.of(_preferences).campus = campus;
      Navigator.of(context).pop();
      RefreshHomepageEvent().fire();
      refreshSelf();
    };
    Constant.CAMPUS_VALUES.forEach((value) {
      list.add(PlatformWidget(
        cupertino: (_, __) => CupertinoActionSheetAction(
          onPressed: () => onTapListener(value),
          child: Text(value.displayTitle(context)),
        ),
        material: (_, __) => ListTile(
          title: Text(value.displayTitle(context)),
          onTap: () => onTapListener(value),
        ),
      ));
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    _preferences = Provider.of<SharedPreferences>(context);
    final Color _originalDividerColor = Theme.of(context).dividerColor;
    const double _avatarSpacing = 24;
    double _avatarSize =
        (MediaQuery.of(context).size.width - _avatarSpacing * 4 - 64) / 4;
    const double _avatarNameSpacing = 4;
    TextStyle defaultText = Theme.of(context).textTheme.bodyText2;
    TextStyle linkText = Theme.of(context)
        .textTheme
        .bodyText2
        .copyWith(color: Theme.of(context).accentColor);

    return RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          refreshSelf();
        },
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: ListView(padding: EdgeInsets.all(4), children: <Widget>[
            //Account Selection
            Card(
              child: Column(children: <Widget>[
                ListTile(
                  title: Text(S.of(context).account),
                  leading: PlatformX.isMaterial(context)
                      ? const Icon(Icons.account_circle)
                      : const Icon(SFSymbols.person_circle),
                  subtitle: Text(context.personInfo.name +
                      ' (' +
                      context.personInfo.id +
                      ')'),
                  onTap: () => initLogin(forceLogin: true),
                ),
                ListTile(
                  title: Text(S.of(context).logout),
                  leading: PlatformX.isMaterial(context)
                      ? const Icon(Icons.logout)
                      : const Icon(SFSymbols.trash),
                  subtitle: Text(S.of(context).logout_subtitle),
                  onTap: () {
                    showPlatformDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) => PlatformAlertDialog(
                        title: Text(S.of(context).logout_question_prompt_title),
                        content: Text(S.of(context).logout_question_prompt),
                        actions: [
                          PlatformDialogAction(
                            child: Text(S.of(context).cancel),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          PlatformDialogAction(
                              child: Text(S.of(context).i_see),
                              onPressed: () {
                                Navigator.of(context).pop();
                                _deleteAllDataAndExit();
                              })
                        ],
                      ),
                    );
                  },
                ),
              ]),
            ),

            //Campus Selection
            Card(
              child: ListTile(
                title: Text(S.of(context).default_campus),
                leading: PlatformX.isMaterial(context)
                    ? const Icon(Icons.location_on)
                    : const Icon(SFSymbols.location),
                subtitle: Text(SettingsProvider.of(_preferences)
                    .campus
                    .displayTitle(context)),
                onTap: () {
                  if (_preferences != null) {
                    showPlatformModalSheet(
                        context: context,
                        builder: (_) => PlatformWidget(
                              cupertino: (_, __) => CupertinoActionSheet(
                                title: Text(S.of(context).select_campus),
                                actions: _buildCampusAreaList(),
                                cancelButton: CupertinoActionSheetAction(
                                  child: Text(S.of(context).cancel),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                              material: (_, __) => Container(
                                height: 300,
                                child: Column(
                                  children: _buildCampusAreaList(),
                                ),
                              ),
                            ));
                  }
                },
              ),
            ),

            if (SettingsProvider.of(_preferences).debugMode)
              //Theme Selection
              Card(
                child: ListTile(
                  title: Text(S.of(context).theme),
                  leading: PlatformX.isMaterial(context)
                      ? const Icon(Icons.color_lens)
                      : const Icon(SFSymbols.color_filter),
                  subtitle: Text(PlatformX.isMaterial(context)
                      ? S.of(context).material
                      : S.of(context).cupertino),
                  onTap: () {
                    PlatformX.isMaterial(context)
                        ? PlatformProvider.of(context)
                            .changeToCupertinoPlatform()
                        : PlatformProvider.of(context)
                            .changeToMaterialPlatform();
                  },
                ),
              ),

            //About Page
            Card(
                child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                        leading: PlatformX.isMaterial(context)
                            ? const Icon(Icons.info)
                            : const Icon(SFSymbols.info_circle),
                        title: Text(S.of(context).about),
                        //subtitle: Text("Click to view"),
                        children: <Widget>[
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                padding: new EdgeInsets.fromLTRB(25, 5, 25, 0),
                                child: new Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        S.of(context).app_description_title,
                                        textScaleFactor: 1.1,
                                      ),
                                      Divider(
                                        color: _originalDividerColor,
                                      ),
                                      Text(S.of(context).app_description),
                                      const SizedBox(
                                        height: 16,
                                      ),

                                      //Terms and Conditions
                                      Text(
                                        S
                                            .of(context)
                                            .terms_and_conditions_title,
                                        textScaleFactor: 1.1,
                                      ),
                                      Divider(
                                        color: _originalDividerColor,
                                      ),
                                      RichText(
                                          text: TextSpan(children: [
                                        TextSpan(
                                          style: defaultText,
                                          text: S
                                              .of(context)
                                              .terms_and_conditions_content,
                                        ),
                                        TextSpan(
                                            style: linkText,
                                            text: S.of(context).privacy_policy,
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () async {
                                                await launch(S
                                                    .of(context)
                                                    .privacy_policy_url);
                                              }),
                                        TextSpan(
                                          style: defaultText,
                                          text: S
                                              .of(context)
                                              .terms_and_conditions_content_end,
                                        ),
                                        TextSpan(
                                          style: defaultText,
                                          text: S.of(context).view_ossl,
                                        ),
                                        TextSpan(
                                            style: linkText,
                                            text: S
                                                .of(context)
                                                .open_source_software_licenses,
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                Navigator.of(context).pushNamed(
                                                    "/about/openLicense",
                                                    arguments: {
                                                      "items": _LICENSE_ITEMS
                                                    });
                                              }),
                                      ])),

                                      const SizedBox(
                                        height: 16,
                                      ),

                                      //Acknowledgement
                                      Text(
                                        S.of(context).acknowledgements,
                                        textScaleFactor: 1.1,
                                      ),
                                      Divider(
                                        color: _originalDividerColor,
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      RichText(
                                          text: TextSpan(children: [
                                        TextSpan(
                                          style: defaultText,
                                          text:
                                              S.of(context).acknowledgements_1,
                                        ),
                                        TextSpan(
                                            style: linkText,
                                            text: S
                                                .of(context)
                                                .acknowledgement_name_1,
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () async {
                                                await launch(S
                                                    .of(context)
                                                    .acknowledgement_link_1);
                                              }),
                                        TextSpan(
                                          style: defaultText,
                                          text:
                                              S.of(context).acknowledgements_2,
                                        ),
                                      ])),

                                      const SizedBox(
                                        height: 16,
                                      ),

                                      // Authors
                                      Text(
                                        S.of(context).authors,
                                        textScaleFactor: 1.1,
                                      ),
                                      Divider(
                                        color: _originalDividerColor,
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              InkWell(
                                                child: Container(
                                                    width: _avatarSize,
                                                    height: _avatarSize,
                                                    decoration: new BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        image: new DecorationImage(
                                                            fit: BoxFit.fill,
                                                            image: new AssetImage(S
                                                                .of(context)
                                                                .dev_image_url_1)))),
                                                onTap: () => launch(
                                                    S.of(context).dev_page_1),
                                              ),
                                              const SizedBox(
                                                  height: _avatarNameSpacing),
                                              Text(
                                                S.of(context).dev_name_1,
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: _avatarSpacing),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              InkWell(
                                                child: Container(
                                                    width: _avatarSize,
                                                    height: _avatarSize,
                                                    decoration: new BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        image: new DecorationImage(
                                                            fit: BoxFit.fill,
                                                            image: new AssetImage(S
                                                                .of(context)
                                                                .dev_image_url_2)))),
                                                onTap: () => launch(
                                                    S.of(context).dev_page_2),
                                              ),
                                              const SizedBox(
                                                  height: _avatarNameSpacing),
                                              Text(
                                                S.of(context).dev_name_2,
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: _avatarSpacing),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              InkWell(
                                                child: Container(
                                                    width: _avatarSize,
                                                    height: _avatarSize,
                                                    decoration: new BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        image: new DecorationImage(
                                                            fit: BoxFit.fill,
                                                            image: new AssetImage(S
                                                                .of(context)
                                                                .dev_image_url_3)))),
                                                onTap: () {
                                                  launch(
                                                      S.of(context).dev_page_3);
                                                },
                                              ),
                                              const SizedBox(
                                                  height: _avatarNameSpacing),
                                              Text(
                                                S.of(context).dev_name_3,
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: _avatarSpacing),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              InkWell(
                                                child: Container(
                                                    width: _avatarSize,
                                                    height: _avatarSize,
                                                    decoration: new BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        image: new DecorationImage(
                                                            fit: BoxFit.fill,
                                                            image: new AssetImage(S
                                                                .of(context)
                                                                .dev_image_url_4)))),
                                                onTap: () {
                                                  launch(
                                                      S.of(context).dev_page_4);
                                                },
                                              ),
                                              const SizedBox(
                                                  height: _avatarNameSpacing),
                                              Text(
                                                S.of(context).dev_name_4,
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Text(
                                            S.of(context).author_descriptor,
                                            textScaleFactor: 0.7,
                                            textAlign: TextAlign.right,
                                            //style: TextStyle(fontStyle: FontStyle.italic)),
                                          )
                                        ],
                                      ),
                                    ]),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  TextButton(
                                    child: Text(S.of(context).contact_us),
                                    onPressed: () async {
                                      final Email email = Email(
                                        body: '',
                                        subject: S.of(context).app_feedback,
                                        recipients: [
                                          S.of(context).feedback_email
                                        ],
                                        isHTML: false,
                                      );

                                      await FlutterEmailSender.send(email);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    child: Text(S.of(context).project_page),
                                    onPressed: () {
                                      launch(S.of(context).project_url);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ],
                          ),
                        ]))),
          ]),
        ));
  }
}
