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
import 'package:dan_xi/model/dashboard_card.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/widget/dialogs/new_shortcut_widget_dialog.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A page allowing user to configure items on his/her dashboard.
class DashboardReorderPage extends StatefulWidget {
  /// 'items': A list of [LicenseItem] to display on the page
  final Map<String, dynamic>? arguments;

  const DashboardReorderPage({super.key, this.arguments});

  @override
  DashboardReorderPageState createState() => DashboardReorderPageState();
}

const List<String> NONFUNCTIONAL_WIDGET_LIST = [
  Constant.FEATURE_DIVIDER,
  Constant.FEATURE_NEW_CARD
];

class DashboardReorderPageState extends State<DashboardReorderPage> {
  List<DashboardCard>? sequence;

  @override
  Widget build(BuildContext context) {
    sequence = SettingsProvider.getInstance().dashboardWidgetsSequence;

    // remove invalid cards
    Map<String, String> widgetName = Constant.getFeatureName(context);
    sequence?.removeWhere((element) =>
        (element.internalString == null) ||
        (!element.isSpecialCard &&
            !widgetName.containsKey(element.internalString)));

    return PlatformScaffold(
      iosContentBottomPadding: false,
      iosContentPadding: false,
      appBar: PlatformAppBarX(title: Text(S.of(context).dashboard_layout)),
      body: SafeArea(
        bottom: false,
        child: WithScrollbar(
          controller: PrimaryScrollController.of(context),
          child: ReorderableListView(
            clipBehavior: Clip.none,
            buildDefaultDragHandles: true,
            primary: true,
            children: _getListWidgets() +
                [
                  Padding(
                    key: UniqueKey(),
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
                    child: ListTile(
                      leading: Icon(PlatformIcons(context).addCircled),
                      title: Text(S.of(context).add_new_card),
                      onTap: () {
                        sequence!.add(DashboardCard(
                            Constant.FEATURE_NEW_CARD, null, null, true));
                        SettingsProvider.getInstance()
                            .dashboardWidgetsSequence = sequence;
                        refreshSelf();
                      },
                    ),
                  ),
                  Padding(
                    key: UniqueKey(),
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
                    child: ListTile(
                      leading: Icon(PlatformIcons(context).addCircled),
                      title: Text(S.of(context).add_new_divider),
                      onTap: () {
                        sequence!.add(
                          DashboardCard(
                              Constant.FEATURE_DIVIDER, null, null, true),
                        );
                        SettingsProvider.getInstance()
                            .dashboardWidgetsSequence = sequence;
                        refreshSelf();
                      },
                    ),
                  ),
                  Padding(
                    key: UniqueKey(),
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
                    child: ListTile(
                      leading: Icon(PlatformIcons(context).addCircled),
                      title: Text(S.of(context).new_shortcut_card),
                      onTap: () {
                        showPlatformDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (BuildContext context) =>
                                    const NewShortcutDialog())
                            .then((value) => refreshSelf());
                      },
                    ),
                  ),
                  Padding(
                    key: UniqueKey(),
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
                    child: ListTile(
                      leading: Icon(PlatformIcons(context).removeCircled),
                      title: Text(S.of(context).reset_layout),
                      onTap: () async {
                        await SettingsProvider.getInstance()
                            .preferences!
                            .remove(SettingsProvider.KEY_DASHBOARD_WIDGETS);
                        refreshSelf();
                      },
                    ),
                  ),
                ],
            onReorder: (oldIndex, newIndex) {
              if (oldIndex >= sequence!.length) {
                Noticing.showNotice(context, S.of(context).unmovable_widget);
                return;
              }
              if (newIndex > oldIndex) --newIndex;
              DashboardCard tmp = sequence![oldIndex];
              sequence!.removeAt(oldIndex);
              sequence!.insert(newIndex, tmp);
              SettingsProvider.getInstance().dashboardWidgetsSequence =
                  sequence;
              refreshSelf();
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _getListWidgets() {
    Map<String, String> widgetName = Constant.getFeatureName(context);
    List<Widget> widgets = [];

    for (int index = 0; index < sequence!.length; ++index) {
      // Nonfunctional Widgets
      if (NONFUNCTIONAL_WIDGET_LIST.contains(sequence![index].internalString)) {
        widgets.add(Dismissible(
          key: UniqueKey(),
          // Show a red background as the item is swiped away.
          background: Container(color: Colors.red),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            child: ListTile(
              title: Text(widgetName[sequence![index].internalString!]!),
              trailing: const Icon(Icons.drag_handle_rounded),
              //leading: Icon(CupertinoIcons.arrow_left_right_circle),
            ),
          ),
          onDismissed: (direction) {
            sequence!.removeAt(index);
            SettingsProvider.getInstance().dashboardWidgetsSequence = sequence;
            refreshSelf();
          },
        ));
      }

      // Custom Widgets
      else if (sequence![index].internalString ==
          Constant.FEATURE_CUSTOM_CARD) {
        widgets.add(
          Dismissible(
            key: UniqueKey(),
            // Show a red background as the item is swiped away.
            background: Container(color: Colors.red),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              child: CheckboxListTile(
                title: Text(sequence![index].title!),
                subtitle: Text(sequence![index].link!),
                secondary: PlatformX.isDesktop
                    ? null
                    : const Icon(Icons.drag_handle_rounded),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (bool? value) {
                  sequence![index].enabled = value;
                  SettingsProvider.getInstance().dashboardWidgetsSequence =
                      sequence;
                  refreshSelf();
                },
                value: sequence![index].enabled,
              ),
            ),
            onDismissed: (direction) {
              sequence!.removeAt(index);
              SettingsProvider.getInstance().dashboardWidgetsSequence =
                  sequence;
              refreshSelf();
            },
          ),
        );
      }

      // Default widgets
      else {
        widgets.add(
          Dismissible(
            key: UniqueKey(),
            confirmDismiss: (_) => Future.value(false),
            background: Center(child: Text(S.of(context).unmovable_widget)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              child: CheckboxListTile(
                title: Text(widgetName[sequence![index].internalString!]!),
                controlAffinity: ListTileControlAffinity.leading,
                secondary: const Icon(Icons.drag_handle_rounded),
                onChanged: (bool? value) {
                  sequence![index].enabled = value;
                  SettingsProvider.getInstance().dashboardWidgetsSequence =
                      sequence;
                  refreshSelf();
                },
                value: sequence![index].enabled,
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }
}
