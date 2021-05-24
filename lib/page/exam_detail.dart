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
        errorBuilder: GestureDetector(
          onTap: () {
            refreshSelf();
          },
          child: Center(
            child: Text(S.of(context).failed),
          ),
        ),
      ),
    );
  }

  List<Widget> _getListWidgets() {
    List<Widget> widgets = [];
    if (_data == null) return widgets;
    _data.forEach((Exam value) {
      widgets.add(ThemedMaterial(
          child: ListTile(
        leading: Icon(SFSymbols.doc_append),
        title: Text(
          "${value.name}(${value.id}) ${value.type}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
            "${value.testCategory} ${value.location} ${value.date} ${value.time}\n${value.note}"),
      )));
    });

    return widgets;
  }
}
