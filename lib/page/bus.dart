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
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/data_center_repository.dart';
import 'package:dan_xi/repository/fudan_bus_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/top_controller.dart';
import 'package:dan_xi/widget/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BusPage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  @override
  _BusPageState createState() => _BusPageState();

  BusPage({Key key, this.arguments});
}

class _BusPageState extends State<BusPage> {
  PersonInfo _personInfo;
  List<BusScheduleItem> _busList;
  List<BusScheduleItem> _filteredBusList;
  Campus _selectItem = Campus.NONE;
  int _sliding;

  // By default, only buses after DateTime.now() is displayed
  // Set this to true to display all buses
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _personInfo = widget.arguments['personInfo'];
    _busList = widget.arguments['busList'];
    SharedPreferences.getInstance().then((preferences) {
      _selectItem = SettingsProvider.of(preferences).campus;
      _sliding = _selectItem.index;
      _onSelectedItemChanged(_selectItem);
    });
  }

  void _onSelectedItemChanged(Campus e) {
    setState(() {
      _showAll = false;
      _selectItem = e;
      _filteredBusList = _busList
          .where((element) => element.start == e || element.end == e)
          .toList();
    });
  }

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
          SizedBox(
            height: PlatformX.isMaterial(context) ? 0 : 10,
          ),
          PlatformWidget(
              material: (_, __) => DropdownButton<Campus>(
                    items: _getItems(),
                    // Don't select anything if _selectItem == Campus.NONE
                    value: _selectItem == Campus.NONE ? null : _selectItem,
                    hint: Text(_selectItem.displayTitle(context)),
                    onChanged: (Campus e) => _onSelectedItemChanged(e),
                  ),
              cupertino: (_, __) => CupertinoSlidingSegmentedControl<int>(
                    onValueChanged: (int value) {
                      _sliding = value;
                      _onSelectedItemChanged(Campus.values[_sliding]);
                    },
                    groupValue: _sliding,
                    children: _getCupertinoItems(),
                  )),
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

  List<DropdownMenuItem> _getItems() => Constant.CAMPUS_VALUES.map((e) {
        return DropdownMenuItem(value: e, child: Text(e.displayTitle(context)));
      }).toList(growable: false);

  Map<int, Text> _getCupertinoItems() => Constant.CAMPUS_VALUES
      .map((e) => Text(e.displayTitle(context)))
      .toList(growable: false)
      .asMap();

  List<Widget> _getListWidgets() {
    final currentTime = DateTime.now();
    List<Widget> widgets = [
      if (!_showAll)
        Card(
          child: ListTile(
            leading: Icon(PlatformIcons(context).info),
            title: Text(S.of(context).school_bus_not_showing_all(
                currentTime.hour, currentTime.minute)),
            subtitle: Text(S.of(context).school_bus_tap_to_show_all),
            onTap: () => setState(() {
              _showAll = true;
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
