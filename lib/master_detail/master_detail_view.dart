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

import 'package:dan_xi/main.dart';
import 'package:dan_xi/master_detail/master_detail_utils.dart';
import 'package:dan_xi/page/home_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class MasterDetailController extends StatelessWidget {
  final Widget? masterPage;

  MasterDetailController({Key? key, this.masterPage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isTablet(context)) {
      return masterPage!;
    }
    return Container(
      color: Theme.of(context).backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
              width: kTabletMasterContainerWidth,
              height: MediaQuery.of(context).size.height,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                  border: Border(
                      right: BorderSide(
                          width: 1, color: Theme.of(context).dividerColor))),
              child: masterPage),
          Container(
              width: MediaQuery.of(context).size.width -
                  kTabletMasterContainerWidth,
              height: MediaQuery.of(context).size.height,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(),
              child: Navigator(
                key: detailNavigatorKey,
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
                initialRoute: '/placeholder',
              ))
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
  }
  return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
}
