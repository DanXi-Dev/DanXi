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
import 'package:dan_xi/repository/card_repository.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/retryer.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/tag_selector/selector.dart';
import 'package:dan_xi/widget/tag_selector/tag.dart';
import 'package:dan_xi/widget/top_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:intl/intl.dart';

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
  bool _selectable = true;
  ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _cardInfo = widget.arguments['cardInfo'];
    _personInfo = widget.arguments['personInfo'];
    _tags = [
      Tag(S.current.last_7_days,
          PlatformX.isAndroid ? Icons.timelapse : SFSymbols.clock_fill),
      Tag(S.current.last_15_days,
          PlatformX.isAndroid ? Icons.timelapse : SFSymbols.clock_fill),
      Tag(S.current.last_30_days,
          PlatformX.isAndroid ? Icons.timelapse : SFSymbols.clock_fill),
    ];
    _tagDays = [7, 15, 30];
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentBottomPadding: true,
      iosContentPadding: true,
      appBar: PlatformAppBarX(
          title: TopController(
        controller: _controller,
        child: Text(S.of(context).ecard_balance_log),
      )),
      body: Column(children: [
        TagContainer(
            fillRandomColor: false,
            fixedColor: Colors.purple,
            fontSize: 16,
            enabled: _selectable,
            singleChoice: true,
            defaultChoice: -1,
            onChoice: (Tag tag, list) async {
              int index = _tags.indexOf(tag);
              if (index >= 0) {
                // Make the tags not clickable when data's being retrieved
                setState(() {
                  tag.checkedIcon =
                      PlatformX.isAndroid ? Icons.pending : SFSymbols.hourglass;
                  _selectable = false;
                });
                _cardInfo.records = await Retrier.runAsyncWithRetryForever(() =>
                    CardRepository.getInstance()
                        .loadCardRecord(_tagDays[index]));
                setState(() {
                  tag.checkedIcon =
                      PlatformX.isAndroid ? Icons.check : SFSymbols.checkmark;
                  _selectable = true;
                });
              }
            },
            tagList: _tags),
        Expanded(
            child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: PlatformWidget(
                    material: (_, __) => Scrollbar(
                        interactive: PlatformX.isDesktop,
                        child: ListView(
                          controller: _controller,
                          children: _getListWidgets(),
                        )),
                    cupertino: (_, __) => CupertinoScrollbar(
                            child: ListView(
                          controller: _controller,
                          children: _getListWidgets(),
                        ))))),
      ]),
    );
  }

  List<Widget> _getListWidgets() {
    List<Widget> widgets = [];
    if (_cardInfo.records != null)
      _cardInfo.records.forEach((element) {
        widgets.add(Material(
            child: ListTile(
          // leading: PlatformX.isAndroid
          //     ? Icon(Icons.monetization_on)
          //     : Icon(SFSymbols.money_dollar_circle_fill),
          title: Text(element.location),
          trailing: Text(Constant.yuanSymbol(element.payment)),
          subtitle:
              Text(DateFormat("yyyy-MM-dd HH:mm:ss").format(element.time)),
        )));
      });

    return widgets;
  }
}
