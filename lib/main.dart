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

import 'dart:async';

import 'package:catcher/catcher.dart';
import 'package:dan_xi/common/Secret.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/model/announcement.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/page/aao_notices.dart';
import 'package:dan_xi/page/announcement_notices.dart';
import 'package:dan_xi/page/bbs_editor.dart';
import 'package:dan_xi/page/bbs_post.dart';
import 'package:dan_xi/page/card_detail.dart';
import 'package:dan_xi/page/card_traffic.dart';
import 'package:dan_xi/page/empty_classroom_detail.dart';
import 'package:dan_xi/page/open_source_license.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/page/subpage_bbs.dart';
import 'package:dan_xi/page/subpage_main.dart';
import 'package:dan_xi/page/subpage_settings.dart';
import 'package:dan_xi/page/subpage_timetable.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/announcement_repository.dart';
import 'package:dan_xi/repository/uis_login_tool.dart';
import 'package:dan_xi/util/bmob/bmob/bmob.dart';
import 'package:dan_xi/util/firebase_handler.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/screen_proxy.dart';
import 'package:dan_xi/util/stream_listener.dart';
import 'package:dan_xi/widget/login_dialog/login_dialog.dart';
import 'package:dan_xi/widget/qr_code_dialog/qr_code_dialog.dart';
import 'package:dan_xi/widget/top_controller.dart';

import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'generated/l10n.dart';

final QuickActions quickActions = QuickActions();

void main() {
  // Config [Catcher] to catch uncaught exceptions.
  CatcherOptions debugOptions = CatcherOptions(SilentReportMode(), [
    FirebaseHandler(),
    ConsoleHandler()
  ], localizationOptions: [
    LocalizationOptions.buildDefaultEnglishOptions(),
    LocalizationOptions.buildDefaultChineseOptions(),
  ]);
  CatcherOptions releaseOptions = CatcherOptions(SilentReportMode(), [
    FirebaseHandler(),
    ConsoleHandler()
  ], localizationOptions: [
    LocalizationOptions.buildDefaultEnglishOptions(),
    LocalizationOptions.buildDefaultChineseOptions(),
  ]);
  WidgetsFlutterBinding.ensureInitialized();
  // Init Bmob database.
  Bmob.init("https://api2.bmob.cn", Secret.APP_ID, Secret.API_KEY);
  Catcher(
      rootWidget: DanxiApp(),
      debugConfig: debugOptions,
      releaseConfig: releaseOptions);
}

class DanxiApp extends StatelessWidget {
  /// Routes to every pages.
  final Map<String, Function> routes = {
    '/card/detail': (context, {arguments}) =>
        CardDetailPage(arguments: arguments),
    '/card/crowdData': (context, {arguments}) =>
        CardCrowdData(arguments: arguments),
    '/room/detail': (context, {arguments}) =>
        EmptyClassroomDetailPage(arguments: arguments),
    '/bbs/postDetail': (context, {arguments}) =>
        BBSPostDetail(arguments: arguments),
    '/bbs/newPost': (context, {arguments}) =>
        BBSEditorPage(arguments: arguments),
    '/notice/aao/list': (context, {arguments}) =>
        AAONoticesList(arguments: arguments),
    '/about/openLicense': (context, {arguments}) =>
        OpenSourceLicenseList(arguments: arguments),
    '/announcement/list': (context, {arguments}) =>
        AnnouncementList(arguments: arguments),
  };

  changeSizeOnDesktop() async {
    if (PlatformX.isDesktop) {
      await DesktopWindow.setWindowSize(Size(540, 960));
    }
  }

  ThemeData getTheme(BuildContext context) {
    return PlatformX.isDarkMode
        ? Constant.darkTheme(PlatformX.isCupertino(context))
        : Constant.lightTheme(PlatformX.isCupertino(context));
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    changeSizeOnDesktop();
    return Phoenix(
        child: PlatformProvider(
      // initialPlatform: TargetPlatform.iOS,
      builder: (BuildContext context) => Theme(
        data: getTheme(context),
        child: PlatformApp(
          title: 'Danxi',
          cupertino: (_, __) => CupertinoAppData(
              theme: CupertinoThemeData(
                  textTheme: CupertinoTextThemeData(
                      textStyle: TextStyle(
                          color:
                              getTheme(context).textTheme.bodyText1.color)))),
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
        ),
      ),
    ));
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  SharedPreferences _preferences;

  ValueNotifier<PersonInfo> _personInfo = ValueNotifier(null);

  /// A description for current connection status.
  ValueNotifier<String> _connectStatus = ValueNotifier("");

  /// Listener to the failure of logging in caused by necessary captcha.
  ///
  /// Request user to log in manually in the browser.
  StateStreamListener<CaptchaNeededException> _captchaSubscription =
      StateStreamListener();

  //Dark/Light Theme Control
  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
  }

