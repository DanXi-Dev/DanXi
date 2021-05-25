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

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardReorderPage extends StatefulWidget {
  /// 'items': A list of [LicenseItem] to display on the page
  final Map<String, dynamic> arguments;

  const DashboardReorderPage({Key key, this.arguments}) : super(key: key);

  @override
  _DashboardReorderPage createState() => _DashboardReorderPage();
}

class _DashboardReorderPage extends State<DashboardReorderPage> {
  SharedPreferences _preferences;

  @override
  Widget build(BuildContext context) {
    List<String> sequence =
        SettingsProvider.of(_preferences).dashboardWidgetsSequence;
    return PlatformScaffold(
      iosContentBottomPadding: true,
      iosContentPadding: true,
      appBar: PlatformAppBarX(title: Text("title")),
      body: Column(children: [
        Expanded(
            child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: WithScrollbar(
                  child: ReorderableListView(
                    scrollController: PrimaryScrollController.of(context),
                    children: _getListWidgets(sequence),
                    onReorder: (oldIndex, newIndex) {
                      String tmp = sequence[oldIndex];
                      sequence[oldIndex] = sequence[newIndex];
                      sequence[newIndex] = tmp;
                      SettingsProvider.of(_preferences)
                          .dashboardWidgetsSequence = sequence;

                      setState(() {});
                    },
                  ),
                  controller: PrimaryScrollController.of(context),
                ))),
      ]),
    );
  }

  List<Widget> _getListWidgets(List<String> widgetSequence) {
    List<Widget> _widgets = [];
    widgetSequence.forEach((element) {
      _widgets.add(Material(
        key: UniqueKey(),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: ListTile(
            title: Text((element == 'seperate_card' ? '' : '  ') + element),
          ),
        ),
      ));
    });
    return _widgets;
  }

  @override
  void didChangeDependencies() {
    _preferences = widget.arguments['preferences'];
    super.didChangeDependencies();
  }
}
