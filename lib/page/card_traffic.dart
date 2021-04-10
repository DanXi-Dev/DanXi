/*
 *     Copyright (C) 2021  w568w
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
import 'package:dan_xi/repository/dining_hall_crowdedness_repository.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class CardCrowdData extends StatefulWidget {
  final Map<String, dynamic> arguments;

  @override
  _CardCrowdDataState createState() => _CardCrowdDataState();

  CardCrowdData({Key key, this.arguments});
}

class _CardCrowdDataState extends State<CardCrowdData> {
  PersonInfo _personInfo;
  Map<String, TrafficInfo> _trafficInfos;
  String _selectItem = S.current.choose_area;
  int _sliding;

  @override
  void initState() {
    super.initState();
    _personInfo = widget.arguments['personInfo'];
  }

  /// Load dining hall data
  Future<void> _onSelectedItemChanged(String e) async {
    setState(() => {_selectItem = e, _trafficInfos = null});
    _trafficInfos = await DiningHallCrowdednessRepository.getInstance()
        .getCrowdednessInfo(
            _personInfo, Constant.campusArea.indexOf(_selectItem))
        .catchError((e) {
      if (e is UnsuitableTimeException) {
        if (PlatformX.isMaterial(context)) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).out_of_dining_time)));
        } else if (PlatformX.isIOS) {
          showPlatformDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) => PlatformAlertDialog(
                    content: Text(S.of(context).out_of_dining_time),
                    actions: <Widget>[
                      PlatformDialogAction(
                          child: PlatformText(S.of(context).i_see),
                          onPressed: () {
                            Navigator.pop(context); //Close Dialog
                            Navigator.pop(context); //Return to previous level
                          }),
                    ],
                  ));
        }
      }
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentBottomPadding: true,
      iosContentPadding: true,
      appBar:
          PlatformAppBar(title: Text(S.of(context).dining_hall_crowdedness)),
      body: Column(
        children: [
          PlatformWidget(
              material: (_, __) => DropdownButton<String>(
                    items: _getItems(),
                    hint: Text(_selectItem),
                    onChanged: (String e) => _onSelectedItemChanged(e),
                  ),
              cupertino: (_, __) => CupertinoSlidingSegmentedControl<int>(
                    onValueChanged: (int value) {
                      _sliding = value;
                      _onSelectedItemChanged(Constant.campusArea[value]);
                    },
                    groupValue: _sliding,
                    children: _getCupertinoItems(),
                  )),
          Expanded(
              child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: ListView(
                    children: _getListWidgets(),
                  )))
        ],
      ),
    );
  }

  List<DropdownMenuItem> _getItems() => Constant.campusArea
      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
      .toList(growable: false);

  Map<int, Text> _getCupertinoItems() =>
      Constant.campusArea.map((e) => Text(e)).toList(growable: false).asMap();

  List<Widget> _getListWidgets() {
    List<Widget> widgets = [];
    Map<String, Map<String, TrafficInfo>> zoneTraffic = {};
    if (_trafficInfos == null) return widgets;

    DiningHallCrowdednessRepository.getInstance()
        .toZoneList(_selectItem, _trafficInfos)
        .forEach((key, value) {
      widgets.add(_buildZoneCard(key, value));
    });
    return widgets;
  }

  Card _buildZoneCard(String zoneName, Map<String, TrafficInfo> infoList) {
    List<Widget> infoIndicators = [];
    infoList.forEach((key, value) {
      infoIndicators.add(Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(key),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text("${value.current} / ${value.max}"),
                ),
              ],
            ),
            LinearProgressIndicator(
              value: value.max == 0 ? 0 : value.current / value.max,
            )
          ],
        ),
      ));
    });
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          // Make the title align to left
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Colors.deepPurple,
                ),
                Text(
                  zoneName,
                  style: TextStyle(fontSize: 18, color: Colors.deepPurple),
                ),
              ],
            ),
            Column(
              children: infoIndicators,
            )
          ],
        ),
      ),
    );
  }
}