  /// If we need to send the qr code to iWatch now.
  ///
  /// When notified [watchActivated], we should send it after [_personInfo] is loaded.
  bool _needSendToWatch = false;

  bool _isDialogShown = false;

  ValueNotifier<int> _pageIndex = ValueNotifier(0);

  /// List of all of the subpages. They will be displayed as tab pages.
  List<PlatformSubpage> _subpage = [];

  /// Force app to refresh pages.
  ///
  /// It's usually called when user changes his account.
  void _rebuildPage() {
    _subpage = [
      HomeSubpage(),
      BBSSubpage(),
      TimetableSubPage(),
      SettingsSubpage()
    ];
  }

  /// List of all of the subpages' action button icon. They will show on the appbar of each tab page.
  final List<Function> _subpageRightmostActionButtonIconBuilders = [
    (cxt) => PlatformX.isAndroid ? Icons.notifications : SFSymbols.bell_circle,
    (cxt) =>
        PlatformX.isAndroid ? PlatformIcons(cxt).add : SFSymbols.plus_circle,
    (cxt) => PlatformX.isAndroid ? Icons.share : SFSymbols.square_arrow_up,
    (cxt) => null
  ];

  final List<Function> _subpageRightsecondActionButtonIconBuilders = [
    (cxt) => null,
    (cxt) => null, //SFSymbols.search,
    (cxt) => null,
    (cxt) => null
  ];

  final List<Function> _subpageLeadingActionButtonIconBuilders = [
    (cxt) => null,
    (cxt) => SFSymbols.sort_down_circle,
    (cxt) => null,
    (cxt) => null
  ];

  /// List of all of the subpage action buttons' description. They will show on the appbar of each tab page.
  final List<Function> _subpageRightmostActionButtonTextBuilders = [
    (cxt) => S.of(cxt).developer_announcement(''),
    (cxt) => S.of(cxt).new_post,
    (cxt) => S.of(cxt).share,
    (cxt) => null,
  ];

  final List<Function> _subpageRightsecondActionButtonTextBuilders = [
    (cxt) => null,
    (cxt) => null, //S.of(cxt).new_post,
    (cxt) => null,
    (cxt) => null,
  ];

