import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/card_repository.dart';
import 'package:dan_xi/repository/dining_hall_crowdedness_repository.dart';
import 'package:flutter/material.dart';

class CardCrowdData extends StatefulWidget {
  final Map<String, dynamic> arguments;

  @override
  _CardCrowdDataState createState() => _CardCrowdDataState();

  CardCrowdData({Key key, this.arguments});
}

class _CardCrowdDataState extends State<CardCrowdData> {
  CardInfo _cardInfo;
  PersonInfo _personInfo;
  Map<String, TrafficInfo> _trafficInfos;
  String _selectItem = "请选择食堂~";

  @override
  void initState() {
    super.initState();
    _cardInfo = widget.arguments['cardInfo'];
    _personInfo = widget.arguments['personInfo'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("食堂排队消费状况")),
      body: Column(
        children: [
          DropdownButton(
            items: _getItems(),
            hint: Text(_selectItem),
            onChanged: (e) async {
              setState(() => {_selectItem = e, _trafficInfos = null});
              _trafficInfos =
                  await DiningHallCrowdednessRepository.getInstance()
                      .getCrowdednessInfo(_personInfo, 0);
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
    return Constant.diningHallNameForECard
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
    // _trafficInfo.record.forEach((element) {
    //   widgets.add(ListTile(
    //     leading: Icon(Icons.monetization_on),
    //     title: Text(element.payment),
    //     isThreeLine: true,
    //     subtitle: Text("${element.location}\n${element.time.toString()}"),
    //   ));
    // });

    return widgets;
  }
}
