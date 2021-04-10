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

import 'dart:async';

import 'package:catcher/catcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dan_xi/common/Secret.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/page/aao_notices.dart';
import 'package:dan_xi/page/bbs_editor.dart';
import 'package:dan_xi/page/bbs_post.dart';
import 'package:dan_xi/page/card_detail.dart';
import 'package:dan_xi/page/card_traffic.dart';
import 'package:dan_xi/page/open_source_license.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/page/subpage_bbs.dart';
import 'package:dan_xi/page/subpage_settings.dart';
import 'package:dan_xi/page/subpage_main.dart';
import 'package:dan_xi/page/subpage_timetable.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/uis_login_tool.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/screen_proxy.dart';
import 'package:dan_xi/widget/login_dialog/login_dialog.dart';
import 'package:dan_xi/widget/qr_code_dialog/qr_code_dialog.dart';
import 'package:data_plugin/bmob/bmob.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'generated/l10n.dart';

final QuickActions quickActions = QuickActions();

void main() {
  CatcherOptions debugOptions = CatcherOptions(PageReportMode(), [
    ConsoleHandler()
  ], localizationOptions: [
    LocalizationOptions.buildDefaultEnglishOptions(),
    LocalizationOptions.buildDefaultChineseOptions(),
  ]);
  Bmob.init("https://api2.bmob.cn", Secret.APP_ID, Secret.API_KEY);
  Catcher(
      rootWidget: DanxiApp(),
      debugConfig: debugOptions,
      releaseConfig: debugOptions);
}

