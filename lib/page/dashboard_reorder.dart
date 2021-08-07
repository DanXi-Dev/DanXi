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
import 'package:dan_xi/model/dashboard_card.dart';
import 'package:dan_xi/page/subpage_main.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/new_shortcut_widget_dialog.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class DashboardReorderPage extends StatefulWidget {
  /// 'items': A list of [LicenseItem] to display on the page
  final Map<String, dynamic> arguments;

  const DashboardReorderPage({Key key, this.arguments}) : super(key: key);

  @override
  _DashboardReorderPage createState() => _DashboardReorderPage();
}

const List<String> NONFUNCTIONAL_WIDGET_LIST = ['divider', 'new_card'];

class _DashboardReorderPage extends State<DashboardReorderPage> {
  List<DashboardCard> sequence;

  @override
  Widget build(BuildContext context) {
    sequence = SettingsProvider.getInstance().dashboardWidgetsSequence;

    return PlatformScaffold(
      iosContentBottomPadding: false,
      iosContentPadding: false,
      appBar: PlatformAppBarX(title: Text(S.of(context).dashboard_layout)),
      body: SafeArea(
        child: Material(
          child: WithScrollbar(
            child: ReorderableListView(
              buildDefaultDragHandles: true,
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
                          sequence
                              .add(DashboardCard("new_card", null, null, true));
                          SettingsProvider.getInstance()
                              .dashboardWidgetsSequence = sequence;
                          RefreshHomepageEvent(queueRefresh: true).fire();
                          refreshSelf();
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
                          sequence.add(
                            DashboardCard("divider", null, null, true),
                          );
                          SettingsProvider.getInstance()
                              .dashboardWidgetsSequence = sequence;
                          RefreshHomepageEvent(queueRefresh: true).fire();
                          refreshSelf();
                        },
                      ),
                    ),
                    Padding(
                      key: UniqueKey(),
                      padding:
                          EdgeInsets.symmetric(vertical: 2, horizontal: 16),
                      child: ListTile(
                        leading: Icon(PlatformIcons(context).addCircled),
                        title: Text(S.of(context).new_shortcut_card),
                        onTap: () {
                          showPlatformDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (BuildContext context) =>
                                  NewShortcutDialog(
                                    sharedPreferences:
                                        SettingsProvider.getInstance()
                                            .preferences,
                                  )).then((value) => refreshSelf());
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
                          await SettingsProvider.getInstance()
                              .preferences
                              .remove(SettingsProvider.KEY_DASHBOARD_WIDGETS);
                          RefreshHomepageEvent(queueRefresh: true).fire();
                          refreshSelf();
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
                DashboardCard tmp = sequence[oldIndex];
                sequence.removeAt(oldIndex);
                sequence.insert(newIndex, tmp);
                SettingsProvider.getInstance().dashboardWidgetsSequence =
                    sequence;
                RefreshHomepageEvent(queueRefresh: true).fire();
                refreshSelf();
              },
            ),
            controller: PrimaryScrollController.of(context),
          ),
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
      'pe_feature': S.of(context).pe_exercises,
      'bus_feature': S.of(context).bus_query,
    };
    List<Widget> _widgets = [];

    for (int index = 0; index < sequence.length; ++index) {
      // Nonfunctional Widgets
      if (NONFUNCTIONAL_WIDGET_LIST.contains(sequence[index].internalString)) {
        _widgets.add(Dismissible(
          key: UniqueKey(),
          // Show a red background as the item is swiped away.
          background: Container(color: Colors.red),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            child: ListTile(
              title: Text(widgetName[sequence[index].internalString]),
              trailing: Icon(Icons.drag_handle_rounded),
              //leading: Icon(SFSymbols.arrow_left_right_circle),
            ),
          ),
          onDismissed: (direction) {
            sequence.removeAt(index);
            SettingsProvider.getInstance().dashboardWidgetsSequence = sequence;
            RefreshHomepageEvent(queueRefresh: true).fire();
            setState(() {});
          },
        ));
      }

      // Custom Widgets
      else if (sequence[index].internalString == 'custom_card') {
        _widgets.add(
          Dismissible(
            key: UniqueKey(),
            // Show a red background as the item is swiped away.
            background: Container(color: Colors.red),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              child: CheckboxListTile(
                title: Text(sequence[index].title),
                subtitle: Text(sequence[index].link),
                secondary: PlatformX.isDesktop
                    ? null
                    : Icon(Icons.drag_handle_rounded),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (bool value) {
                  sequence[index].enabled = value;
                  SettingsProvider.getInstance().dashboardWidgetsSequence =
                      sequence;
                  RefreshHomepageEvent(queueRefresh: true).fire();
                  setState(() {});
                },
                value: sequence[index].enabled,
              ),
            ),
            onDismissed: (direction) {
              sequence.removeAt(index);
              SettingsProvider.getInstance().dashboardWidgetsSequence =
                  sequence;
              RefreshHomepageEvent(queueRefresh: true).fire();
              setState(() {});
            },
          ),
        );
      }

      // Default widgets
      else {
        _widgets.add(
          Dismissible(
            key: UniqueKey(),
            confirmDismiss: (_) => Future.value(false),
            background: Center(child: Text(S.of(context).unmovable_widget)),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              child: CheckboxListTile(
                title: Text(widgetName[sequence[index].internalString]),
                controlAffinity: ListTileControlAffinity.leading,
                secondary: Icon(Icons.drag_handle_rounded),
                onChanged: (bool value) {
                  sequence[index].enabled = value;
                  SettingsProvider.getInstance().dashboardWidgetsSequence =
                      sequence;
                  RefreshHomepageEvent(queueRefresh: true).fire();
                  refreshSelf();
                },
                value: sequence[index].enabled,
              ),
            ),
          ),
        );
      }
    }
    return _widgets;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }
}
