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
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:catcher/catcher.dart';
import 'package:dan_xi/common/Secret.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/feature/feature_map.dart';
import 'package:dan_xi/master_detail/master_detail_view.dart';
import 'package:dan_xi/model/announcement.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/page/aao_notices.dart';
import 'package:dan_xi/page/announcement_notices.dart';
import 'package:dan_xi/page/bbs_post.dart';
import 'package:dan_xi/page/bbs_tags.dart';
import 'package:dan_xi/page/bus.dart';
import 'package:dan_xi/page/card_detail.dart';
import 'package:dan_xi/page/card_traffic.dart';
import 'package:dan_xi/page/dashboard_reorder.dart';
import 'package:dan_xi/page/empty_classroom_detail.dart';
import 'package:dan_xi/page/exam_detail.dart';
import 'package:dan_xi/page/gpa_table.dart';
import 'package:dan_xi/page/image_viewer.dart';
import 'package:dan_xi/page/open_source_license.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/page/subpage_bbs.dart';
import 'package:dan_xi/page/subpage_main.dart';
import 'package:dan_xi/page/subpage_settings.dart';
import 'package:dan_xi/page/subpage_timetable.dart';
import 'package:dan_xi/page/text_selector.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/announcement_repository.dart';
import 'package:dan_xi/repository/table_repository.dart';
import 'package:dan_xi/repository/uis_login_tool.dart';
import 'package:dan_xi/util/bmob/bmob/bmob.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/firebase_handler.dart';
import 'package:dan_xi/util/flutter_app.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/retryer.dart';
import 'package:dan_xi/util/stream_listener.dart';
import 'package:dan_xi/widget/bbs_editor.dart';
import 'package:dan_xi/widget/login_dialog/login_dialog.dart';
import 'package:dan_xi/widget/qr_code_dialog/qr_code_dialog.dart';
import 'package:dan_xi/widget/top_controller.dart';
import 'package:dio_log/overlay_draggable_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_tray/system_tray.dart';

import 'generated/l10n.dart';

final QuickActions quickActions = QuickActions();

ThemeData getTheme(BuildContext context) {
  return PlatformX.isDarkMode
      ? Constant.darkTheme(PlatformX.isCupertino(context))
      : Constant.lightTheme(PlatformX.isCupertino(context));
}

void sendFduholeTokenToWatch(String token) {
  const channel = const MethodChannel('fduhole');
  channel.invokeMethod("send_token", token);
}

/// The main entry of the whole app.
/// Do some initiative work here.
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
  // Init Feature registation.
  FeatureMap.registerAllFeatures();
  Catcher(
      rootWidget: DanxiApp(),
      debugConfig: debugOptions,
      releaseConfig: releaseOptions);
  doWhenWindowReady(() {
    final win = appWindow;
    win.show();
  });
}

