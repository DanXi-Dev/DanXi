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
        if (Platform.isAndroid) {
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
                    onValueChanged: (int value) =>
                        _onSelectedItemChanged(Constant.campusArea[value]),
                    children: _getCupertinoItems(),
                  )),
          Expanded(
              child: ListView(
            children: _getListWidgets(),
          ))
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
          child: ListTile(
        leading: Icon(Icons.timelapse),
        title: Text(value.current.toString()),
        subtitle: Text(key),
      )));
    });

    return widgets;
  }
}
