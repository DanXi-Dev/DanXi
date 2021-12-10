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

import 'dart:ui';

import 'package:catcher/core/catcher.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/main.dart';
import 'package:dan_xi/util/master_detail_utils.dart';
import 'package:dan_xi/page/home_page.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class MasterDetailController extends StatelessWidget {
  final Widget? masterPage;

  MasterDetailController({Key? key, this.masterPage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isTablet(context)) {
      return masterPage!;
    }
    return Directionality(
      textDirection: TextDirection.ltr, //TODO: Hardcoded TextDirection
      child: Container(
        color: Theme.of(context).backgroundColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            MediaQuery(
              data: MediaQueryData.fromWindow(window).copyWith(
                size: Size(
                  kTabletMasterContainerWidth,
                  window.physicalSize.height,
                ),
              ),
              child: Container(
                width: kTabletMasterContainerWidth,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                    border: Border(
                        right: BorderSide(
                            width: 1, color: Theme.of(context).dividerColor))),
                child: PlatformApp(
                  useInheritedMediaQuery: true,
                  scrollBehavior: MyCustomScrollBehavior(),
                  debugShowCheckedModeBanner: false,
                  // Fix cupertino UI text color issues
                  cupertino: (context, __) => CupertinoAppData(
                      theme: CupertinoThemeData(
                          textTheme: CupertinoTextThemeData(
                              textStyle: TextStyle(
                                  color: PlatformX.getTheme(context)
                                      .textTheme
                                      .bodyText1!
                                      .color)))),
                  // Configure i18n delegates
                  localizationsDelegates: [
                    S.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate
                  ],
                  supportedLocales: S.delegate.supportedLocales,
                  home: masterPage,
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
            Expanded(
              child: Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(),
                child: MediaQuery(
                  data: MediaQueryData.fromWindow(window).copyWith(
                    size: Size(
                      window.physicalSize.width - kTabletMasterContainerWidth,
                      window.physicalSize.height,
                    ),
                  ),
                  child: PlatformApp(
                    useInheritedMediaQuery: true,
                    scrollBehavior: MyCustomScrollBehavior(),
                    debugShowCheckedModeBanner: false,
                    // Fix cupertino UI text color issues
                    cupertino: (context, __) => CupertinoAppData(
                        theme: CupertinoThemeData(
                            textTheme: CupertinoTextThemeData(
                                textStyle: TextStyle(
                                    color: PlatformX.getTheme(context)
                                        .textTheme
                                        .bodyText1!
                                        .color)))),
                    // Configure i18n delegates
                    localizationsDelegates: [
                      S.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate
                    ],
                    supportedLocales: S.delegate.supportedLocales,
                    home: const SizedBox(),
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
                    navigatorKey: detailNavigatorKey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> smartNavigatorPush<T extends Object>(
    BuildContext context, String routeName,
    {Object? arguments, bool forcePushOnMainNavigator = false}) {
  if (isTablet(context) && !forcePushOnMainNavigator) {
    return detailNavigatorKey.currentState!
        .pushNamed<T?>(routeName, arguments: arguments);
  }
  return Navigator.of(context).pushNamed<T?>(routeName, arguments: arguments);
}
