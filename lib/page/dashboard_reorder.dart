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
import 'package:dan_xi/widget/new_shortcut_widget_dialog.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/with_scrollbar.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:html_editor_enhanced/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardReorderPage extends StatefulWidget {
  /// 'items': A list of [LicenseItem] to display on the page
  final Map<String, dynamic> arguments;

  const DashboardReorderPage({Key key, this.arguments}) : super(key: key);

  @override
  _DashboardReorderPage createState() => _DashboardReorderPage();
}

const List<String> NONFUNCTIONAL_WIDGET_LIST = ['divider', 'new_card'];
String getWidgetStringFromSettings(String value) {
  RegExpMatch match = RegExp(r'n:[a-z_]+').firstMatch(value);
  if (match == null) return value;
  return value.substring(match.start + 2, match.end);
}

bool getWidgetEnabledStatusFromSettings(String value) {
  return !value.contains('s:disabled');
}

String getCustomWidgetTitleFromSettings(String value) {
  // TODO: Potential bug in getting title
  RegExpMatch match = RegExp(r't:[^(s:)]+').firstMatch(value);
  if (match == null) return value;
  return value.substring(match.start + 2, match.end);
}

String getCustomWidgetLinkFromSettings(String value) {
  RegExpMatch match = RegExp(r'l:[^ ]+').firstMatch(value);
  if (match == null) return value;
  print("saved url: ${value.substring(match.start + 2, match.end)}");
  return value.substring(match.start + 2, match.end);
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
            child: Column(
              children: [
                Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    child: Text(S.of(context).reorder_hint)),
                Divider(
                  height: 2,
                ),
                Expanded(
                  child: ReorderableListView(
                    primary: true,
                    children: _getListWidgets() +
                        [
                          Padding(
                            key: UniqueKey(),
                            padding: EdgeInsets.symmetric(
                                vertical: 2, horizontal: 16),
                            child: ListTile(
                              leading: Icon(PlatformIcons(context).addCircled),
                              title: Text(S.of(context).new_shortcut_card),
                              onTap: () {
                                showPlatformDialog(
                                    context: context,
                                    barrierDismissible: true,
                                    builder: (BuildContext context) =>
                                        NewShortcutDialog(
                                          sharedPreferences: _preferences,
                                        )).then((value) => refreshSelf());
                              },
                            ),
                          ),
                          Padding(
                            key: UniqueKey(),
                            padding: EdgeInsets.symmetric(
                                vertical: 2, horizontal: 16),
                            child: ListTile(
                              leading: Icon(PlatformIcons(context).addCircled),
                              title: Text(S.of(context).add_new_card),
                              onTap: () {
                                sequence.add("n:new_card");
                                SettingsProvider.of(_preferences)
                                    .dashboardWidgetsSequence = sequence;
                                RefreshHomepageEvent(queueRefresh: true).fire();
                                refreshSelf();
                              },
                            ),
                          ),
                          Padding(
                            key: UniqueKey(),
                            padding: EdgeInsets.symmetric(
                                vertical: 2, horizontal: 16),
                            child: ListTile(
                              leading: Icon(PlatformIcons(context).addCircled),
                              title: Text(S.of(context).add_new_divider),
                              onTap: () {
                                sequence.add("n:divider");
                                SettingsProvider.of(_preferences)
                                    .dashboardWidgetsSequence = sequence;
                                RefreshHomepageEvent(queueRefresh: true).fire();
                                refreshSelf();
                              },
                            ),
                          ),
                          Padding(
                            key: UniqueKey(),
                            padding: EdgeInsets.symmetric(
                                vertical: 2, horizontal: 16),
                            child: ListTile(
                              leading:
                                  Icon(PlatformIcons(context).removeCircled),
                              title: Text(S.of(context).reset_layout),
                              onTap: () async {
                                await _preferences.remove(
                                    SettingsProvider.KEY_DASHBOARD_WIDGETS);
                                RefreshHomepageEvent(queueRefresh: true).fire();
                                refreshSelf();
                              },
                            ),
                          ),
                        ],
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex >= sequence.length) {
                        Noticing.showNotice(
                            context, S.of(context).unmovable_widget);
                        return;
                      }
                      if (newIndex > oldIndex) --newIndex;
                      String tmp = sequence[oldIndex];
                      sequence.removeAt(oldIndex);
                      sequence.insert(newIndex, tmp);
                      SettingsProvider.of(_preferences)
                          .dashboardWidgetsSequence = sequence;
                      RefreshHomepageEvent(queueRefresh: true).fire();
                      refreshSelf();
                    },
                  ),
                )
              ],
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
    List<Widget> _widgets = [];

    print(sequence);

    for (int index = 0; index < sequence.length; ++index) {
      // Nonfunctional Widgets
      if (NONFUNCTIONAL_WIDGET_LIST
          .contains(getWidgetStringFromSettings(sequence[index]))) {
        _widgets.add(Dismissible(
          key: ValueKey(index),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            child: ListTile(
              title: Text(
                  (getWidgetStringFromSettings(sequence[index]) == 'divider'
                          ? '            '
                          : '') +
                      widgetName[getWidgetStringFromSettings(sequence[index])]),
            ),
          ),
          onDismissed: (direction) {
            sequence.removeAt(index);
            SettingsProvider.of(_preferences).dashboardWidgetsSequence =
                sequence;
            RefreshHomepageEvent(queueRefresh: true).fire();
            refreshSelf();
          },
        ));
      }

      // Custom Widgets
      else if (getWidgetStringFromSettings(sequence[index]) == 'custom_card') {
        _widgets.add(
          Dismissible(
            key: ValueKey(index),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              child: CheckboxListTile(
                title: Text(getCustomWidgetTitleFromSettings(sequence[index])),
                subtitle:
                    Text(getCustomWidgetLinkFromSettings(sequence[index])),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (bool value) {
                  sequence[index] = _generateWidgetStatusSettingsString(
                      sequence[index], value);
                  SettingsProvider.of(_preferences).dashboardWidgetsSequence =
                      sequence;
                  RefreshHomepageEvent(queueRefresh: true).fire();
                  refreshSelf();
                },
                value: getWidgetEnabledStatusFromSettings(sequence[index]),
              ),
            ),
          ),
        );
      }

      // Default widgets
      else {
        _widgets.add(
          Padding(
            key: ValueKey(index),
            padding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            child: CheckboxListTile(
              title: Text(
                  widgetName[getWidgetStringFromSettings(sequence[index])]),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (bool value) {
                sequence[index] =
                    _generateWidgetStatusSettingsString(sequence[index], value);
                SettingsProvider.of(_preferences).dashboardWidgetsSequence =
                    sequence;
                RefreshHomepageEvent(queueRefresh: true).fire();
                refreshSelf();
              },
              value: getWidgetEnabledStatusFromSettings(sequence[index]),
            ),
          ),
        );
      }
    }
    return _widgets;
  }

  String _generateWidgetStatusSettingsString(String original, bool newStatus) {
    if (newStatus) {
      if (original.contains('s:disabled'))
        return original.replaceAll('s:disabled', '').trim();
    } else {
      if (!original.contains('s:disabled'))
        return (original + ' s:disabled').trim();
    }
    return original;
  }

  @override
  void didChangeDependencies() {
    _preferences = widget.arguments['preferences'];
    super.didChangeDependencies();
  }
}
