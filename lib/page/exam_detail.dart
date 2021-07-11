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

import 'dart:io';

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/master_detail/master_detail_view.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/data_center_repository.dart';
import 'package:dan_xi/repository/edu_service_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/viewport_utils.dart';
import 'package:dan_xi/widget/future_widget.dart';
import 'package:dan_xi/widget/material_x.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:ical/serializer.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

class ExamList extends StatefulWidget {
  final Map<String, dynamic> arguments;

  @override
  _ExamListState createState() => _ExamListState();

  ExamList({Key key, this.arguments});
}

class _ExamListState extends State<ExamList> {
  List<Exam> _data = [];
  PersonInfo _info;
  Future _examList;
  Future _gpaList;
  List<GPAListItem> _gpa;

  Future<List<SemesterInfo>> _semester;
  List<SemesterInfo> _unpackedSemester;
  int _showingSemester;

  @override
  void initState() {
    super.initState();
    _info = widget.arguments['personInfo'];
    _examList = EduServiceRepository.getInstance().loadExamListRemotely(_info);
    _gpaList = EduServiceRepository.getInstance().loadGPARemotely(_info);
    _semester = EduServiceRepository.getInstance().loadSemesters(_info);
  }

  void _exportICal() async {
    ICalendar cal = ICalendar(company: 'DanXi', lang: "CN");
    _data?.forEach((element) {
      if (element.date.trim().isNotEmpty && element.time.trim().isNotEmpty)
        try {
          cal.addElement(IEvent(
            summary: element.name,
            location: element.location,
            status: IEventStatus.CONFIRMED,
            description:
                "${element.testCategory} ${element.type}\n${element.note}",
            start:
                DateTime.parse(element.date + ' ' + element.time.split('~')[0]),
            end:
                DateTime.parse(element.date + ' ' + element.time.split('~')[1]),
          ));
        } catch (ignored) {
          Noticing.showNotice(
              context, S.of(context).error_adding_exam(element.name),
              title: S.of(context).fatal_error);
        }
    });
    Directory documentDir = await getApplicationDocumentsDirectory();
    File outputFile =
        File("${documentDir.absolute.path}/output_timetable/${"exam.ics"}");
    outputFile.createSync(recursive: true);
    await outputFile.writeAsString(cal.serialize(), flush: true);
    if (PlatformX.isIOS)
      OpenFile.open(outputFile.absolute.path, type: "text/calendar");
    else if (PlatformX.isAndroid)
      Share.shareFiles([outputFile.absolute.path],
          mimeTypes: ["text/calendar"]);
    else {
      Noticing.showNotice(context, outputFile.absolute.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
        iosContentBottomPadding: true,
        iosContentPadding: true,
        appBar: PlatformAppBarX(
          title: Text(
            S.of(context).exam_schedule,
          ),
          trailingActions: [
            PlatformIconButton(
              padding: EdgeInsets.zero,
              icon: Icon(PlatformX.isMaterial(context)
                  ? Icons.share
                  : SFSymbols.square_arrow_up),
              onPressed: _exportICal,
            ),
          ],
        ),
        body: Material(
            child: FutureWidget<List<SemesterInfo>>(
                future: _semester,
                successBuilder: (BuildContext context,
                    AsyncSnapshot<List<SemesterInfo>> snapshot) {
                  _unpackedSemester = snapshot.data;
                  if (_showingSemester == null)
                    _showingSemester = _unpackedSemester.length - 5;

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          PlatformIconButton(
                            icon: Icon(Icons.chevron_left),
                            onPressed: _showingSemester > 0
                                ? () => setState(() => --_showingSemester)
                                : null,
                          ),
                          Text(S.of(context).semester(
                              _unpackedSemester[_showingSemester].schoolYear,
                              _unpackedSemester[_showingSemester].name)),
                          PlatformIconButton(
                            icon: Icon(Icons.chevron_right),
                            onPressed:
                                _showingSemester < _unpackedSemester.length - 1
                                    ? () => setState(() => ++_showingSemester)
                                    : null,
                          )
                        ],
                      ),
                      Expanded(
                        child: _loadExamGradeHybridView(),
                      )
                    ],
                  );
                },
                loadingBuilder:
                    Center(child: PlatformCircularProgressIndicator()),
                errorBuilder: _loadGradeViewFromDataCenter)));
  }

  Widget _loadExamGradeHybridView() => FutureWidget<List<Exam>>(
        future: _examList,
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
                            children: _getListWidgetsHybrid(),
                          ))))
            ],
          );
        },
        loadingBuilder: Container(
            child: Center(
          child: PlatformCircularProgressIndicator(),
        )),
        errorBuilder: _loadGradeView,
      );

  Widget _loadGradeView() => GestureDetector(
      child: FutureWidget<List<ExamScore>>(
          future: EduServiceRepository.getInstance().loadExamScoreRemotely(
              _info,
              semesterId: _unpackedSemester[_showingSemester].semesterId),
          successBuilder: (_, snapShot) => _buildGradeLayout(snapShot),
          loadingBuilder: Container(
              child: Center(
            child: PlatformCircularProgressIndicator(),
          )),
          errorBuilder: _loadGradeViewFromDataCenter));

  Widget _buildGradeLayout(AsyncSnapshot<List<ExamScore>> snapshot,
          {bool isFallback = false}) =>
      Column(
        children: [
          Expanded(
              child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: WithScrollbar(
                      controller: PrimaryScrollController.of(context),
                      child: ListView(
                        primary: true,
                        children: _getListWidgetsGrade(snapshot.data,
                            isFallback: isFallback),
                      ))))
        ],
      );

  Widget _loadGradeViewFromDataCenter() => GestureDetector(
      child: FutureWidget<List<ExamScore>>(
          future: DataCenterRepository.getInstance().loadAllExamScore(_info),
          successBuilder: (_, snapShot) =>
              _buildGradeLayout(snapShot, isFallback: true),
          loadingBuilder: Container(
              child: Center(
            child: PlatformCircularProgressIndicator(),
          )),
          errorBuilder: _buildErrorPage));

  Widget _buildErrorPage(BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.error is RangeError)
      return Padding(
        child: Center(
          child: Text(
            S.of(context).no_data,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 32),
      );

    return GestureDetector(
        onTap: () {
          setState(() {
            _semester = EduServiceRepository.getInstance().loadSemesters(_info);
            _examList =
                EduServiceRepository.getInstance().loadExamListRemotely(_info);
          });
        },
        child: Padding(
          child: Center(
            child: Text(S.of(context).failed +
                '\n${S.of(context).need_campus_network}\n\nThe error was:\n' +
                snapshot.error.toString()),
          ),
          padding: EdgeInsets.symmetric(horizontal: 32),
        ));
  }

  List<Widget> _getListWidgetsGrade(List<ExamScore> scores,
      {bool isFallback = false}) {
    List<Widget> widgets = [];
    if (isFallback) {
      widgets.add(_buildLimitedCard());
    } else {
      widgets.add(_buildGPACard());
    }
    scores.forEach((value) {
      widgets.add(_buildCardGrade(value, context));
    });
    return widgets;
  }

  Widget _buildLimitedCard() => Card(
      color: Theme.of(context).errorColor,
      child: ListTile(
        visualDensity: VisualDensity.comfortable,
        title: Text(
          S.of(context).limited_mode_title,
          style: TextStyle(color: Colors.white),
        ),
        subtitle: Text(S.of(context).limited_mode_description,
            style: TextStyle(color: Colors.white)),
      ));

  Widget _buildGPACard() => Card(
        color: Theme.of(context).accentColor,
        child: ListTile(
          visualDensity: VisualDensity.comfortable,
          title: Text(
            S.of(context).your_gpa,
            style: TextStyle(color: Colors.white),
          ),
          trailing: FutureWidget<List<GPAListItem>>(
            future: _gpaList,
            successBuilder: (BuildContext context,
                AsyncSnapshot<List<GPAListItem>> snapShot) {
              _gpa = snapShot.data;
              return Text(
                snapShot.data
                    .firstWhere((element) => element.id == _info.id)
                    .gpa,
                textScaleFactor: 1.25,
                style: TextStyle(color: Colors.white),
              );
            },
            errorBuilder: (BuildContext context,
                AsyncSnapshot<List<GPAListItem>> snapShot) {
              return Container();
            },
            loadingBuilder: (_, __) => PlatformCircularProgressIndicator(),
          ),
          subtitle: FutureWidget<List<GPAListItem>>(
            future: _gpaList,
            successBuilder: (BuildContext context,
                AsyncSnapshot<List<GPAListItem>> snapShot) {
              GPAListItem myGPA =
                  snapShot.data.firstWhere((element) => element.id == _info.id);
              return Text(
                  S.of(context).your_gpa_subtitle(myGPA.rank, myGPA.credits),
                  style: TextStyle(color: ThemeData.dark().hintColor));
            },
            errorBuilder: (BuildContext context,
                AsyncSnapshot<List<GPAListItem>> snapShot) {
              return Text(S.of(context).failed);
            },
            loadingBuilder: (_, __) => Text(S.of(context).loading),
          ),
          onTap: () => smartNavigatorPush(context, "/exam/gpa", arguments: {
            "gpalist": _gpa,
          }),
        ),
      );

  List<Widget> _getListWidgetsHybrid() {
    List<Widget> widgets = [_buildGPACard()];
    List<Widget> secondaryWidgets = [
      _buildDividerWithText(S.of(context).other_types_exam,
          Theme.of(context).textTheme.bodyText1.color)
    ]; //These widgets are displayed after the ones above
    if (_data == null) return widgets;
    _data.forEach((Exam value) {
      if (value.testCategory.trim() == "论文" ||
          value.testCategory.trim() == "其他")
        secondaryWidgets.add(_buildCardHybrid(value, context));
      else
        widgets.add(_buildCardHybrid(value, context));
    });

    return widgets + secondaryWidgets;
  }

  Widget _buildDividerWithText(String text, Color color) => Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(children: <Widget>[
        Expanded(child: Divider(color: color)),
        Text(" $text ", style: TextStyle(color: color)),
        Expanded(child: Divider(color: color)),
      ]));

  Widget _buildCardHybrid(Exam value, BuildContext context) => ThemedMaterial(
          child: Card(
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${value.testCategory} ${value.type}",
                      textScaleFactor: 0.8,
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
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
                          const SizedBox(
                            width: 8,
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: FutureWidget<List<ExamScore>>(
                    future: EduServiceRepository.getInstance()
                        .loadExamScoreRemotely(_info,
                            semesterId:
                                _unpackedSemester[_showingSemester].semesterId),
                    loadingBuilder: PlatformCircularProgressIndicator(),
                    errorBuilder: Container(),
                    successBuilder: (context, snapshot) {
                      if (snapshot.hasData) {
                        try {
                          return Container(
                              height: 28,
                              width: 28,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                                //borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  snapshot.data
                                      .firstWhere((element) =>
                                          element.name == value.name)
                                      .level,
                                  textScaleFactor: 1.2,
                                  //style: TextStyle(color: Colors.red),
                                ),
                              ));
                        } catch (ignored) {}
                      }
                      return Container();
                    },
                  ),
                )
              ],
            )),
      ));

  Widget _buildCardGrade(ExamScore value, BuildContext context) =>
      ThemedMaterial(
          child: Card(
        child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: ViewportUtils.getMainNavigatorWidth(context) - 80,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${value.type}",
                        textScaleFactor: 0.8,
                        style: TextStyle(color: Theme.of(context).hintColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                      Text(
                        "${value.name}",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 28,
                  alignment: Alignment.centerLeft,
                  child: Center(
                    child: Text(
                      value.level,
                      textScaleFactor: 1.2,
                    ),
                  ),
                ),
              ],
            )),
      ));
}
