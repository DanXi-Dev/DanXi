import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/card_repository.dart';
import 'package:flutter/material.dart';

class CardDetailPage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  @override
  _CardDetailPageState createState() => _CardDetailPageState();

  CardDetailPage({Key key, this.arguments});
}

class _CardDetailPageState extends State<CardDetailPage> {
  CardInfo _cardInfo;
  PersonInfo _personInfo;

  @override
  void initState() {
    super.initState();
    _cardInfo = widget.arguments['cardInfo'];
    _personInfo = widget.arguments['personInfo'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).ecard_balance_log)),
      body: ListView(
        children: _getListWidgets(),
      ),
    );
  }

  List<Widget> _getListWidgets() {
    List<Widget> widgets = [];
    _cardInfo.records.forEach((element) {
      widgets.add(ListTile(
        leading: Icon(Icons.monetization_on),
        title: Text(element.payment),
        isThreeLine: true,
        subtitle: Text("${element.location}\n${element.time.toString()}"),
      ));
    });

    return widgets;
  }
}