class DanxiApp extends StatelessWidget {
  /// Routes to every pages.
  static final Map<String, Function> routes = {
    '/placeholder': (context, {arguments}) => Container(),
    '/card/detail': (context, {arguments}) =>
        CardDetailPage(arguments: arguments),
    '/card/crowdData': (context, {arguments}) =>
        CardCrowdData(arguments: arguments),
    '/room/detail': (context, {arguments}) =>
        EmptyClassroomDetailPage(arguments: arguments),
    '/bbs/postDetail': (context, {arguments}) =>
        BBSPostDetail(arguments: arguments),
    '/notice/aao/list': (context, {arguments}) =>
        AAONoticesList(arguments: arguments),
    '/about/openLicense': (context, {arguments}) =>
        OpenSourceLicenseList(arguments: arguments),
    '/announcement/list': (context, {arguments}) =>
        AnnouncementList(arguments: arguments),
    '/exam/detail': (context, {arguments}) => ExamList(arguments: arguments),
    '/dashboard/reorder': (context, {arguments}) =>
        DashboardReorderPage(arguments: arguments),
    '/bbs/discussions': (context, {arguments}) =>
        BBSSubpage(arguments: arguments),
    '/bbs/tags': (context, {arguments}) => BBSTagsPage(arguments: arguments),
    '/bbs/fullScreenEditor': (context, {arguments}) =>
        BBSEditorPage(arguments: arguments),
    '/image/detail': (context, {arguments}) =>
        ImageViewerPage(arguments: arguments),
    '/text/detail': (context, {arguments}) =>
        TextSelectorPage(arguments: arguments),
    '/exam/gpa': (context, {arguments}) => GpaTablePage(arguments: arguments),
    '/bus/detail': (context, {arguments}) => BusPage(arguments: arguments),
  };

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Phoenix(
        child: PlatformProvider(
      // initialPlatform: TargetPlatform.iOS,
      builder: (BuildContext context) => Theme(
        data: getTheme(context),
        child: PlatformApp(
          title: '旦夕',
          debugShowCheckedModeBanner: false,
          // Fix cupertino UI text color issues
          cupertino: (_, __) => CupertinoAppData(
              theme: CupertinoThemeData(
                  textTheme: CupertinoTextThemeData(
                      textStyle: TextStyle(
                          color:
                              getTheme(context).textTheme.bodyText1.color)))),
          // Configure i18n delegates
          localizationsDelegates: [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate
          ],
          supportedLocales: S.delegate.supportedLocales,
          home: MasterDetailController(
            masterPage: HomePage(),
          ),
          // Configure the page route behaviour of the whole app
          onGenerateRoute: (settings) {
            final Function pageContentBuilder = DanxiApp.routes[settings.name];
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

GlobalKey<NavigatorState> detailNavigatorKey = GlobalKey();

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  SharedPreferences _preferences;

  /// A description for current connection status.
  ValueNotifier<String> _connectStatus = ValueNotifier("");

  /// Listener to the failure of logging in caused by necessary captcha.
  ///
  /// Open up a dialog to request user to log in manually in the browser.
  static StateStreamListener<CaptchaNeededException> _captchaSubscription =
      StateStreamListener();

  //Dark/Light Theme Control
  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
  }

  /// If we need to send the QR code to iWatch now.
  ///
  /// When notified [watchActivated], we should send it after [StateProvider.personInfo] is loaded.
  bool _needSendToWatch = false;

  /// Whether the error dialog is shown.
  /// If a dialog has been shown, we will not show a duplicated one.
  /// See [_dealWithCaptchaNeededException]
  bool _isDialogShown = false;

  /// The tab page index.
  ValueNotifier<int> _pageIndex = ValueNotifier(0);

  /// List of all of the subpages. They will be displayed as tab pages.
  List<PlatformSubpage> _subpage = [];

  /// Force app to rebuild all of subpages.
  ///
  /// It's usually called when user changes his account.
  void _rebuildPage() {
    _subpage = [
      HomeSubpage(),
      BBSSubpage(),
      TimetableSubPage(),
      SettingsSubpage(),
    ];
  }

  final List<Function> _appTitleWidgetBuilder = [
    (cxt) => Text(S.of(cxt).app_name),
    (cxt) => Text(S.of(cxt).forum),
    (cxt) => Text(S.of(cxt).timetable),
    (cxt) => Text(S.of(cxt).settings)
  ];

  /// List of all of the subpages' action button icon. They will show on the appbar of each tab page.
  final List<Function> _subpageRightmostActionButtonWidgetBuilders = [
    (cxt) => Text(
          S.of(cxt).edit,
          textScaleFactor: 1.2,
        ),
    (cxt) => Icon(
        PlatformX.isAndroid ? PlatformIcons(cxt).add : SFSymbols.plus_circle),
    (cxt) =>
        Icon(PlatformX.isAndroid ? Icons.share : SFSymbols.square_arrow_up),
    (cxt) => null
  ];
  final List<Function> _subpageRightsecondActionButtonIconBuilders = [
    (cxt) => null,
    (cxt) => SFSymbols.star,
    (cxt) => null,
    (cxt) => null
  ];
  final List<Function> _subpageLeadingActionButtonIconBuilders = [
    (cxt) => PlatformX.isAndroid ? Icons.notifications : SFSymbols.bell_circle,
    (cxt) => SFSymbols.sort_down_circle,
    (cxt) => null,
    (cxt) => null
  ];

  /// List of all of the subpage action buttons' description. They will show on the appbar of each tab page.
  final List<Function> _subpageRightmostActionButtonTextBuilders = [
    (cxt) => S.of(cxt).dashboard_layout,
    (cxt) => S.of(cxt).new_post,
    (cxt) => S.of(cxt).share,
    (cxt) => null,
  ];
  final List<Function> _subpageRightsecondActionButtonTextBuilders = [
    (cxt) => null,
    (cxt) => S.of(cxt).favorites,
    (cxt) => null,
    (cxt) => null,
  ];
  final List<Function> _subpageLeadingActionButtonTextBuilders = [
    (cxt) => S.of(cxt).developer_announcement(''),
    (cxt) => S.of(cxt).sort_order,
    (cxt) => null,
    (cxt) => null,
  ];
  final SystemTray _systemTray = SystemTray();

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
                    BrowserUtil.openUrl(Constant.UIS_URL, context);
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

  Future<void> initSystemTray() async {
    if (!PlatformX.isWindows) return;
    // We first init the systray menu and then add the menu entries
    await _systemTray.initSystemTray("system tray",
        iconPath: PlatformX.createPlatformFile(
                PlatformX.getPathFromFile(Platform.resolvedExecutable) +
                    "/data/flutter_assets/assets/graphics/app_icon.ico")
            .path,
        toolTip: "DanXi is here~");
    List<MenuItemBase> showingMenu;
    List<MenuItemBase> hidingMenu;
    showingMenu = [
      MenuItem(
        label: 'Hide',
        onClicked: () {
          appWindow.hide();
          _systemTray.setContextMenu(hidingMenu);
        },
      ),
      MenuSeparator(),
      MenuItem(
        label: 'Exit',
        onClicked: () {
          appWindow.close();
          FlutterApp.exitApp();
        },
      ),
    ];
    hidingMenu = [
      MenuItem(
        label: 'Show',
        onClicked: () {
          appWindow.show();
          _systemTray.setContextMenu(showingMenu);
        },
      ),
      MenuSeparator(),
      MenuItem(
        label: 'Exit',
        onClicked: () {
          appWindow.close();
          FlutterApp.exitApp();
        },
      ),
    ];
    await _systemTray.setContextMenu(showingMenu);
  }

  @override
  void initState() {
    super.initState();
    // Init for firebase services.
    FirebaseHandler.initFirebase();
    // Refresh the page when account changes.
    StateProvider.personInfo.addListener(() {
      _rebuildPage();
      refreshSelf();
    });
    initSystemTray();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
      // This callback gets invoked every time brightness changes
      // What's wrong with this code? why does the app refresh on every launch?
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

    // Load the latest announcement & the start date of the following term.
    // Just ignore the network error.
    _loadAnnouncement().catchError((ignored) {});
    _loadStartDate().catchError((ignored) {});

    _loadOrInitSharedPreference().then((_) {
      // Configure shortcut listeners on Android & iOS.
      if (PlatformX.isMobile)
        quickActions.initialize((shortcutType) {
          if (shortcutType == 'action_qr_code' &&
              StateProvider.personInfo.value != null) {
            QRHelper.showQRCode(context, StateProvider.personInfo.value);
          }
        });
      // Configure watch listeners on iOS.
      if (_needSendToWatch &&
          _preferences.containsKey(SettingsProvider.KEY_FDUHOLE_TOKEN)) {
        sendFduholeTokenToWatch(
            _preferences.getString(SettingsProvider.KEY_FDUHOLE_TOKEN));
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
    // _initPlatformState(); //Init brightness control

    // Init watchOS support
    const channel_a = const MethodChannel('fduhole');
    channel_a.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'get_token') {
        // If we haven't loaded [StateProvider.personInfo]
        if (_preferences.containsKey(SettingsProvider.KEY_FDUHOLE_TOKEN)) {
          sendFduholeTokenToWatch(
              _preferences.getString(SettingsProvider.KEY_FDUHOLE_TOKEN));
        } else {
          // Notify that we should send the token to watch later
          _needSendToWatch = true;
        }
      }
    });
  }

  /// Pop up a dialog where user can give his name & password.
  void _showLoginDialog({bool forceLogin = false}) => showPlatformDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoginDialog(
          sharedPreferences: _preferences,
          personInfo: StateProvider.personInfo,
          forceLogin: forceLogin));

  /// Load persistent data (e.g. user name, password, etc.) from the local storage.
  ///
  /// If user hasn't logged in before, request him to do so.
  Future<void> _loadOrInitSharedPreference({bool forceLogin = false}) async {
    _preferences = await SharedPreferences.getInstance();

    if (!forceLogin && PersonInfo.verifySharedPreferences(_preferences)) {
      StateProvider.personInfo.value =
          PersonInfo.fromSharedPreferences(_preferences);
    } else {
      _showLoginDialog(forceLogin: forceLogin);
    }
  }

  /// When user clicks the action button on appbar
  void _onPressRightmostActionButton() async {
    switch (_pageIndex.value) {
      case 0:
        smartNavigatorPush(context, '/dashboard/reorder',
                arguments: {'preferences': _preferences})
            .then((value) => RefreshHomepageEvent(onlyIfQueued: true).fire());
        break;
      case 1:
        AddNewPostEvent().fire();
        break;
      case 2:
        ShareTimetableEvent().fire();
        break;
    }
  }

  void _onPressRightSecondActionButton() async {
    switch (_pageIndex.value) {
      //Entries omitted
      case 1:
        smartNavigatorPush(context, '/bbs/discussions', arguments: {
          'showFavoredDiscussion': true,
          'preferences': _preferences,
        });
        break;
    }
  }

  void _onPressLeadingActionButton() async {
    switch (_pageIndex.value) {
      //Entries omitted
      case 0:
        smartNavigatorPush(context, '/announcement/list');
        break;
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
    // Build action buttons.
    PlatformIconButton leadingButton;
    List<PlatformIconButton> trailingButtons = [];
    if (_subpageLeadingActionButtonIconBuilders[_pageIndex.value](context) !=
        null) {
      leadingButton = PlatformIconButton(
        material: (_, __) => MaterialIconButtonData(
            tooltip: _subpageLeadingActionButtonTextBuilders[_pageIndex.value](
                context)),
        padding: EdgeInsets.zero,
        icon: Icon(
            _subpageLeadingActionButtonIconBuilders[_pageIndex.value](context)),
        onPressed: _onPressLeadingActionButton,
      );
    }

    // BBS Subpage's third trailing button
    if (_pageIndex.value == 1) {
      trailingButtons.add(PlatformIconButton(
        material: (_, __) =>
            MaterialIconButtonData(tooltip: S.of(context).all_tags),
        padding: EdgeInsets.zero,
        cupertinoIcon: Icon(SFSymbols.tag),
        materialIcon: Icon(Icons.tag),
        onPressed: () => smartNavigatorPush(context, '/bbs/tags', arguments: {
          'preferences': _preferences,
        }),
      ));
    }

    if (_subpageRightsecondActionButtonIconBuilders[_pageIndex.value](
            context) !=
        null) {
      trailingButtons.add(PlatformIconButton(
        material: (_, __) => MaterialIconButtonData(
            tooltip:
                _subpageRightsecondActionButtonTextBuilders[_pageIndex.value](
                    context)),
        padding: EdgeInsets.zero,
        icon: Icon(
            _subpageRightsecondActionButtonIconBuilders[_pageIndex.value](
                context)),
        onPressed: _onPressRightSecondActionButton,
      ));
    }
    if (_subpageRightmostActionButtonWidgetBuilders[_pageIndex.value](
            context) !=
        null) {
      trailingButtons.add(PlatformIconButton(
        material: (_, __) => MaterialIconButtonData(
            tooltip:
                _subpageRightmostActionButtonTextBuilders[_pageIndex.value](
                    context)),
        padding: EdgeInsets.zero,
        icon: _subpageRightmostActionButtonWidgetBuilders[_pageIndex.value](
            context),
        onPressed: _onPressRightmostActionButton,
      ));
    }

    if (StateProvider.personInfo.value == null) {
      // Show an empty container if no person info is set
      return PlatformScaffold(
        iosContentBottomPadding: false,
        iosContentPadding: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: PlatformAppBar(
          title: _appTitleWidgetBuilder[_pageIndex.value](context),
          trailingActions: trailingButtons,
        ),
        body: Container(),
      );
    } else {
      // Show debug button for [Dio].
      if (PlatformX.isDebugMode(_preferences)) showDebugBtn(context);
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _pageIndex),
          ChangeNotifierProvider.value(value: _connectStatus),
          ChangeNotifierProvider.value(value: StateProvider.personInfo),
          Provider.value(value: _preferences),
        ],
        child: PlatformScaffold(
          iosContentBottomPadding: _subpage[_pageIndex.value].needBottomPadding,
          iosContentPadding: _subpage[_pageIndex.value].needPadding,

          // This workarounds a color bug
          backgroundColor: _pageIndex.value == 2
              ? null
              : Theme.of(context).scaffoldBackgroundColor,

          appBar: PlatformAppBar(
            cupertino: (_, __) => CupertinoNavigationBarData(
              title: MediaQuery(
                data: MediaQueryData(
                    textScaleFactor: MediaQuery.textScaleFactorOf(context)),
                child: TopController(
                  child: _appTitleWidgetBuilder[_pageIndex.value](context),
                  controller: PrimaryScrollController.of(context),
                ),
              ),
            ),
            material: (_, __) => MaterialAppBarData(
              title: TopController(
                child: Text(
                  S.of(context).app_name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                controller: PrimaryScrollController.of(context),
              ),
            ),
            leading: leadingButton,
            trailingActions: trailingButtons,
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
                // List<ScrollPosition> positions =
                //     PrimaryScrollController.of(context).positions.toList();
                // for (var p in positions.skip(1)) {
                //   PrimaryScrollController.of(context).detach(p);
                // }
                for (int i = 0; i < _subpage.length; i++) {
                  if (index != i) {
                    _subpage[i].onViewStateChanged(SubpageViewState.INVISIBLE);
                  }
                }
                _subpage[index].onViewStateChanged(SubpageViewState.VISIBLE);
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
                title: Text(
                  S.of(context).developer_announcement(announcement.createdAt),
                ),
                content: Linkify(
                  text: announcement.content,
                  onOpen: (element) =>
                      BrowserUtil.openUrl(element.url, context),
                ),
                actions: <Widget>[
                  PlatformDialogAction(
                      child: PlatformText(S.of(context).i_see),
                      onPressed: () => Navigator.pop(context)),
                ],
              ));
    }
  }

  Future<void> _loadStartDate() async {
    TimeTable.START_TIME = await AnnouncementRepository.getInstance()
        .getStartDate()
        .catchError((e) {
      showPlatformDialog(
          context: context,
          builder: (BuildContext context) => PlatformAlertDialog(
                title: Text(
                  S.of(context).fatal_error,
                ),
                content: Text(S.of(context).login_issue_2),
                actions: <Widget>[
                  PlatformDialogAction(
                      child: PlatformText(S.of(context).retry),
                      onPressed: () {
                        Navigator.pop(context);
                        _loadStartDate();
                      }),
                  PlatformDialogAction(
                      child: PlatformText(S.of(context).skip),
                      onPressed: () => Navigator.pop(context)),
                ],
              ));
    });
    // Determine if Timetable needs to be updated
    if (SettingsProvider.of(_preferences).lastSemesterStartTime !=
            TimeTable.START_TIME.toIso8601String() &&
        StateProvider.personInfo.value != null) {
      // Update Timetable
      Retrier.runAsyncWithRetry(
              () => TimeTableRepository.getInstance().loadTimeTableLocally(
                  StateProvider.personInfo.value,
                  forceLoadFromRemote: true),
              retryTimes: 1)
          .onError((error, stackTrace) => Noticing.showNotice(
              context, S.of(context).timetable_refresh_error,
              title: S.of(context).fatal_error, androidUseSnackbar: false));

      SettingsProvider.of(_preferences).lastSemesterStartTime =
          TimeTable.START_TIME.toIso8601String();
    }
  }
}
