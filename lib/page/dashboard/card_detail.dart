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
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/fdu/ecard_repository.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/top_controller.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:dan_xi/widget/forum/tag_selector/selector.dart';
import 'package:dan_xi/widget/forum/tag_selector/tag.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';

/// A list page showing user's campus card spending history.
///
/// Arguments:
/// [CardInfo] cardInfo: user's card info.
class CardDetailPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  @override
  CardDetailPageState createState() => CardDetailPageState();

  const CardDetailPage({super.key, this.arguments});
}

class CardDetailPageState extends State<CardDetailPage> {
  CardInfo? _cardInfo;
  List<Tag>? _tags;
  late List<int> _tagDays;
  bool _selectable = true;

  @override
  void initState() {
    super.initState();
    _cardInfo = widget.arguments!['cardInfo'];
    _tagDays = [7, 15, 30];
  }

  @override
  Widget build(BuildContext context) {
    _tags ??= [
      Tag(
          S.current.last_7_days,
          PlatformX.isMaterial(context)
              ? Icons.timelapse
              : CupertinoIcons.clock_fill),
      Tag(
          S.current.last_15_days,
          PlatformX.isMaterial(context)
              ? Icons.timelapse
              : CupertinoIcons.clock_fill),
      Tag(
          S.current.last_30_days,
          PlatformX.isMaterial(context)
              ? Icons.timelapse
              : CupertinoIcons.clock_fill),
    ];
    return PlatformScaffold(
      iosContentBottomPadding: true,
      iosContentPadding: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
          title: TopController(
        controller: PrimaryScrollController.of(context),
        child: Text(S.of(context).ecard_balance_log),
      )),
      body: Column(children: [
        TagContainer(
            fillRandomColor: false,
            fixedColor: Theme.of(context).colorScheme.secondary,
            fontSize: 16,
            enabled: _selectable,
            singleChoice: true,
            defaultChoice: -1,
            onChoice: (Tag tag, list) async {
              int index = _tags!.indexOf(tag);
              if (index >= 0) {
                // Make the tags not clickable when data's being retrieved
                setState(() {
                  tag.checkedIcon = PlatformX.isMaterial(context)
                      ? Icons.pending
                      : CupertinoIcons.hourglass;
                  _selectable = false;
                });
                _cardInfo!.records = await CardRepository.getInstance()
                    .loadCardRecord(
                        StateProvider.personInfo.value, _tagDays[index]);
                setState(() {
                  tag.checkedIcon = PlatformX.isMaterial(context)
                      ? Icons.check
                      : CupertinoIcons.checkmark;
                  _selectable = true;
                });
              }
            },
            tagList: _tags),
        Expanded(
            child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: WithScrollbar(
                  controller: PrimaryScrollController.of(context),
                  child: ListView(
                    controller: PrimaryScrollController.of(context),
                    children: _getListWidgets(),
                  ),
                ))),
      ]),
    );
  }

  List<Widget> _getListWidgets() {
    List<Widget> widgets = [];
    if (_cardInfo!.records != null) {
      for (var element in _cardInfo!.records!) {
        widgets.add(ListTile(
          // leading: PlatformX.isMaterial(context)
          //     ? Icon(Icons.monetization_on)
          //     : Icon(CupertinoIcons.money_dollar_circle_fill),
          title: Text(element.location),
          trailing: Text(Constant.yuanSymbol(element.payment)),
          subtitle:
              Text(DateFormat("yyyy-MM-dd HH:mm:ss").format(element.time)),
        ));
      }
    }

    return widgets;
  }
}
