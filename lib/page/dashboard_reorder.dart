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
import 'package:dan_xi/page/subpage_main.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:dan_xi/public_extension_methods.dart';
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

    return PlatformScaffold(
      iosContentBottomPadding: true,
      iosContentPadding: true,
      appBar: PlatformAppBarX(title: Text(S.of(context).dashboard_layout)),
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: WithScrollbar(
          child: Material(
            child: ReorderableListView(
              primary: true,
              children: _getListWidgets() +
                  [
                    Padding(
                      key: UniqueKey(),
                      padding:
                          EdgeInsets.symmetric(vertical: 2, horizontal: 16),
                      child: ListTile(
                        leading: Icon(PlatformIcons(context).addCircled),
                        title: Text(S.of(context).add_new_card),
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
                          EdgeInsets.symmetric(vertical: 2, horizontal: 16),
                      child: ListTile(
                        leading: Icon(PlatformIcons(context).addCircled),
                        title: Text(S.of(context).add_new_divider),
                        onTap: () {
                          sequence.add("divider");
                          SettingsProvider.of(_preferences)
                              .dashboardWidgetsSequence = sequence;
                          setState(() {});
                        },
                      ),
                    ),
                    Padding(
                      key: UniqueKey(),
                      padding:
                          EdgeInsets.symmetric(vertical: 2, horizontal: 16),
                      child: ListTile(
                        leading: Icon(PlatformIcons(context).removeCircled),
                        title: Text(S.of(context).reset_layout),
                        onTap: () async {
                          await _preferences
                              .remove(SettingsProvider.KEY_DASHBOARD_WIDGETS);
                          setState(() {});
                        },
                      ),
                    ),
                  ],
              onReorder: (oldIndex, newIndex) {
                if (oldIndex >= sequence.length) {
                  Noticing.showNotice(context, S.of(context).unmovable_widget);
                  return;
                }
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
          controller: PrimaryScrollController.of(context),
        ),
      ),
    );
  }

  List<Widget> _getListWidgets() {
    Map<String, String> widgetName = {
      'welcome_feature': S.of(context).welcome_feature,
      'next_course_feature': S.of(context).today_course,
      'divider': S.of(context).divider,
      'ecard_balance_feature': S.of(context).ecard_balance,
      'dining_hall_crowdedness_feature': S.of(context).dining_hall_crowdedness,
      'aao_notice_feature': S.of(context).fudan_aao_notices,
      'empty_classroom_feature': S.of(context).empty_classrooms,
      'fudan_daily_feature': S.of(context).fudan_daily,
      'new_card': S.of(context).add_new_card,
      'qr_feature': S.of(context).fudan_qr_code,
    };
    List<Widget> _widgets = [
      Padding(
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          child: Text(S.of(context).reorder_hint)),
      Divider(),
    ];

    for (int index = 0; index < sequence.length; ++index) {
      _widgets.add(Dismissible(
        key: ValueKey(index),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          child: ListTile(
            title: Text((sequence[index] == 'new_card' ? '' : '    ') +
                widgetName[sequence[index]]),
          ),
        ),
        onDismissed: (direction) {
          print(index);
          sequence.removeAt(index);
          SettingsProvider.of(_preferences).dashboardWidgetsSequence = sequence;
        },
      ));
    }
    return _widgets;
  }

  @override
  void didChangeDependencies() {
    _preferences = widget.arguments['preferences'];
    super.didChangeDependencies();
  }
}
