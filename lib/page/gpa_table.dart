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
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/repository/edu_service_repository.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class GpaTablePage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  @override
  _GpaTablePageState createState() => _GpaTablePageState();

  GpaTablePage({Key key, this.arguments});
}

class _GpaTablePageState extends State<GpaTablePage> {
  List<GPAListItem> gpalist;

  @override
  void initState() {
    super.initState();
    gpalist = widget.arguments['gpalist'];
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
        iosContentBottomPadding: false,
        iosContentPadding: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: PlatformAppBarX(
          title: Text(S.of(context).your_gpa),
        ),
        body: MediaQuery.removePadding(
            removeTop: true,
            context: context,
            child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                controller: PrimaryScrollController.of(context),
                child: Table(
                  children: _getGpaRow(),
                ))));
  }

  List<TableRow> _getGpaRow() {
    List<TableRow> widgets = [
      TableRow(children: [
        Text(S.of(context).name),
        Text(S.of(context).gpa),
        Text(S.of(context).credits),
        Text(S.of(context).rank)
      ])
    ];
    gpalist.forEach((element) {
      widgets.add(TableRow(children: [
        Text(element.name),
        Text(element.gpa),
        Text(element.credits),
        Text(element.rank)
      ]));
    });
    return widgets;
  }
}