  final List<Function> _subpageLeadingActionButtonTextBuilders = [
    (cxt) => null,
    (cxt) => S.of(cxt).sort_order,
    (cxt) => null,
    (cxt) => null,
  ];

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _captchaSubscription.cancel();
    super.dispose();
  }

  /// Deal with login issue described at [CaptchaNeededException].
  _dealWithCaptchaNeededException() {
    if (_isDialogShown) {
      return;
    }
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

  DateTime _lastRefreshTime;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // After the app returns from the background
        // Refresh the homepage if it hasn't been refreshed for 30 minutes
        // To keep the data up-to-date.
        if (DateTime.now()
                .difference(_lastRefreshTime)
                .compareTo(Duration(minutes: 30)) >
            0) {
          _lastRefreshTime = DateTime.now();
          RefreshHomepageEvent().fire();
        }
        break;
      case AppLifecycleState.inactive:
        // Ignored
        break;
      case AppLifecycleState.paused:
        // Ignored
        break;
      case AppLifecycleState.detached:
        // Ignored
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    // Init for firebase services.
    FirebaseHandler.initFirebase();
    // Refresh the page when account changes.
    _personInfo.addListener(() {
      _rebuildPage();
      refreshSelf();
    });

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
      // This callback gets invoked every time brightness changes
      // TODO: What's wrong with this code? why does the app refresh on every launch?
      // The timer below is a workaround to the issue.
      Timer(Duration(milliseconds: 500), () {
        if (WidgetsBinding.instance.platformDispatcher.platformBrightness !=
            Theme.of(context).brightness) Phoenix.rebirth(context);
      });
    };

    _captchaSubscription.bindOnlyInvalid(
        Constant.eventBus
            .on<CaptchaNeededException>()
            .listen((_) => _dealWithCaptchaNeededException()),
        hashCode);

    // Load the latest announcement. Just ignore the network error.
    _loadAnnouncement().catchError((ignored) {});
    _loadOrInitSharedPreference().then((_) {
      // Configure shortcut listeners on Android & iOS.
      if (PlatformX.isMobile)
        quickActions.initialize((shortcutType) {
          if (shortcutType == 'action_qr_code' && _personInfo.value != null) {
            QRHelper.showQRCode(context, _personInfo.value, _brightness);
          }
        });
      // Configure watch listeners on iOS.
      if (_needSendToWatch && _personInfo.value != null) {
        QRHelper.sendQRtoWatch(_personInfo.value);
        // Only send once.
        _needSendToWatch = false;
      }
    });
    // Add shortcuts on Android & iOS.
    if (PlatformX.isMobile) {
      quickActions.setShortcutItems(<ShortcutItem>[
        ShortcutItem(
            type: 'action_qr_code',
            localizedTitle: S.current.fudan_qr_code,
            icon: 'ic_launcher'),
      ]);
    }
    _initPlatformState(); //Init brightness control

    // Init watchOS support
    const channel_a = const MethodChannel('watchAppActivated');
    channel_a.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'watchActivated') {
        // If we haven't loaded [_personInfo]
        if (_personInfo.value == null) {
          // Notify that we should send the qr code to watch later
          _needSendToWatch = true;
        } else {
          QRHelper.sendQRtoWatch(_personInfo.value);
        }
      }
    });
  }

  /// Current brightness
  double _brightness = 1.0;

  /// get current brightness so that we can restore it after showing QR code.
  _initPlatformState() async {
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

    if (!forceLogin && PersonInfo.verifySharedPreferences(_preferences)) {
      setState(() =>
          _personInfo.value = PersonInfo.fromSharedPreferences(_preferences));
    } else {
      _showLoginDialog(forceLogin: forceLogin);
    }
  }

  /// When user clicks the action button on appbar
  void _onPressRightmostActionButton() async {
    switch (_pageIndex.value) {
      case 0:
        Navigator.of(context).pushNamed('/announcement/list');
        break;
      case 1:
        AddNewPostEvent().fire();
        break;
      case 2:
        ShareTimetableEvent().fire();
        break;
    }
  }

  void _onPressRightsecondActionButton() async {
    /*switch (_pageIndex.value) {
      //Entries omitted
      case 1:
        AddNewPostEvent().fire();
        break;
    }*/
  }

  void _onPressLeadingActionButton() async {
    switch (_pageIndex.value) {
      //Entries omitted
      case 1:
        showPlatformModalSheet(
            context: context,
            builder: (_) => PlatformWidget(
                  cupertino: (_, __) => CupertinoActionSheet(
                    title: Text(S.of(context).sort_order),
                    actions: _buildSortOptionsList(),
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
                      children: _buildSortOptionsList(),
                    ),
                  ),
                ));
        break;
    }
  }

  List<Widget> _buildSortOptionsList() {
    List<Widget> list = [];
    Function onTapListener = (SortOrder newOrder) {
      Navigator.of(context).pop();
      SortOrderChangedEvent(newOrder).fire();
    };
    SortOrder.values.forEach((value) {
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
    _lastRefreshTime = DateTime.now();
    if (_personInfo.value == null) {
      // Show an empty container if no person info is set
      return PlatformScaffold(
        iosContentBottomPadding: false,
        iosContentPadding: true,
        appBar: PlatformAppBar(
          title: Text(S.of(context).app_name),
          trailingActions: [
            PlatformIconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                  _subpageRightmostActionButtonIconBuilders[_pageIndex.value](
                      context)),
              onPressed: _onPressRightmostActionButton,
            )
          ],
        ),
        body: Container(),
      );
    } else {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _pageIndex),
          ChangeNotifierProvider.value(value: _connectStatus),
          ChangeNotifierProvider.value(value: _personInfo),
          Provider.value(value: _preferences),
        ],
        child: PlatformScaffold(
          iosContentBottomPadding: _subpage[_pageIndex.value].needBottomPadding,
          iosContentPadding: _subpage[_pageIndex.value].needPadding,
          appBar: PlatformAppBar(
            cupertino: (_, __) => CupertinoNavigationBarData(
              title: MediaQuery(
                data: MediaQueryData(
                    textScaleFactor: MediaQuery.textScaleFactorOf(context)),
                child: TopController(
                  child: Text(
                    S.of(context).app_name,
                  ),
                  onDoubleTap: () => ScrollToTopEvent().fire(),
                ),
              ),
            ),
            material: (_, __) => MaterialAppBarData(
              title: TopController(
                child: Text(
                  S.of(context).app_name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onDoubleTap: () => ScrollToTopEvent().fire(),
              ),
            ),
            leading: PlatformIconButton(
              material: (_, __) => MaterialIconButtonData(
                  tooltip:
                      _subpageLeadingActionButtonTextBuilders[_pageIndex.value](
                          context)),
              padding: EdgeInsets.zero,
              icon: Icon(
                  _subpageLeadingActionButtonIconBuilders[_pageIndex.value](
                      context)),
              onPressed: _onPressLeadingActionButton,
            ),
            trailingActions: [
              PlatformIconButton(
                material: (_, __) => MaterialIconButtonData(
                    tooltip: _subpageRightsecondActionButtonTextBuilders[
                        _pageIndex.value](context)),
                padding: EdgeInsets.zero,
                icon: Icon(_subpageRightsecondActionButtonIconBuilders[
                    _pageIndex.value](context)),
                onPressed: _onPressRightsecondActionButton,
              ),
              PlatformIconButton(
                material: (_, __) => MaterialIconButtonData(
                    tooltip: _subpageRightmostActionButtonTextBuilders[
                        _pageIndex.value](context)),
                padding: EdgeInsets.zero,
                icon: Icon(
                    _subpageRightmostActionButtonIconBuilders[_pageIndex.value](
                        context)),
                onPressed: _onPressRightmostActionButton,
              ),
            ],
          ),
          body: IndexedStack(
            index: _pageIndex.value,
            children: _subpage,
          ),

          // 2021-5-19 @w568w:
          // Override the builder to prevent the repeatedly built states.
          // I don't know why it works...
          cupertinoTabChildBuilder: (_, index) => _subpage[index],
          bottomNavBar: PlatformNavBar(
            items: [
              BottomNavigationBarItem(
                //backgroundColor: Colors.purple,
                icon: PlatformX.isAndroid
                    ? Icon(Icons.dashboard)
                    : Icon(SFSymbols.square_stack_3d_up_fill),
                label: S.of(context).dashboard,
              ),
              BottomNavigationBarItem(
                //backgroundColor: Colors.indigo,
                icon: PlatformX.isAndroid
                    ? Icon(Icons.forum)
                    : Icon(SFSymbols.text_bubble),
                label: S.of(context).forum,
              ),
              BottomNavigationBarItem(
                //backgroundColor: Colors.blue,
                icon: PlatformX.isAndroid
                    ? Icon(Icons.calendar_today)
                    : Icon(SFSymbols.calendar),
                label: S.of(context).timetable,
              ),
              BottomNavigationBarItem(
                //backgroundColor: Theme.of(context).primaryColor,
                icon: PlatformX.isAndroid
                    ? Icon(Icons.settings)
                    : Icon(SFSymbols.gear_alt),
                label: S.of(context).settings,
              ),
            ],
            currentIndex: _pageIndex.value,
            material: (_, __) => MaterialNavBarData(
              type: BottomNavigationBarType.fixed,
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
        ),
      );
    }
  }

  Future<void> _loadAnnouncement() async {
    Announcement announcement =
        await AnnouncementRepository.getInstance().getLastNewAnnouncement();
    if (announcement != null) {
      showPlatformDialog(
          context: context,
          builder: (BuildContext context) => PlatformAlertDialog(
                title: Text(S
                    .of(context)
                    .developer_announcement(announcement.createdAt)),
                content: Text(announcement.content),
                actions: <Widget>[
                  PlatformDialogAction(
                      child: PlatformText(S.of(context).i_see),
                      onPressed: () => Navigator.pop(context)),
                ],
              ));
    }
  }
}
