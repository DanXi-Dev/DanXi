import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/dining_hall_crowdedness_repository.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).dining_hall_crowdedness)),
      body: Column(
        children: [
          DropdownButton(
            items: _getItems(),
            hint: Text(_selectItem),
            onChanged: (e) async {
              setState(() => {_selectItem = e, _trafficInfos = null});
              _trafficInfos =
                  await DiningHallCrowdednessRepository.getInstance()
                      .getCrowdednessInfo(
                          _personInfo, Constant.campusArea.indexOf(_selectItem))
                      .catchError((e) {
                if (e is UnsuitableTimeException) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(S.of(context).out_of_dining_time)));
                }
              });
              setState(() {});
            },
          ),
          Expanded(
              child: ListView(
            children: _getListWidgets(),
          ))
        ],
      ),
    );
  }

  List<DropdownMenuItem> _getItems() {
    return Constant.campusArea
        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
        .toList(growable: false);
  }

  List<Widget> _getListWidgets() {
    List<Widget> widgets = [];
    if (_trafficInfos == null) return widgets;
    _trafficInfos.forEach((key, value) {
      widgets.add(ListTile(
        leading: Icon(Icons.timelapse),
        title: Text(value.current.toString()),
        subtitle: Text(key),
      ));
    });

    return widgets;
  }
}