class DanxiApp extends StatelessWidget {
  /// Routes to every pages.
  final Map<String, Function> routes = {
    '/card/detail': (context, {arguments}) =>
        CardDetailPage(arguments: arguments),
    '/card/crowdData': (context, {arguments}) =>
        CardCrowdData(arguments: arguments),
    '/bbs/postDetail': (context, {arguments}) =>
        BBSPostDetail(arguments: arguments),
    '/bbs/newPost': (context, {arguments}) =>
        BBSEditorPage(arguments: arguments),
    '/notice/aao/list': (context, {arguments}) =>
        AAONoticesList(arguments: arguments),
    '/about/openLicense': (context, {arguments}) =>
        OpenSourceLicenseList(arguments: arguments),
  };

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => PlatformProvider(
      // initialPlatform: TargetPlatform.iOS,
      builder: (BuildContext context) => PlatformApp(
            title: "DanXi",
            cupertino: (_, __) => CupertinoAppData(
                theme: CupertinoThemeData(brightness: Brightness.light)),
            material: (_, __) => MaterialAppData(
                theme: ThemeData(
                  brightness: Brightness.light,
                  primarySwatch: Colors.deepPurple,
                ),
                darkTheme: ThemeData(
                  brightness: Brightness.dark,
                  bottomNavigationBarTheme: BottomNavigationBarThemeData(
                      selectedIconTheme: IconThemeData(color: Colors.white),
                      unselectedIconTheme: IconThemeData(color: Colors.white),
                      selectedItemColor: Colors.white,
                      unselectedItemColor: Colors.white),
                  textTheme: new TextTheme(
                    bodyText2: new TextStyle(color: Colors.red),
                    headline1: new TextStyle(fontSize: 78),
                    button: new TextStyle(color: Colors.green),
                  ),
                )),
            localizationsDelegates: [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate
            ],
            supportedLocales: S.delegate.supportedLocales,
            home: HomePage(),
            onGenerateRoute: (settings) {
              final Function pageContentBuilder = this.routes[settings.name];
              if (pageContentBuilder != null) {
                return platformPageRoute(
                    context: context,
                    builder: (context) => pageContentBuilder(context,
                        arguments: settings.arguments));
              }
              return null;
            },
            navigatorKey: Catcher.navigatorKey,
          ));
}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SharedPreferences _preferences;

  ValueNotifier<PersonInfo> _personInfo = ValueNotifier(null);

  /// A description for current connection status.
  ValueNotifier<String> _connectStatus = ValueNotifier("");

  /// Listener to connectivity changes.
  StreamSubscription<ConnectivityResult> _connectivitySubscription;

  /// Listener to the failure of logging in caused by necessary captcha.
  ///
  /// Request user to log in manually in the browser.
  StreamSubscription<CaptchaNeededException> _captchaSubscription;
  bool _isDialogShown = false;

  ValueNotifier<int> _pageIndex = ValueNotifier(0);

  /// List of all of the subpages. They will be displayed as tab pages.
  List<PlatformSubpage> _subpage = [
    HomeSubpage(),
    BBSSubpage(),
    TimetableSubPage(),
    SettingsSubpage()
  ];

  /// Force app to refresh pages.
  void _rebuildPage() {
    _subpage = [
      HomeSubpage(),
      BBSSubpage(),
      TimetableSubPage(),
      SettingsSubpage()
    ];
  }

  /// List of all of the subpages' action button icon. They will show on the appbar of each tab page.
  final List<Function> _subpageActionButtonIconBuilders = [
    (cxt) => null,
    (cxt) =>
        PlatformX.isAndroid ? PlatformIcons(cxt).add : SFSymbols.plus_circle,
    (cxt) => PlatformX.isAndroid ? Icons.share : SFSymbols.square_arrow_up,
    (cxt) => null  //TODO: is a stub
  ];

  /// List of all of the subpage action buttons' description. They will show on the appbar of each tab page.
  final List<Function> _subpageActionButtonTextBuilders = [
    (cxt) => null,
    (cxt) => S.of(cxt).new_post,
    (cxt) => S.of(cxt).share,
    (cxt) => null, //TODO: is a stub
  ];

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _connectivitySubscription = null;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    /* Listening to the network state.
    _connectivitySubscription = WiFiUtils.getConnectivity()
        .onConnectivityChanged
        .listen((_) => _loadNetworkState());
     */

    // Refresh the page when account changes.
    _personInfo.addListener(() {
      _rebuildPage();
      refreshSelf();
    });
    _captchaSubscription =
        Constant.eventBus.on<CaptchaNeededException>().listen((_) {
      // Deal with login issue described at [CaptchaNeededException].
      if (!_isDialogShown) {
        _isDialogShown = true;
        showPlatformDialog(
            barrierDismissible: false,
            context: context,
            builder: (_) => PlatformAlertDialog(
                  title: Text(S.of(context).fatal_error),
                  content: Text(S.of(context).login_issue_1),
                  actions: [
                    PlatformDialogAction(
                      child: Text(S.of(context).cancel),
                      onPressed: () {
                        _isDialogShown = false;
                        Navigator.of(context).pop();
                      },
                    ),
                    PlatformDialogAction(
                      child: Text(S.of(context).login_issue_1_action),
                      onPressed: () {
                        _isDialogShown = false;
                        Navigator.of(context).pop();
                        launch(Constant.UIS_URL);
                      },
                    ),
                  ],
                ));
      }
    });
    _loadOrInitSharedPreference().then((_) {
      // Configure shortcut listeners on Android & iOS.
      if (PlatformX.isMobile)
        quickActions.initialize((shortcutType) {
          if (shortcutType == 'action_qr_code' && _personInfo != null) {
            QR.showQRCode(context, _personInfo.value, _brightness);
          }
        });
    });
    //_loadNetworkState();
    // Add shortcuts on Android & iOS.
    if (PlatformX.isMobile)
      quickActions.setShortcutItems(<ShortcutItem>[
        ShortcutItem(
            type: 'action_qr_code',
            localizedTitle: S.current.fudan_qr_code,
            icon: 'ic_launcher'),
      ]);
    initPlatformState(); //Init brightness control

    //Init watchOS support
    const channel_a = const MethodChannel('watchAppActivated');
    channel_a.setMethodCallHandler((MethodCall call) async {
      print("received method call\n\n");
      if (call.method == 'watchActivated') {
        QR.sendQRtoWatch(_personInfo.value);
      }
    });
  }

  /// Current brightness
  double _brightness = 1.0;

  /// get current brightness so that we can restore it after showing QR code.
  initPlatformState() async {
    _brightness = await ScreenProxy.brightness;
  }

  /// Pop up a dialog where user can give his name & password.
  void _showLoginDialog({bool forceLogin = false}) => showPlatformDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoginDialog(
          sharedPreferences: _preferences,
          personInfo: _personInfo,
          forceLogin: forceLogin));

  /// Load persistent data (e.g. user name, password, etc.) from the local storage.
  ///
  /// If user hasn't logged in before, request him to do so.
  Future<void> _loadOrInitSharedPreference({bool forceLogin = false}) async {
    _preferences = await SharedPreferences.getInstance();

    if (!forceLogin && _preferences.containsKey("id")) {
      setState(() =>
          _personInfo.value = PersonInfo.fromSharedPreferences(_preferences));
    } else {
      _showLoginDialog(forceLogin: forceLogin);
    }
  }

  /* Load network ssid
  Future<void> _loadNetworkState() async {
    ConnectivityResult connectivity =
        await WiFiUtils.getConnectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.wifi) {
      Map<String, String> result =
          await WiFiUtils.getWiFiInfo(connectivity).catchError((_) => null);
      setState(() => _connectStatus.value =
          result == null || result['name'] == null
              ? S.current.current_connection_failed
              : FDUWiFiConverter.recognizeWiFi(result['name']));
    } else {
      setState(() =>
          _connectStatus.value = S.of(context).current_connection_no_wifi);
    }
  }
  */

  /// When user clicks the action button on appbar
  void _onPressActionButton() async {
    switch (_pageIndex.value) {
      case 0:
        //await loadOrInitSharedPreference(forceLogin: true);
        break;
      case 1:
        AddNewPostEvent().fire();
        break;
      case 2:
        ShareTimetableEvent().fire();
        break;
      case 3: //TODO: is a stub
        //ShareTimetableEvent().fire();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    print("rebuild!");
    return _personInfo.value == null
        // Empty container if no person info is set
        ? PlatformScaffold(
            iosContentBottomPadding: true,
            iosContentPadding: true,
            appBar: PlatformAppBar(
              title: Text(S.of(context).app_name),
              trailingActions: [
                PlatformIconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(_subpageActionButtonIconBuilders[_pageIndex.value](
                context)),
            onPressed: _onPressActionButton,
          )
        ],
      ),
      body: Container(),
    )
        : PlatformScaffold(
      iosContentBottomPadding: true,
      iosContentPadding: _subpage[_pageIndex.value].needPadding,
      appBar: PlatformAppBar(
        title: Text(
          S.of(context).app_name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailingActions: [
          PlatformIconButton(
            material: (_, __) => MaterialIconButtonData(
                tooltip:
                _subpageActionButtonTextBuilders[_pageIndex.value](
                    context)),
            padding: EdgeInsets.zero,
            icon: Icon(_subpageActionButtonIconBuilders[_pageIndex.value](
                context)),
            onPressed: _onPressActionButton,
          )
        ],
      ),
      body: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _pageIndex),
          ChangeNotifierProvider.value(value: _connectStatus),
          ChangeNotifierProvider.value(value: _personInfo),
        ],
        child: IndexedStack(index: _pageIndex.value, children: _subpage),
      ),
      bottomNavBar: PlatformNavBar(
        items: [
          BottomNavigationBarItem(
            backgroundColor: Colors.purple,
            icon: PlatformX.isAndroid
                ? Icon(Icons.dashboard)
                : Icon(SFSymbols.square_stack_3d_up_fill),
            label: S.of(context).dashboard,
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.indigo,
            icon: PlatformX.isAndroid
                ? Icon(Icons.forum)
                : Icon(SFSymbols.text_bubble),
            label: S.of(context).forum,
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.blue,
            icon: PlatformX.isAndroid
                ? Icon(Icons.calendar_today)
                : Icon(SFSymbols.calendar),
            label: S.of(context).timetable,
          ),
          BottomNavigationBarItem(
            backgroundColor: Colors.blue, //TODO: Change Color
            icon: PlatformX.isAndroid
                ? Icon(Icons.settings)
                : Icon(SFSymbols.gear_alt), //TODO: Change Icon
            label: S.of(context).settings,
          ),
        ],
        currentIndex: _pageIndex.value,
        material: (_, __) => MaterialNavBarData(
          type: BottomNavigationBarType.shifting,
          selectedIconTheme:
          BottomNavigationBarTheme.of(context).selectedIconTheme,
          unselectedIconTheme:
          BottomNavigationBarTheme.of(context).unselectedIconTheme,
        ),
        itemChanged: (index) {
          if (index != _pageIndex.value) {
            setState(() => _pageIndex.value = index);
          }
        },
      ),
    );
  }
}
