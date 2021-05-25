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

import 'dart:ffi';

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
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
  List<String> sequence;

  @override
  Widget build(BuildContext context) {
    sequence = SettingsProvider.of(_preferences).dashboardWidgetsSequence;
    print(sequence);
    return PlatformScaffold(
      iosContentBottomPadding: true,
      iosContentPadding: true,
      appBar: PlatformAppBarX(title: Text("title")),
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: WithScrollbar(
          child: Material(
            child: Expanded(
              child: ReorderableListView(
                primary: true,
                children: _getListWidgets() +
                    [
                      Padding(
                        key: UniqueKey(),
                        padding:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                        child: ListTile(
                          leading: Icon(PlatformIcons(context).addCircled),
                          title: Text("Add new_card"),
                          onTap: () {
                            sequence.add("new_card");
                            SettingsProvider.of(_preferences)
                                .dashboardWidgetsSequence = sequence;
                            setState(() {});
                          },
                        ),
                      ),
                      Padding(
                        key: UniqueKey(),
                        padding:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                        child: ListTile(
                          leading: Icon(PlatformIcons(context).addCircled),
                          title: Text("Add divider"),
                          onTap: () {
                            sequence.add("divider");
                            SettingsProvider.of(_preferences)
                                .dashboardWidgetsSequence = sequence;
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) --newIndex;
                  String tmp = sequence[oldIndex];
                  sequence.removeAt(oldIndex);
                  sequence.insert(newIndex, tmp);
                  SettingsProvider.of(_preferences).dashboardWidgetsSequence =
                      sequence;
                  setState(() {});
                },
              ),
            ),
          ),
          controller: PrimaryScrollController.of(context),
        ),
      ),
    );
  }

  List<Widget> _getListWidgets() {
    List<Widget> _widgets = [];
    int currentIndex = 0;
    sequence.forEach((element) {
      _widgets.add(Dismissible(
        key: UniqueKey(),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: ListTile(
            title: Text((element == 'new_card' ? '' : '\t\t') + element),
          ),
        ),
        onDismissed: (direction) {
          sequence.removeAt(currentIndex);
        },
      ));
      ++currentIndex;
    });
    return _widgets;
  }

  @override
  void didChangeDependencies() {
    _preferences = widget.arguments['preferences'];
    super.didChangeDependencies();
  }
}
