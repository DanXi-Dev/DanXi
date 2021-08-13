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

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:catcher/catcher.dart';
import 'package:dan_xi/common/Secret.dart';
import 'package:dan_xi/feature/feature_map.dart';
import 'package:dan_xi/master_detail/master_detail_view.dart';
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
import 'package:dan_xi/page/home_page.dart';
import 'package:dan_xi/page/image_viewer.dart';
import 'package:dan_xi/page/open_source_license.dart';
import 'package:dan_xi/page/subpage_bbs.dart';
import 'package:dan_xi/page/text_selector.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/util/bmob/bmob/bmob.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/bbs_editor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'generated/l10n.dart';

/// The main entry of the whole app.
/// Do some initiative work here.
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
  Bmob.init("https://api2.bmob.cn", Secret.APP_ID, Secret.API_KEY);
  // Init Feature registration.
  FeatureMap.registerAllFeatures();
  SettingsProvider.getInstance().init().then((_) {
    Catcher(
        rootWidget: DanxiApp(),
        debugConfig: debugOptions,
        releaseConfig: releaseOptions);
  });
  if (PlatformX.isDesktop)
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
          data: PlatformX.getTheme(context),
          child: PlatformApp(
            title: '旦夕',
            debugShowCheckedModeBanner: false,
            // Fix cupertino UI text color issues
            cupertino: (_, __) => CupertinoAppData(
                theme: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                        textStyle: TextStyle(
                            color: PlatformX.getTheme(context)
                                .textTheme
                                .bodyText1
                                .color)))),
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
              final Function pageContentBuilder =
                  DanxiApp.routes[settings.name];
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
  }
}
