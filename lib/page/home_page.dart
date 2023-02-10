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
import 'dart:convert';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/common/pubspec.yaml.g.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/announcement.dart';
import 'package:dan_xi/model/extra.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/page/subpage_danke.dart';
import 'package:dan_xi/page/subpage_dashboard.dart';
import 'package:dan_xi/page/subpage_settings.dart';
import 'package:dan_xi/page/subpage_timetable.dart';
import 'package:dan_xi/page/subpage_treehole.dart';
import 'package:dan_xi/provider/fduhole_provider.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/app/announcement_repository.dart';
import 'package:dan_xi/repository/fdu/uis_login_tool.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/test/test.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/flutter_app.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/stream_listener.dart';
import 'package:dan_xi/widget/dialogs/login_dialog.dart';
import 'package:dan_xi/widget/dialogs/qr_code_dialog.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/linkify_x.dart';
import 'package:dan_xi/widget/libraries/platform_nav_bar_m3.dart';
import 'package:dan_xi/widget/opentreehole/post_render.dart';
import 'package:dan_xi/widget/opentreehole/render/render_impl.dart';
import 'package:dio_log/overlay_draggable_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:lazy_load_indexed_stack/lazy_load_indexed_stack.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:screen_capture_event/screen_capture_event.dart';
import 'package:xiao_mi_push_plugin/entity/mi_push_command_message_entity.dart';
import 'package:xiao_mi_push_plugin/entity/mi_push_message_entity.dart';
import 'package:xiao_mi_push_plugin/xiao_mi_push_plugin.dart';
import 'package:xiao_mi_push_plugin/xiao_mi_push_plugin_listener.dart';

const fduholeChannel = MethodChannel('fduhole');

void sendFduholeTokenToWatch(String? token) {
  fduholeChannel.invokeMethod("send_token", token);
}

GlobalKey<NavigatorState> detailNavigatorKey = GlobalKey();
GlobalKey<State<SettingsSubpage>> settingsPageKey = GlobalKey();
GlobalKey<TreeHoleSubpageState> treeholePageKey = GlobalKey();
GlobalKey<HomeSubpageState> dashboardPageKey = GlobalKey();
GlobalKey<TimetableSubPageState> timetablePageKey = GlobalKey();
const QuickActions quickActions = QuickActions();

