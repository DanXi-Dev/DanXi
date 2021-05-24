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
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/exam_repository.dart';
import 'package:dan_xi/widget/future_widget.dart';
import 'package:dan_xi/widget/material_x.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:dan_xi/public_extension_methods.dart';

class ExamList extends StatefulWidget {
  final Map<String, dynamic> arguments;

  @override
  _ExamListState createState() => _ExamListState();

  ExamList({Key key, this.arguments});
}

class _ExamListState extends State<ExamList> {
  List<Exam> _data = [];
  PersonInfo _info;
  Future _content;

  @override
  void initState() {
    super.initState();
    _info = widget.arguments['personInfo'];
    _content = ExamRepository.getInstance().loadExamListRemotely(_info);
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentBottomPadding: true,
      iosContentPadding: true,
      appBar: PlatformAppBarX(
          title: Text(
        S.of(context).exam_schedule,
      )),
      body: FutureWidget(
        future: _content,
        successBuilder: (_, snapShot) {
          _data = snapShot.data;
          return Column(
            children: [
              Expanded(
                  child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: WithScrollbar(
                          controller: PrimaryScrollController.of(context),
                          child: ListView(
                            primary: true,
                            children: _getListWidgets(),
                          ))))
            ],
          );
        },
        loadingBuilder: Container(
            child: Center(
          child: PlatformCircularProgressIndicator(),
        )),
        errorBuilder: (_, snapShot) => GestureDetector(
          onTap: () {
            setState(() {
              _content =
                  ExamRepository.getInstance().loadExamListRemotely(_info);
            });
          },
          child: Center(
            child: Text(S.of(context).failed +
                '\n\nThe error was:\n' +
                snapShot.error.toString()),
          ),
        ),
      ),
    );
  }

  List<Widget> _getListWidgets() {
    List<Widget> widgets = [];
    List<Widget> secondaryWidgets = [
      _buildDividerWithText(S.of(context).other_types_exam,
          Theme.of(context).textTheme.bodyText1.color)
    ]; //These widgets are displayed after the ones above
    if (_data == null) return widgets;
    _data.forEach((Exam value) {
      if (value.testCategory.trim() == "论文" ||
          value.testCategory.trim() == "其他")
        secondaryWidgets.add(_buildCard(value, context));
      else
        widgets.add(_buildCard(value, context));
    });

    return widgets + secondaryWidgets;
  }
}

Widget _buildDividerWithText(String text, Color color) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: Row(children: <Widget>[
      Expanded(child: Divider(color: color)),
      Text(" $text ", style: TextStyle(color: color)),
      Expanded(child: Divider(color: color)),
    ]));

Widget _buildCard(Exam value, BuildContext context) => ThemedMaterial(
        child: Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${value.testCategory} ${value.type}",
              textScaleFactor: 0.8,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            /*Text(
                "${value.id}",
                textScaleFactor: 0.8,
                //style: TextStyle(color: Theme.of(context).hintColor),
              ),*/
            Text(
              "${value.name}",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (value.date.trim() != "" ||
                value.location.trim() != "" ||
                value.time.trim() != "")
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${value.date} ${value.time}",
                    textScaleFactor: 0.8,
                  ),
                  Text(
                    "${value.location} ",
                    textScaleFactor: 0.8,
                  ),
                ],
              ),
            if (value.note.trim() != "")
              Text(
                "${value.note}",
                textScaleFactor: 0.8,
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
          ],
        ),
      ),
    ));
