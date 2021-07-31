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
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/fudan_bus_repository.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/top_controller.dart';
import 'package:dan_xi/widget/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BusPage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  @override
  _BusPageState createState() => _BusPageState();

  BusPage({Key key, this.arguments});
}

class _BusPageState extends State<BusPage> {
  List<BusScheduleItem> _busList;
  List<BusScheduleItem> _filteredBusList;

  // Start Location
  Campus _startSelectItem = Campus.NONE;
  int _startSliding;

  // End Location
  Campus _endSelectItem = Campus.NONE;
  int _endSliding;

  // By default, only buses after DateTime.now() is displayed
  // Set this to true to display all buses
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _busList = widget.arguments['busList'];

    // Normalize all entries
    _busList.forEach((element) {
      if (element.direction == BusDirection.BACKWARD) {
        final start = element.start;
        element.start = element.end;
        element.end = start;
        final startTime = element.startTime;
        element.startTime = element.endTime;
        element.endTime = startTime;
        element.direction = BusDirection.FORWARD;
      }
    });

    // Default to Handan
    _startSelectItem = Campus.HANDAN_CAMPUS;
    _startSliding = _startSelectItem.index;
    _onStartLocationChanged(_startSelectItem);

    SharedPreferences.getInstance().then((preferences) {
      _endSelectItem = SettingsProvider.of(preferences).campus;
      _endSliding = _endSelectItem.index;
      _onEndLocationChanged(_endSelectItem);
    });
  }

  void _onStartLocationChanged(Campus e) {
    setState(() {
      _startSelectItem = e;
      _filteredBusList = _busList
          .where((element) =>
              element.start == _startSelectItem &&
              element.end == _endSelectItem)
          .toList();
    });
  }

  void _onEndLocationChanged(Campus e) {
    setState(() {
      _endSelectItem = e;
      _filteredBusList = _busList
          .where((element) =>
              element.start == _startSelectItem &&
              element.end == _endSelectItem)
          .toList();
    });
  }

  List<DropdownMenuItem> _getItems() => Constant.CAMPUS_VALUES.map((e) {
        return DropdownMenuItem(value: e, child: Text(e.displayTitle(context)));
      }).toList(growable: false);

  Map<int, Text> _getCupertinoItems() => Constant.CAMPUS_VALUES
      .map((e) => Text(e.displayTitle(context)))
      .toList(growable: false)
      .asMap();

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      iosContentBottomPadding: true,
      iosContentPadding: true,
      appBar: PlatformAppBarX(
          title: TopController(
              controller: PrimaryScrollController.of(context),
              child: Text(S.of(context).bus_query))),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(S.of(context).bus_start),
              PlatformWidget(
                material: (_, __) => DropdownButton<Campus>(
                  items: _getItems(),
                  // Don't select anything if _selectItem == Campus.NONE
                  value:
                      _startSelectItem == Campus.NONE ? null : _startSelectItem,
                  hint: Text(_startSelectItem.displayTitle(context)),
                  onChanged: (Campus e) => _onStartLocationChanged(e),
                ),
                cupertino: (_, __) => Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 4),
                  child: CupertinoSlidingSegmentedControl<int>(
                    onValueChanged: (int value) {
                      _startSliding = value;
                      _onStartLocationChanged(Campus.values[_startSliding]);
                    },
                    groupValue: _startSliding,
                    children: _getCupertinoItems(),
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(S.of(context).bus_dest),
              PlatformWidget(
                material: (_, __) => DropdownButton<Campus>(
                  items: _getItems(),
                  // Don't select anything if _selectItem == Campus.NONE
                  value: _endSelectItem == Campus.NONE ? null : _endSelectItem,
                  hint: Text(_endSelectItem.displayTitle(context)),
                  onChanged: (Campus e) => _onEndLocationChanged(e),
                ),
                cupertino: (_, __) => Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 4),
                  child: CupertinoSlidingSegmentedControl<int>(
                    onValueChanged: (int value) {
                      _endSliding = value;
                      _onEndLocationChanged(Campus.values[_endSliding]);
                    },
                    groupValue: _endSliding,
                    children: _getCupertinoItems(),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
              child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: WithScrollbar(
                    controller: PrimaryScrollController.of(context),
                    child: ListView(
                      physics: AlwaysScrollableScrollPhysics(),
                      primary: true,
                      children: _getListWidgets(),
                    ),
                  )))
        ],
      ),
    );
  }

  List<Widget> _getListWidgets() {
    final currentTime = DateTime.now();
    final format = NumberFormat("00");
    List<Widget> widgets = [
      Card(
        child: ListTile(
          leading: Icon(PlatformIcons(context).info),
          title: Text(_showAll
              ? S.of(context).school_bus_showing_all
              : S.of(context).school_bus_not_showing_all(
                  format.format(currentTime.hour),
                  format.format(currentTime.minute))),
          subtitle: Text(_showAll
              ? S.of(context).school_bus_tap_to_not_show_all(
                  format.format(currentTime.hour),
                  format.format(currentTime.minute))
              : S.of(context).school_bus_tap_to_show_all),
          onTap: () => setState(() {
            _showAll = !_showAll;
          }),
        ),
      )
    ];
    if (_filteredBusList == null) return [Container()];
    _filteredBusList.forEach((value) {
      if (_showAll ||
          value.realStartTime == null ||
          value.realStartTime.toExactTime().isAfter(currentTime))
        widgets.add(_buildBusCard(value));
    });
    return widgets;
  }

  Card _buildBusCard(BusScheduleItem item) {
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      item.start.displayTitle(context),
                      textScaleFactor: 1.2,
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(item.startTime?.toDisplayFormat() ?? ""),
                  ],
                ),
                Text(
                  item.direction.toText(),
                  textScaleFactor: 1.5,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      item.end.displayTitle(context),
                      textScaleFactor: 1.2,
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(item.endTime?.toDisplayFormat() ?? ""),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
