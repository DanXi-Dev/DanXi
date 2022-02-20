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
import 'dart:ui';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:catcher/catcher.dart';
import 'package:dan_xi/feature/feature_map.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/page/dashboard/aao_notices.dart';
import 'package:dan_xi/page/dashboard/announcement_notices.dart';
import 'package:dan_xi/page/dashboard/bus.dart';
import 'package:dan_xi/page/dashboard/card_detail.dart';
import 'package:dan_xi/page/dashboard/card_traffic.dart';
import 'package:dan_xi/page/dashboard/dashboard_reorder.dart';
import 'package:dan_xi/page/dashboard/empty_classroom_detail.dart';
import 'package:dan_xi/page/dashboard/exam_detail.dart';
import 'package:dan_xi/page/dashboard/gpa_table.dart';
import 'package:dan_xi/page/home_page.dart';
import 'package:dan_xi/page/opentreehole/hole_detail.dart';
import 'package:dan_xi/page/opentreehole/hole_editor.dart';
import 'package:dan_xi/page/opentreehole/hole_login.dart';
import 'package:dan_xi/page/opentreehole/hole_messages.dart';
import 'package:dan_xi/page/opentreehole/hole_reports.dart';
import 'package:dan_xi/page/opentreehole/hole_search.dart';
import 'package:dan_xi/page/opentreehole/hole_tags.dart';
import 'package:dan_xi/page/opentreehole/image_viewer.dart';
import 'package:dan_xi/page/opentreehole/text_selector.dart';
import 'package:dan_xi/page/settings/hidden_tags_preference.dart';
import 'package:dan_xi/page/settings/open_source_license.dart';
import 'package:dan_xi/page/subpage_treehole.dart';
import 'package:dan_xi/provider/notification_provider.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/util/bmob/bmob/bmob.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/screen_proxy.dart';
import 'package:dan_xi/widget/libraries/dynamic_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'common/constant.dart';

/// The main entry of the whole app.
/// Do some initial work here.
void main() {
  // Config [Catcher] to catch uncaught exceptions.
  CatcherOptions debugOptions = CatcherOptions(SilentReportMode(), [
    ConsoleHandler()
  ], localizationOptions: [
    LocalizationOptions.buildDefaultEnglishOptions(),
    LocalizationOptions.buildDefaultChineseOptions(),
  ]);
  CatcherOptions releaseOptions = CatcherOptions(SilentReportMode(), [
    ConsoleHandler()
  ], localizationOptions: [
    LocalizationOptions.buildDefaultEnglishOptions(),
    LocalizationOptions.buildDefaultChineseOptions(),
  ]);

  WidgetsFlutterBinding.ensureInitialized();

  // Init Bmob database.
  Bmob.init(
      "https://api2.bmob.cn", Constant.BMOB_APP_ID, Constant.BMOB_API_KEY);

  // Init Mi push Service.
  // if (PlatformX.isAndroid) {
  //   XiaoMiPushPlugin.init(
  //       appId: "2882303761519940685", appKey: "5821994071685");
  // }

  // Init Feature registration.
  FeatureMap.registerAllFeatures();
  unawaited(ScreenProxy.init());
  SettingsProvider.getInstance().init().then((_) {
    // Initialize Ad only if user has opted-in to save resources
    // If user decides to opt-in after the app has started,
    // Admob SDK will automatically initialize on first request.
    // if (SettingsProvider.getInstance().isAdEnabled) {
    //   MobileAds.instance.initialize();
    // }

    Catcher(
        rootWidget: const DanxiApp(),
        debugConfig: debugOptions,
        releaseConfig: releaseOptions);
  });

  // Init DesktopWindow on desktop environment.
  if (PlatformX.isDesktop) {
    doWhenWindowReady(() {
      final win = appWindow;
      win.show();
    });
  }
}

class TouchMouseScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus
        // etc.
      };
}

