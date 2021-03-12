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

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/card_repository.dart';
import 'package:dan_xi/widget/tag_selector/selector.dart';
import 'package:dan_xi/widget/tag_selector/tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class CardDetailPage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  @override
  _CardDetailPageState createState() => _CardDetailPageState();

  CardDetailPage({Key key, this.arguments});
}

class _CardDetailPageState extends State<CardDetailPage> {
  CardInfo _cardInfo;
  PersonInfo _personInfo; // ignore: unused_field
  List<Tag> _tags;
  List<int> _tagDays;

  @override
  void initState() {
    super.initState();
    _cardInfo = widget.arguments['cardInfo'];
    _personInfo = widget.arguments['personInfo'];
    _tags = [
      Tag(S.current.last_7_days, Icons.timelapse),
      Tag(S.current.last_15_days, Icons.timelapse),
      Tag(S.current.last_30_days, Icons.timelapse),
    ];
    _tagDays = [7, 15, 30];
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentBottomPadding: true,
      iosContentPadding: true,
      appBar: PlatformAppBar(title: Text(S.of(context).ecard_balance_log)),
      body: Column(children: [
        TagContainer(
            fillRandomColor: false,
            fixedColor: Colors.purple,
            fontSize: 16,
            singleChoice: true,
            onChoice: (Tag tag, list) async {
              int index = _tags.indexOf(tag);
              if (index >= 0) {
                setState(() => tag.checkedIcon = Icons.pending);
                await _cardInfo.loadRecords(_tagDays[index]);
                setState(() => tag.checkedIcon = Icons.check);
              }
            },
            tagList: _tags),
        Expanded(
            child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: ListView(
                  children: _getListWidgets(),
                ))),
      ]),
    );
  }

  List<Widget> _getListWidgets() {
    List<Widget> widgets = [];
    _cardInfo.records.forEach((element) {
      widgets.add(Material(
          color: isCupertino(context) ? Colors.white : null,
          child: ListTile(
            leading: Icon(Icons.monetization_on),
            title: Text(element.payment),
            isThreeLine: true,
            subtitle: Text("${element.location}\n${element.time.toString()}"),
          )));
    });

    return widgets;
  }
}