/// The main page of DanXi.
/// It is a container for [PlatformSubpage].
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final ScreenCaptureEvent? screenListener =
      PlatformX.isMobile ? ScreenCaptureEvent() : null;

  /// Listener to the failure of logging in caused by different reasons.
  ///
  /// Open up a dialog to request user to log in manually in the browser.
  static final StateStreamListener<CaptchaNeededException>
      _captchaSubscription = StateStreamListener();
  static final StateStreamListener<CredentialsInvalidException>
      _credentialsInvalidSubscription = StateStreamListener();

  /// If we need to send the QR code to iWatch now.
  ///
  /// When notified [watchActivated], we should send it after [StateProvider.personInfo] is loaded.
  bool _needSendToWatch = false;

  /// Whether the error dialog is shown.
  /// If a dialog has been shown, we will not show a duplicated one.
  /// See [_dealWithCaptchaNeededException]
  bool _isErrorDialogShown = false;

  /// The tab page index.
  final ValueNotifier<int> _pageIndex = ValueNotifier(0);

  /// List of all of the subpages. They will be displayed as tab pages.
  List<PlatformSubpage<dynamic>> _subpage = [];

  /// Force app to rebuild all of subpages.
  ///
  /// It's usually called when user changes his account.
  void _rebuildPage() {
    _lastRefreshTime = DateTime.now();
    _subpage = [
      // Don't show Dashboard in visitor mode
      if (StateProvider.personInfo.value?.group != UserGroup.VISITOR)
        HomeSubpage(key: dashboardPageKey),
      if (!SettingsProvider.getInstance().hideHole)
        TreeHoleSubpage(key: treeholePageKey),
      // Don't show Timetable in visitor mode
      const DankeSubPage(),
      if (StateProvider.personInfo.value?.group != UserGroup.VISITOR)
        TimetableSubPage(key: timetablePageKey),
      SettingsSubpage(key: settingsPageKey),
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _captchaSubscription.cancel();
    screenListener?.dispose();
    super.dispose();
  }

  /// Deal with login issue described at [CaptchaNeededException].
  _dealWithCaptchaNeededException() {
    // If we have shown a dialog, do not pop up another.
    if (_isErrorDialogShown) {
      return;
    }
    _isErrorDialogShown = true;
    showPlatformDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => PlatformAlertDialog(
              title: Text(S.of(context).fatal_error),
              content: Text(S.of(context).login_issue_1),
              actions: [
                if (!LoginDialog.dialogShown)
                  PlatformDialogAction(
                    child: Text(S.of(context).retry),
                    onPressed: () {
                      _isErrorDialogShown = false;
                      Navigator.of(context).pop();
                      FlutterApp.restartApp(context);
                    },
                  ),
                if (!LoginDialog.dialogShown)
                  PlatformDialogAction(
                    child: Text(S.of(context).re_login),
                    onPressed: () {
                      _isErrorDialogShown = false;
                      Navigator.of(context).pop();
                      _dealWithCredentialsInvalidException();
                    },
                  )
                else
                  PlatformDialogAction(
                    child: Text(S.of(context).cancel),
                    onPressed: () {
                      _isErrorDialogShown = false;
                      Navigator.of(context).pop();
                    },
                  ),
                PlatformDialogAction(
                  child: Text(S.of(context).login_issue_1_action),
                  onPressed: () =>
                      BrowserUtil.openUrl(Constant.UIS_URL, context),
                ),
              ],
            ));
  }

  /// Deal with login issue described at [CredentialsInvalidException].
  _dealWithCredentialsInvalidException() async {
    if (!LoginDialog.dialogShown) {
      // In case that [_preferences] is still not initialized.
      PersonInfo.removeFromSharedPreferences(
          SettingsProvider.getInstance().preferences!);
      FlutterApp.restartApp(context);
    }
  }

  /// Deal with bmob error (e.g. unable to obtain data in [AnnouncementRepository]).
  _dealWithBmobError() {
    showPlatformDialog(
        context: context,
        builder: (BuildContext context) => PlatformAlertDialog(
              title: Text(S.of(context).fatal_error),
              content: Text(S.of(context).login_issue_2),
              actions: <Widget>[
                PlatformDialogAction(
                    child: PlatformText(S.of(context).retry),
                    onPressed: () {
                      Navigator.pop(context);
                      _loadDataFromGithubRepo();
                    }),
                PlatformDialogAction(
                    child: PlatformText(S.of(context).skip),
                    onPressed: () => Navigator.pop(context)),
              ],
            ));
  }

  void _loadDataFromGithubRepo() {
    AnnouncementRepository.getInstance().loadAnnouncements().then((value) {
      _loadUpdate().then(
          (value) => _loadAnnouncement().catchError((ignored) {}),
          onError: (ignored) {});
      _loadUserAgent().catchError((ignored) {});
      _loadStartDate().catchError((ignored) {});
      _loadCelebration().catchError((ignored, st) {});
    }, onError: (e) {
      _dealWithBmobError();
    });
  }

  DateTime? _lastRefreshTime;

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    OpenTreeHoleRepository.getInstance().reduceFloorCache();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        // After the app returns from the background,
        // refresh the homepage if it hasn't been refreshed for 30 minutes
        // to keep the data up-to-date.
        if (_lastRefreshTime != null &&
            DateTime.now()
                    .difference(_lastRefreshTime!)
                    .compareTo(const Duration(minutes: 30)) >
                0) {
          _lastRefreshTime = DateTime.now();
          dashboardPageKey.currentState?.triggerRebuildFeatures();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> initSystemTray() async {
    /*
    if (!PlatformX.isWindows) return;
    // We first init the systray menu and then add the menu entries
    await _systemTray.initSystemTray(
        title: 'DanXi',
        iconPath: PlatformX.createPlatformFile(
                "${PlatformX.getPathFromFile(Platform.resolvedExecutable)}/data/flutter_assets/assets/graphics/app_icon.ico")
            .path,
        toolTip: "DanXi is here~");
    late List<tray.MenuItemBase> showingMenu, hidingMenu;
    showingMenu = [
      tray.MenuItem(
        label: 'Hide',
        onClicked: () {
          appWindow.hide();
          _systemTray.setContextMenu(hidingMenu);
        },
      ),
      tray.MenuSeparator(),
      tray.MenuItem(
        label: 'Exit',
        onClicked: () {
          appWindow.close();
          FlutterApp.exitApp();
        },
      ),
    ];
    hidingMenu = [
      tray.MenuItem(
        label: 'Show',
        onClicked: () {
          appWindow.show();
          _systemTray.setContextMenu(showingMenu);
        },
      ),
      tray.MenuSeparator(),
      tray.MenuItem(
        label: 'Exit',
        onClicked: () {
          appWindow.close();
          FlutterApp.exitApp();
        },
      ),
    ];
    await _systemTray.setContextMenu(showingMenu);
    */
  }

  Future<void> onTapNotification(
    BuildContext context,
    String? code,
    Map<String, dynamic>? data,
  ) async {
    if (!context.read<FDUHoleProvider>().isUserInitialized) {
      // Do a quick initialization and push
      OpenTreeHoleRepository.getInstance().initializeToken();
    }
    smartNavigatorPush(context, '/bbs/messages',
        forcePushOnMainNavigator: true);
    //OTMessageItem.dispMessageDetailBasedOnGuessedDataType(context, code, data);
  }

  @override
  void initState() {
    super.initState();
    // Refresh the page when account changes.
    StateProvider.personInfo.addListener(() {
      if (StateProvider.personInfo.value != null) {
        _rebuildPage();
        refreshSelf();
      }
    });
    initSystemTray().catchError((ignored) {});
    WidgetsBinding.instance.addObserver(this);

    _captchaSubscription.bindOnlyInvalid(
        Constant.eventBus
            .on<CaptchaNeededException>()
            .listen((_) => _dealWithCaptchaNeededException()),
        hashCode);
    _credentialsInvalidSubscription.bindOnlyInvalid(
        Constant.eventBus
            .on<CredentialsInvalidException>()
            .listen((_) => _dealWithCredentialsInvalidException()),
        hashCode);

    // Load the latest version, announcement & the start date of the following term.
    _loadDataFromGithubRepo();
    // Configure shortcut listeners on Android & iOS.
    if (PlatformX.isMobile) {
      quickActions.initialize((shortcutType) {
        if (shortcutType == 'action_qr_code' &&
            StateProvider.personInfo.value != null) {
          QRHelper.showQRCode(context, StateProvider.personInfo.value);
        }
      });
    }
    // Configure watch listeners on iOS.
    if (_needSendToWatch &&
        SettingsProvider.getInstance().fduholeToken != null) {
      sendFduholeTokenToWatch(
          SettingsProvider.getInstance().fduholeToken!.access!);
      // Only send once.
      _needSendToWatch = false;
    }
    // Add shortcuts on Android & iOS.
    if (PlatformX.isMobile) {
      quickActions.setShortcutItems(<ShortcutItem>[
        ShortcutItem(
            type: 'action_qr_code',
            localizedTitle: S.current.fudan_qr_code,
            icon: 'ic_launcher'),
      ]);
    }
    fduholeChannel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case "launch_from_notification":
          Map<String, dynamic> map =
              Map<String, dynamic>.from(call.arguments['data']);
          // Reconstruct data to restore proper type
          map.updateAll((key, value) {
            try {
              return int.parse(value);
            } catch (ignored) {}
            return value;
          });
          await onTapNotification(context, call.arguments['code'], map);
          break;
        case "upload_apns_token":
          try {
            await OpenTreeHoleRepository.getInstance()
                .updatePushNotificationToken(
                    call.arguments["token"],
                    await PlatformX.getUniqueDeviceId(),
                    PushNotificationServiceType.APNS);
          } catch (e, st) {
            Noticing.showNotice(
                context,
                S.of(context).push_notification_reg_failed_des(
                    ErrorPageWidget.generateUserFriendlyDescription(
                        S.of(context), e,
                        stackTrace: st)),
                title: S.of(context).push_notification_reg_failed);
          }
          break;
        case 'get_token':
          if (SettingsProvider.getInstance().fduholeToken != null) {
            sendFduholeTokenToWatch(
                SettingsProvider.getInstance().fduholeToken!.access!);
          } else {
            // Notify that we should send the token to watch later
            _needSendToWatch = true;
          }
          break;
      }
    });
    if (PlatformX.isAndroid) {
      XiaoMiPushPlugin.addListener((type, params) async {
        switch (type) {
          case XiaoMiPushListenerTypeEnum.NotificationMessageClicked:
            if (params is MiPushMessageEntity && params.content != null) {
              Map<String, String> obj = Uri.splitQueryString(params.content!);
              await onTapNotification(
                  context, obj['code'], jsonDecode(obj['data'] ?? ""));
            }
            break;
          case XiaoMiPushListenerTypeEnum.RequirePermissions:
          case XiaoMiPushListenerTypeEnum.ReceivePassThroughMessage:
          case XiaoMiPushListenerTypeEnum.CommandResult:
            break;
          case XiaoMiPushListenerTypeEnum.ReceiveRegisterResult:
            if (params is MiPushCommandMessageEntity &&
                (params.commandArguments?.isNotEmpty ?? false)) {
              String regId = params.commandArguments![0];
              try {
                await OpenTreeHoleRepository.getInstance()
                    .updatePushNotificationToken(
                        regId,
                        await PlatformX.getUniqueDeviceId(),
                        PushNotificationServiceType.MIPUSH);
              } catch (e, st) {
                Noticing.showNotice(
                    context,
                    S.of(context).push_notification_reg_failed_des(
                        ErrorPageWidget.generateUserFriendlyDescription(
                            S.of(context), e,
                            stackTrace: st)),
                    title: S.of(context).push_notification_reg_failed);
              }
            }
            break;
          case XiaoMiPushListenerTypeEnum.NotificationMessageArrived:
            break;
        }
      });
    }

    screenListener?.addScreenRecordListener((recorded) async {
      if (StateProvider.needScreenshotWarning &&
          StateProvider.isForeground &&
          !StateProvider.showingScreenshotWarning) {
        StateProvider.showingScreenshotWarning = true;
        await showScreenshotWarning(context);
        StateProvider.showingScreenshotWarning = false;
      }
    });
    screenListener?.addScreenShotListener((filePath) async {
      if (StateProvider.needScreenshotWarning &&
          StateProvider.isForeground &&
          !StateProvider.showingScreenshotWarning) {
        StateProvider.showingScreenshotWarning = true;
        await showScreenshotWarning(context);
        StateProvider.showingScreenshotWarning = false;
      }
    });
    screenListener?.watch();
  }

  static showScreenshotWarning(BuildContext context) =>
      Noticing.showNotice(context, S.of(context).screenshot_warning,
          title: S.of(context).screenshot_warning_title, useSnackBar: false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // We have to load personInfo after [initState] and [build], since it may pop up a dialog,
    // which is not allowed in both methods. It is because that the widget's reference to its inherited widget hasn't been changed.
    // Also, otherwise it will call [setState] before the frame is completed.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadPersonInfoOrLogin());
  }

  /// Load persistent data (e.g. user name, password, etc.) from the local storage.
  ///
  /// If user hasn't logged in before, request him to do so.
  void _loadPersonInfoOrLogin() {
    var preferences = SettingsProvider.getInstance().preferences;

    if (PersonInfo.verifySharedPreferences(preferences!)) {
      StateProvider.personInfo.value =
          PersonInfo.fromSharedPreferences(preferences);
      TestLifeCycle.onStart(context);
    } else {
      LoginDialog.showLoginDialog(
          context, preferences, StateProvider.personInfo, false);
    }
  }

  /// Show an empty container, if no person info is set.
  Widget _buildDummyBody(Widget title) => PlatformScaffold(
        iosContentBottomPadding: false,
        iosContentPadding: true,
        appBar: PlatformAppBar(title: title),
        body: Column(children: [
          Card(
            child: ListTile(
              leading: Icon(PlatformIcons(context).accountCircle),
              title: Text(S.of(context).login),
              onTap: () => LoginDialog.showLoginDialog(
                  context,
                  SettingsProvider.getInstance().preferences,
                  StateProvider.personInfo,
                  false),
            ),
          )
        ]),
      );

  Widget _buildBody(Widget title) {
    // Show debug button for [Dio].
    if (PlatformX.isDebugMode(SettingsProvider.getInstance().preferences)) {
      showDebugBtn(context);
    }

    return MultiProvider(
      providers: [ValueListenableProvider.value(value: _pageIndex)],
      child: PageWithTab(
        child: Consumer<int>(
          builder: (BuildContext context, pageIndex, _) => PlatformScaffold(
            body: LazyLoadIndexedStack(
              index: pageIndex,
              children: _subpage,
            ),

            // 2021-5-19 @w568w:
            // Override the builder to prevent the repeatedly built states on iOS.
            // I don't know why it works...
            cupertinoTabChildBuilder: (_, index) => _subpage[index],
            bottomNavBar: PlatformNavBarM3(
              items: [
                // Don't show Dashboard in visitor mode
                if (StateProvider.personInfo.value?.group != UserGroup.VISITOR)
                  BottomNavigationBarItem(
                    icon: PlatformX.isMaterial(context)
                        ? const Icon(Icons.dashboard)
                        : const Icon(CupertinoIcons.square_stack_3d_up_fill),
                    label: S.of(context).dashboard,
                  ),
                if (!SettingsProvider.getInstance().hideHole)
                  BottomNavigationBarItem(
                    icon: PlatformX.isMaterial(context)
                        ? const Icon(Icons.forum)
                        : const Icon(CupertinoIcons.text_bubble),
                    label: S.of(context).forum,
                  ),
                BottomNavigationBarItem(
                  icon: PlatformX.isMaterial(context)
                      ? const Icon(Icons.egg_alt)
                      : const Icon(CupertinoIcons.book),
                  label: S.of(context).danke,
                ),
                // Don't show Timetable in visitor mode
                if (StateProvider.personInfo.value?.group != UserGroup.VISITOR)
                  BottomNavigationBarItem(
                    icon: PlatformX.isMaterial(context)
                        ? const Icon(Icons.calendar_today)
                        : const Icon(CupertinoIcons.calendar),
                    label: S.of(context).timetable,
                  ),
                BottomNavigationBarItem(
                  icon: PlatformX.isMaterial(context)
                      ? const Icon(Icons.settings)
                      : const Icon(CupertinoIcons.gear_alt),
                  label: S.of(context).settings,
                ),
              ],
              currentIndex: pageIndex,
              itemChanged: (index) {
                if (index != pageIndex) {
                  // Dispatch [SubpageViewState] events.
                  for (int i = 0; i < _subpage.length; i++) {
                    if (index != i) {
                      _subpage[i]
                          .onViewStateChanged(SubpageViewState.INVISIBLE);
                    }
                  }
                  _subpage[index].onViewStateChanged(SubpageViewState.VISIBLE);
                  _pageIndex.value = index;
                } else {
                  _subpage[index].onDoubleTapOnTab();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget title = _subpage.isEmpty
        ? Text(S.of(context).app_name)
        : _subpage[_pageIndex.value].title.call(context);
    return StateProvider.personInfo.value == null || _subpage.isEmpty
        ? _buildDummyBody(title)
        : _buildBody(title);
  }

  Future<void> _loadUpdate() async {
    //We don't need to check for update on iOS platform.
    if (PlatformX.isIOS) return;
    final UpdateInfo updateInfo =
        AnnouncementRepository.getInstance().checkVersion();
    if (updateInfo.isAfter(major, minor, patch)) {
      await showPlatformDialog(
          context: context,
          builder: (BuildContext context) => PlatformAlertDialog(
                title: Text(
                  S.of(context).new_update_title,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(S.of(context).new_update_description(
                        FlutterApp.versionName,
                        updateInfo.latestVersion ?? "?")),
                    PostRenderWidget(
                      content: "```\n${updateInfo.changeLog}\n```",
                      render: kMarkdownRender,
                      hasBackgroundImage: false,
                    )
                  ],
                ),
                actions: <Widget>[
                  PlatformDialogAction(
                      child: PlatformText(S.of(context).update_now),
                      onPressed: () {
                        Navigator.pop(context);
                        BrowserUtil.openUrl(Constant.updateUrl(), context);
                      }),
                  PlatformDialogAction(
                      child: PlatformText(S.of(context).skip),
                      onPressed: () => Navigator.pop(context)),
                ],
              ));
    }
  }

  Future<void> _loadAnnouncement() async {
    final Announcement? announcement =
        await AnnouncementRepository.getInstance().getLastNewAnnouncement();
    if (announcement != null && mounted) {
      showPlatformDialog(
          context: context,
          builder: (BuildContext context) => PlatformAlertDialog(
                title: Text(
                  S
                      .of(context)
                      .developer_announcement(announcement.createdAt ?? "?"),
                ),
                content: SingleChildScrollView(
                    child: LinkifyX(
                  text: announcement.content!,
                  onOpen: (element) =>
                      BrowserUtil.openUrl(element.url, context),
                )),
                actions: <Widget>[
                  PlatformDialogAction(
                      child: PlatformText(S.of(context).i_see),
                      onPressed: () => Navigator.pop(context)),
                ],
              ));
    }
  }

  Future<void> _loadUserAgent() async {
    String? userAgent;
    try {
      userAgent = AnnouncementRepository.getInstance().getUserAgent();
    } catch (_) {}
    if (userAgent != null) {
      SettingsProvider.getInstance().customUserAgent =
          StateProvider.onlineUserAgent = userAgent;
    }
  }

  Future<void> _loadStartDate() async {
    TimeTableExtra? startDateData;
    try {
      startDateData = AnnouncementRepository.getInstance().getStartDates();
    } catch (_) {}
    if (startDateData != null) {
      SettingsProvider.getInstance().semesterStartDates = startDateData;
    }
  }

  Future<void> _loadCelebration() async {
    SettingsProvider.getInstance().celebrationWords =
        AnnouncementRepository.getInstance().getCelebrations();
  }
}
