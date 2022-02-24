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

import 'package:dan_xi/page/home_page.dart';
import 'package:dan_xi/util/master_detail_utils.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

GlobalKey<NavigatorState>? navigatorGlobalKey;

class PlatformMasterDetailApp extends StatelessWidget {
  final RouteFactory? onGenerateRoute;
  final GlobalKey<NavigatorState>? navigatorKey;

  const PlatformMasterDetailApp(
      {Key? key, this.onGenerateRoute, this.navigatorKey})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    navigatorGlobalKey = navigatorKey;
    if (PlatformX.isCupertino(context)) {
      return buildView(context);
    } else {
      return WillPopScope(
          child: buildView(context),
          onWillPop: () async {
            if (isTablet(context) &&
                (detailNavigatorKey.currentState?.canPop() ?? false)) {
              detailNavigatorKey.currentState?.pop();
              return false;
            } else if (navigatorKey?.currentState?.canPop() ?? false) {
              navigatorKey?.currentState?.pop();
              return false;
            }
            return true;
          });
    }
  }

  Widget buildView(BuildContext context) {
    final Widget masterNavigatorWidget = Navigator(
      key: navigatorKey,
      onGenerateRoute: onGenerateRoute,
      initialRoute: '/home',
      observers: [HeroController()],
    );
    if (!isTablet(context)) {
      return masterNavigatorWidget;
    }
    return Container(
      color: Theme.of(context).backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          PlatformWidget(
            material: (_, __) => SizedBox(
                width: kTabletMasterContainerWidth,
                height: MediaQuery.of(context).size.height,
                child: masterNavigatorWidget),
            // Dismiss the shadow border on Cupertino
            cupertino: (_, __) => Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                  border: Border(
                      right: BorderSide(
                          width: 1, color: Theme.of(context).dividerColor))),
              width: kTabletMasterContainerWidth,
              height: MediaQuery.of(context).size.height,
              child: masterNavigatorWidget,
            ),
          ),
          Container(
            // Set an empty BoxDecoration to dismiss the shadow border on Cupertino
            decoration: const BoxDecoration(),
            clipBehavior: Clip.hardEdge,
            width:
                MediaQuery.of(context).size.width - kTabletMasterContainerWidth,
            height: MediaQuery.of(context).size.height,
            child: Navigator(
              key: detailNavigatorKey,
              onGenerateRoute: onGenerateRoute,
              initialRoute: '/placeholder',
              observers: [HeroController()],
            ),
          ),
        ],
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
  } else if (navigatorGlobalKey?.currentState != null) {
    return navigatorGlobalKey!.currentState!
        .pushNamed<T?>(routeName, arguments: arguments);
  } else {
    return Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }
}

NavigatorState? get auxiliaryNavigatorState => detailNavigatorKey.currentState;
