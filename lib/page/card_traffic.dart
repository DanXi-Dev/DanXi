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

import 'dart:io';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/dining_hall_crowdedness_repository.dart';
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

  Future<void> _onSelectedItemChanged(String e) async {
    setState(() => {_selectItem = e, _trafficInfos = null});
    _trafficInfos = await DiningHallCrowdednessRepository.getInstance()
        .getCrowdednessInfo(
            _personInfo, Constant.campusArea.indexOf(_selectItem))
        .catchError((e) {
      if (e is UnsuitableTimeException) {
        if (Platform.isAndroid && isMaterial(context)) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).out_of_dining_time)));
        } else if (Platform.isIOS) {
          //TODO
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
    if (_trafficInfos == null) return widgets;
    _trafficInfos.forEach((key, value) {
      widgets.add(Material(
          color: isCupertino(context) ? Colors.white : null,
          child: ListTile(
            leading: Icon(Icons.timelapse),
            title: Text(value.current.toString()),
            subtitle: Text(key),
          )));
    });

    return widgets;
  }
}
