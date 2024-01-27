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
import 'package:dan_xi/repository/fdu/edu_service_repository.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A list page showing user's GPA scores and his/her ranking.
class GpaTablePage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  @override
  GpaTablePageState createState() => GpaTablePageState();

  const GpaTablePage({super.key, this.arguments});
}

class GpaTablePageState extends State<GpaTablePage> {
  List<GPAListItem>? gpaList;
  static const String NAME_HIDDEN = "****";

  @override
  void initState() {
    super.initState();
    gpaList = widget.arguments!['gpalist'];
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
        iosContentBottomPadding: false,
        iosContentPadding: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: PlatformAppBarX(
          title: Text(S.of(context).your_gpa),
        ),
        body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                controller: PrimaryScrollController.of(context),
                child: Table(children: _buildGpaRow()))));
  }

  List<TableRow> _buildGpaRow() {
    List<TableRow> widgets = [
      TableRow(
          children: [
        S.of(context).major,
        S.of(context).gpa,
        S.of(context).credits,
        S.of(context).rank
      ]
              .map((headText) => Text(headText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold)))
              .toList())
    ];

    for (var element in gpaList!) {
      TextStyle? textColorStyle = element.name == NAME_HIDDEN
          ? null
          : TextStyle(color: Theme.of(context).colorScheme.secondary);
      widgets.add(TableRow(
          children: [element.major, element.gpa, element.credits, element.rank]
              .map((itemText) => Text(itemText,
                  textAlign: TextAlign.center, style: textColorStyle))
              .toList()));
    }
    return widgets;
  }
}