/// ## Note: A Checklist After Creating a New Page
///
/// [TextSelectorPage] is a simple example of what a typical page in DanXi looks like.
/// Also have a look at [AAONoticesList] if you are looking for something a bit advanced.
///
/// 1. Register it in [DanxiApp.routes] below, with the same syntax.
/// 2. Call [smartNavigatorPush] to navigate to the page.
///
class DanxiApp extends StatelessWidget {
  /// Routes to every pages.
  static final Map<String, Function> routes = {
    '/placeholder': (context, {arguments}) => const SizedBox(),
    '/home': (context, {arguments}) => const HomePage(),
    '/bbs/reports': (context, {arguments}) =>
        BBSReportDetail(arguments: arguments),
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
        TreeHoleSubpage(arguments: arguments),
    '/bbs/tags': (context, {arguments}) => BBSTagsPage(arguments: arguments),
    '/bbs/fullScreenEditor': (context, {arguments}) =>
        BBSEditorPage(arguments: arguments),
    '/image/detail': (context, {arguments}) =>
        ImageViewerPage(arguments: arguments),
    '/text/detail': (context, {arguments}) =>
        TextSelectorPage(arguments: arguments),
    '/exam/gpa': (context, {arguments}) => GpaTablePage(arguments: arguments),
    '/bus/detail': (context, {arguments}) => BusPage(arguments: arguments),
    '/bbs/tags/blocklist': (context, {arguments}) =>
        BBSHiddenTagsPreferencePage(arguments: arguments),
    '/bbs/login': (context, {arguments}) => HoleLoginPage(arguments: arguments),
    '/bbs/messages': (context, {arguments}) =>
        OTMessagesPage(arguments: arguments),
    '/bbs/search': (context, {arguments}) => OTSearchPage(arguments: arguments),
  };

  const DanxiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget mainApp = PlatformProvider(
      // Uncomment this line below to force the app to use Cupertino UI
      // initialPlatform: TargetPlatform.iOS,
      builder: (BuildContext context) => DynamicThemeController(
        lightTheme: Constant.lightTheme(PlatformX.isCupertino(context)),
        darkTheme: Constant.darkTheme(PlatformX.isCupertino(context)),
        child: PlatformApp(
          scrollBehavior: TouchMouseScrollBehavior(),
          debugShowCheckedModeBanner: false,
          // Fix cupertino UI text color issue by override text color
          cupertino: (context, __) => CupertinoAppData(
              theme: CupertinoThemeData(
                  textTheme: CupertinoTextThemeData(
                      textStyle: TextStyle(
                          color: PlatformX.getTheme(context)
                              .textTheme
                              .bodyText1!
                              .color)))),
          // Configure i18n delegates
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate
          ],
          supportedLocales: S.delegate.supportedLocales,
          onUnknownRoute: (settings) {
            throw AssertionError(
                "ERROR: onUnknownRoute() has been called inside the root navigator.\nDevelopers are not supposed to push on this Navigator. There should be something wrong in the code.");
          },
          home: PlatformMasterDetailApp(
            // Configure the page route behaviour of the whole app
            onGenerateRoute: (settings) {
              final Function? pageContentBuilder =
                  DanxiApp.routes[settings.name!];
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
      ),
    );
    if (PlatformX.isAndroid || PlatformX.isIOS) {
      // Listen to Foreground / Background Event with [FGBGNotifier].
      mainApp = FGBGNotifier(
          onEvent: (FGBGType value) {
            switch (value) {
              case FGBGType.foreground:
                StateProvider.isForeground = true;
                break;
              case FGBGType.background:
                StateProvider.isForeground = false;
                break;
            }
          },
          child: mainApp);
    }

    return Phoenix(
      child: MultiProvider(providers: [
        ChangeNotifierProvider.value(value: SettingsProvider.getInstance()),
        ChangeNotifierProvider(create: (_) => NotificationProvider())
      ], child: mainApp),
    );
  }
}
