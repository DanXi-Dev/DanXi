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

import 'package:dan_xi/feature/feature_map.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/page/danke/course_group_detail.dart';
import 'package:dan_xi/page/danke/course_review_editor.dart';
import 'package:dan_xi/page/dashboard/aao_notices.dart';
import 'package:dan_xi/page/dashboard/announcement_notices.dart';
import 'package:dan_xi/page/dashboard/bus.dart';
import 'package:dan_xi/page/dashboard/card_detail.dart';
import 'package:dan_xi/page/dashboard/card_traffic.dart';
import 'package:dan_xi/page/dashboard/dashboard_reorder.dart';
import 'package:dan_xi/page/dashboard/empty_classroom_detail.dart';
import 'package:dan_xi/page/dashboard/exam_detail.dart';
import 'package:dan_xi/page/dashboard/gpa_table.dart';
import 'package:dan_xi/page/forum/admin_operation.dart';
import 'package:dan_xi/page/forum/hole_detail.dart';
import 'package:dan_xi/page/forum/hole_editor.dart';
import 'package:dan_xi/page/forum/hole_login.dart';
import 'package:dan_xi/page/forum/hole_messages.dart';
import 'package:dan_xi/page/forum/hole_reports.dart';
import 'package:dan_xi/page/forum/hole_search.dart';
import 'package:dan_xi/page/forum/hole_tags.dart';
import 'package:dan_xi/page/forum/image_viewer.dart';
import 'package:dan_xi/page/forum/text_selector.dart';
import 'package:dan_xi/page/home_page.dart';
import 'package:dan_xi/page/settings/diagnostic_console.dart';
import 'package:dan_xi/page/settings/hidden_tags_preference.dart';
import 'package:dan_xi/page/settings/open_source_license.dart';
import 'package:dan_xi/page/subpage_forum.dart';
import 'package:dan_xi/provider/forum_provider.dart';
import 'package:dan_xi/provider/language_manager.dart';
import 'package:dan_xi/provider/notification_provider.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/util/lazy_future.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/screen_proxy.dart';
import 'package:dan_xi/widget/libraries/dynamic_theme.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:device_identity/device_identity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:material_color_generator/material_color_generator.dart';
import 'package:provider/provider.dart';
import 'package:xiao_mi_push_plugin/xiao_mi_push_plugin.dart';

import 'common/constant.dart';

/// The main entry of the whole app.
/// Do some initial work here.
void main() {
  // Ensure that the engine has bound itself to
  WidgetsFlutterBinding.ensureInitialized();

  // Init Mi push Service.
  if (PlatformX.isAndroid) {
    XiaoMiPushPlugin.init(
        appId: "2882303761519940685", appKey: "5821994071685");
  }

  // Init Feature registration.
  //
  // Feature map is a map that contains all the features in the home screen.
  //
  // If you want to add a new feature, refer to "Note: A Checklist After
  // Creating a New [Feature]" in `feature/base_feature.dart`
  //
  // A detailed example of a feature can be found in
  // `feature/dorm_electricity_feature.dart`. This file contains extensive
  // comments which would be helpful for you to get started.
  FeatureMap.registerAllFeatures();

  // Init ScreenProxy. It is a proxy class for [ScreenBrightness] to make it
  // work on all platforms.
  // We need to adjust the screen brightness when showing tht Fudan QR Code.
  unawaited(LazyFuture.pack(ScreenProxy.init()));

  // Init SettingsProvider. SettingsProvider is a singleton class that stores
  // all the settings of the app.
  SettingsProvider.getInstance().init().then((_) {
    SettingsProvider.getInstance().isTagSuggestionAvailable().then((value) {
      SettingsProvider.getInstance().tagSuggestionAvailable = value;
      final registerDeviceIdentity =
          PlatformX.isAndroid ? DeviceIdentity.register() : Future.value();
      registerDeviceIdentity.then((_) {
        // This is the entrypoint of a simple Flutter app.
        // runApp() is a function that takes a [Widget] and makes it the root
        // of the widget tree.
        runApp(const DanxiApp());
      });
    });
  });
}

class TouchMouseScrollBehavior extends MaterialScrollBehavior {
  // Override dragDevices to enable scrolling with mouse & stylus
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
        // etc.
      };
}

