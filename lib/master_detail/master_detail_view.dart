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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/main.dart';
import 'package:dan_xi/master_detail/master_detail_utils.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/repository/fudan_aao_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/material_x.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/top_controller.dart';
import 'package:dan_xi/widget/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';

class MasterDetailController extends StatefulWidget {
  final Widget masterPage;

  @override
  MasterDetailControllerState createState() => MasterDetailControllerState();

  MasterDetailController({Key key, this.masterPage}) : super(key: key);
}

class MasterDetailControllerState extends State<MasterDetailController> {
  Widget masterPage;

  @override
  void initState() {
    super.initState();
    masterPage = widget.masterPage;
  }

  @override
  Widget build(BuildContext context) {
    if (!isTablet(context)) {
      return masterPage;
    }
    return Container(
        color: Theme.of(context).backgroundColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
                width: kTabletMasterContainerWidth,
                height: MediaQuery.of(context).size.height,
                child: masterPage),
            SizedBox(
                width: MediaQuery.of(context).size.width -
                    kTabletMasterContainerWidth,
                height: MediaQuery.of(context).size.height,
                child: Navigator(
                  key: detailNavigatorKey,
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
                  initialRoute: '/placeholder',
                ))
          ],
        ));
  }
}

Future<T> smartNavigatorPush<T extends Object>(
    BuildContext context, String routeName,
    {Object arguments}) {
  if (isTablet(context)) {
    return detailNavigatorKey.currentState
        .pushNamed(routeName, arguments: arguments);
  }
  return Navigator.of(context).pushNamed(routeName, arguments: arguments);
}