/// ## Note: A Checklist After Creating a New Page
///
/// [TextSelectorPage] is a simple example of what a typical page in DanXi looks like.
/// Also, you can have a look at [AAONoticesList] if looking for something a bit advanced.
///
/// 1. Register it in [DanxiApp.routes] below, with the same syntax.
/// 2. Call [smartNavigatorPush] to navigate to the page.
///
class DanxiApp extends StatelessWidget {
  /// Routes to every pages.
  /// Every route record is a function that returns a [Widget]. After registering
  //  the route, you can call [smartNavigatorPush] to navigate to the page.
  static final Map<String, Function> routes = {
    // @w568w(2024-07-01): if the placeholder is a ColoredBox with color alpha 255,
    // the app will be half black screen and half white screen, displaying nothing on Linux.
    // Why?
    '/placeholder': (context, {arguments}) => ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor.withAlpha(254)),
    '/home': (context, {arguments}) => const HomePage(),
    '/diagnose': (context, {arguments}) =>
        DiagnosticConsole(arguments: arguments),
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
        ForumSubpage(arguments: arguments),
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
    '/bbs/admin': (context, {arguments}) =>
        AdminOperationPage(arguments: arguments),
    '/bbs/login': (context, {arguments}) => HoleLoginPage(arguments: arguments),
    '/bbs/messages': (context, {arguments}) =>
        OTMessagesPage(arguments: arguments),
    '/bbs/search': (context, {arguments}) => OTSearchPage(arguments: arguments),
    '/danke/courseDetail': (context, {arguments}) =>
        CourseGroupDetail(arguments: arguments),
    '/danke/fullScreenEditor': (context, {arguments}) =>
        CourseReviewEditorPage(arguments: arguments)
  };

  const DanxiApp({super.key});

  Widget errorBuilder(FlutterErrorDetails details) => Builder(
      builder: (context) =>
          ErrorPageWidget.buildWidget(context, details.exception));

  /// For every Flutter widget class, you need to override the build() method.
  /// The build() method returns a [Widget] that will be displayed on the screen.
  @override
  Widget build(BuildContext context) {
    // We use [GlobalKey] to get the navigator state of the root navigator.
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    // Replace the global error widget with a simple Text.
    if (!kDebugMode) ErrorWidget.builder = errorBuilder;

    // We use [PlatformProvider] to make the app adapt to different platforms.
    // For example, on Android, it will use Material Design, while on iOS, it
    // will use Cupertino Design.
    //
    // You may find [PlatformX] in `lib/util/platform_universal.dart` useful to
    // get the current platform.
    Widget mainApp = PlatformProvider(
      // Uncomment this line below to force the app to use Cupertino Widgets.
      // initialPlatform: TargetPlatform.iOS,

      // [DynamicThemeController] enables the app to change between dark/light
      // theme without restart on iOS.
      builder: (BuildContext context) {
        MaterialColor primarySwatch =
            context.select<SettingsProvider, MaterialColor>((value) =>
                generateMaterialColor(color: Color(value.primarySwatch)));
        return DynamicThemeController(
          lightTheme: Constant.lightTheme(
              PlatformX.isCupertino(context), primarySwatch),
          darkTheme:
              Constant.darkTheme(PlatformX.isCupertino(context), primarySwatch),
          child: Material(
            child: PlatformApp(
              // Remember? We have just defined this scroll behavior class above
              // to enable scrolling with mouse & stylus.
              scrollBehavior: TouchMouseScrollBehavior(),
              debugShowCheckedModeBanner: false,
              // Fix cupertino UI text color issue by override text color
              cupertino: (context, __) => CupertinoAppData(
                  theme: CupertinoThemeData(
                      brightness: context
                          .select<SettingsProvider, ThemeType>(
                              (s) => s.themeType)
                          .getBrightness(),
                      textTheme: CupertinoTextThemeData(
                          textStyle: TextStyle(
                              color: PlatformX.getTheme(context, primarySwatch)
                                  .textTheme
                                  .bodyLarge!
                                  .color)))),
              material: (context, __) => MaterialAppData(
                  theme: PlatformX.getTheme(context, primarySwatch)),
              // Configure i18n delegates.
              localizationsDelegates: const [
                // [S] is a generated class that contains all the strings in the
                // app for l10n.
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate
              ],
              locale: LanguageManager.toLocale(
                  context.watch<SettingsProvider>().language),
              supportedLocales: S.delegate.supportedLocales,
              onUnknownRoute: (settings) => throw AssertionError(
                  "ERROR: onUnknownRoute() has been called inside the root navigator.\nDevelopers are not supposed to push on this Navigator. There should be something wrong in the code."),
              home: ThemedSystemOverlay(
                child: PlatformMasterDetailApp(
                  // Configure the page route behaviour of the whole app.
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
                  navigatorKey: navigatorKey,
                ),
              ),
            ),
          ),
        );
      },
    );

    if (PlatformX.isAndroid || PlatformX.isIOS) {
      // Wrap mainApp with [FGBGNotifier] to listen to ForeGround / BackGround events.
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

    // Init FDUHoleProvider. This object provides some global states about
    // FDUHole such as the current division and the json web token.
    var fduHoleProvider = ForumProvider();
    // Init ForumRepository with the provider. This is the api implementations of the forum.
    ForumProvider.init(fduHoleProvider);

    // Wrap the whole app with [Phoenix] to enable fast reload. When user
    // logouts the Fudan UIS account, the whole app will be reloaded.
    //
    // You can call FlutterApp.restartApp() to refresh the app.
    return Phoenix(
      // Wrap the app with a global state management provider. As the name
      // suggests, it groups multiple providers.
      child: MultiProvider(providers: [
        ChangeNotifierProvider.value(value: SettingsProvider.getInstance()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider.value(value: fduHoleProvider)
      ], child: mainApp),
    );
  }
}
