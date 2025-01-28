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
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/fdu/data_center_repository.dart';
import 'package:dan_xi/repository/fdu/edu_service_repository.dart';
import 'package:dan_xi/util/lazy_future.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/viewport_utils.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:ical/serializer.dart';
import 'package:nil/nil.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// A list page showing user's GPA scores and exam information.
/// It will try to fetch [SemesterInfo] first.
/// If successful, it will fetch exams in this term. In case that there is no exam, it shows the score of this term.
/// If failed, it will try to fetch the list of score in all terms from DataCenter.
class ExamList extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  @override
  ExamListState createState() => ExamListState();

  const ExamList({super.key, this.arguments});
}

class ExamListState extends State<ExamList> {
  List<Exam> _examData = [];
  PersonInfo? _info;
  Future<List<GPAListItem>?>? _gpaListFuture;
  List<GPAListItem>? _gpa;

  Future<List<SemesterInfo>?>? _semesterFuture;
  List<SemesterInfo>? _unpackedSemester;
  List<ExamScore>? _cachedScoreData;
  int? _showingSemester;

  set semester(int? newSemester) {
    _cachedScoreData = null;
    _showingSemester = newSemester;
  }

  int? get semester => _showingSemester;

  @override
  void initState() {
    super.initState();
    _info = StateProvider.personInfo.value;
    _gpaListFuture = LazyFuture.pack(
        EduServiceRepository.getInstance().loadGPARemotely(_info));
    _semesterFuture = LazyFuture.pack(
        EduServiceRepository.getInstance().loadSemesters(_info));
  }

  void _exportICal() async {
    if (_examData.isEmpty) {
      Noticing.showNotice(context, S.of(context).exam_unavailable,
          title: S.of(context).fatal_error);
      return;
    }
    ICalendar cal = ICalendar(company: 'DanXi', lang: "CN");
    for (var element in _examData) {
      if (element.date.trim().isNotEmpty && element.time.trim().isNotEmpty) {
        try {
          cal.addElement(IEvent(
            summary: element.name,
            location: element.location,
            status: IEventStatus.CONFIRMED,
            description:
                "${element.testCategory} ${element.type}\n${element.note}",
            start:
                DateTime.parse('${element.date} ${element.time.split('~')[0]}'),
            end:
                DateTime.parse('${element.date} ${element.time.split('~')[1]}'),
          ));
        } catch (ignored) {
          Noticing.showNotice(
              context, S.of(context).error_adding_exam(element.name),
              title: S.of(context).fatal_error);
        }
      }
    }
    Directory documentDir = await getApplicationDocumentsDirectory();
    File outputFile = PlatformX.createPlatformFile(
        "${documentDir.absolute.path}/output_timetable/exam.ics");
    outputFile.createSync(recursive: true);
    await outputFile.writeAsString(cal.serialize(), flush: true);
    if (PlatformX.isIOS) {
      OpenFile.open(outputFile.absolute.path, type: "text/calendar");
    } else if (PlatformX.isAndroid) {
      Share.shareXFiles(
          [XFile(outputFile.absolute.path, mimeType: "text/calendar")]);
    } else if (mounted) {
      Noticing.showNotice(context, outputFile.absolute.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
        iosContentBottomPadding: false,
        iosContentPadding: false,
        appBar: PlatformAppBarX(
          title: Text(S.of(context).exam_schedule),
          trailingActions: [
            PlatformIconButton(
              padding: EdgeInsets.zero,
              icon: Icon(PlatformX.isMaterial(context)
                  ? Icons.share
                  : CupertinoIcons.square_arrow_up),
              onPressed: _exportICal,
            ),
          ],
        ),
        body: SafeArea(
            child: FutureWidget<List<SemesterInfo>?>(
                future: _semesterFuture,
                successBuilder: (BuildContext context,
                    AsyncSnapshot<List<SemesterInfo>?> snapshot) {
                  _unpackedSemester = snapshot.data;
                  semester ??= _unpackedSemester!.length - 5;
                  return _loadExamGradeHybridView();
                },
                loadingBuilder:
                    Center(child: PlatformCircularProgressIndicator()),
                // @w568w (2022-1-27): replacing following lines with `errorBuilder: _loadGradeViewFromDataCenter`
                // leads to a 100% execution of _loadGradeViewFromDataCenter.
                // I don't know why.
                errorBuilder: (BuildContext context,
                    AsyncSnapshot<List<SemesterInfo>?> snapshot) {
                  return _loadGradeViewFromDataCenter();
                })));
  }

  Future<void> loadExamAndScore() async {
    _examData.clear();
    _cachedScoreData = null;
    _examData = (await EduServiceRepository.getInstance().loadExamListRemotely(
        _info,
        semesterId: _unpackedSemester![semester!].semesterId))!;
    _cachedScoreData = await EduServiceRepository.getInstance()
        .loadExamScoreRemotely(_info,
            semesterId: _unpackedSemester![semester!].semesterId);
  }

  Widget _loadExamGradeHybridView() {
    Widget body = FutureWidget<void>(
        nullable: true,
        future: LazyFuture.pack(loadExamAndScore()),
        successBuilder: (_, snapShot) => _examData.isEmpty
            ? _loadGradeView(needReloadScoreData: false)
            : ListView(children: _getListWidgetsHybrid()),
        loadingBuilder: Center(
          child: PlatformCircularProgressIndicator(),
        ),
        errorBuilder: () => _loadGradeView());
    final List<Widget> mainWidgets = [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PlatformIconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: semester! > 0
                ? () => setState(() => semester = semester! - 1)
                : null,
          ),
          Text(S.of(context).semester(
              _unpackedSemester![semester!].schoolYear ?? "?",
              _unpackedSemester![semester!].name ?? "?")),
          PlatformIconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: semester! < _unpackedSemester!.length - 1
                ? () => setState(() => semester = semester! + 1)
                : null,
          )
        ],
      ),
      Expanded(child: body)
    ];
    return Column(children: mainWidgets);
  }

  Widget _loadGradeView({bool needReloadScoreData = true}) =>
      FutureWidget<List<ExamScore>?>(
          future: needReloadScoreData
              ? EduServiceRepository.getInstance().loadExamScoreRemotely(_info,
                  semesterId: _unpackedSemester![semester!].semesterId)
              : Future.value(_cachedScoreData),
          successBuilder: (_, snapShot) => _buildGradeLayout(snapShot),
          loadingBuilder: Center(child: PlatformCircularProgressIndicator()),
          errorBuilder:
              (BuildContext context, AsyncSnapshot<List<ExamScore>?> snapshot) {
            if (snapshot.error is RangeError) {
              return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Center(
                    child: Text(S.of(context).no_data),
                  ));
            }
            return _loadGradeViewFromDataCenter();
          });

  Widget _buildGradeLayout(AsyncSnapshot<List<ExamScore>?> snapshot,
          {bool isFallback = false}) =>
      WithScrollbar(
          controller: PrimaryScrollController.of(context),
          child: ListView(
              primary: true,
              children: _getListWidgetsGrade(snapshot.data!,
                  isFallback: isFallback)));

  Widget _loadGradeViewFromDataCenter() {
    return GestureDetector(
        child: FutureWidget<List<ExamScore>?>(
            future: DataCenterRepository.getInstance().loadAllExamScore(_info),
            successBuilder: (_, snapShot) =>
                _buildGradeLayout(snapShot, isFallback: true),
            loadingBuilder: Center(
              child: PlatformCircularProgressIndicator(),
            ),
            errorBuilder: _buildErrorPage));
  }

  Widget _buildErrorPage(
          BuildContext context, AsyncSnapshot<List<ExamScore>?> snapshot) =>
      ErrorPageWidget(
        errorMessage:
            '${S.of(context).failed}\n${S.of(context).need_campus_network}\n\nError:\n${ErrorPageWidget.generateUserFriendlyDescription(S.of(context), snapshot.error)}',
        error: snapshot.error,
        trace: snapshot.stackTrace,
        onTap: () => setState(() {
          _semesterFuture = LazyFuture.pack(
              EduServiceRepository.getInstance().loadSemesters(_info));
        }),
        buttonText: S.of(context).retry,
      );

  List<Widget> _getListWidgetsGrade(List<ExamScore> scores,
      {bool isFallback = false}) {
    List<Widget> widgets = [];
    if (isFallback) {
      widgets.add(_buildLimitedCard());
    } else {
      widgets.add(_buildGPACard());
    }
    for (var value in scores) {
      widgets.add(_buildCardGrade(value, context));
    }
    return widgets;
  }

  Widget _buildLimitedCard() => Card(
      color: Theme.of(context).colorScheme.error,
      child: ListTile(
        visualDensity: VisualDensity.comfortable,
        title: Text(
          S.of(context).limited_mode_title,
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(S.of(context).limited_mode_description,
            style: const TextStyle(color: Colors.white)),
      ));

  Widget _buildGPACard() => Card(
        color: PlatformX.backgroundAccentColor(context),
        child: ListTile(
          visualDensity: VisualDensity.comfortable,
          title: Text(
            S.of(context).your_gpa,
            style: const TextStyle(color: Colors.white),
          ),
          trailing: FutureWidget<List<GPAListItem>?>(
            future: _gpaListFuture,
            successBuilder: (BuildContext context,
                AsyncSnapshot<List<GPAListItem>?> snapShot) {
              _gpa = snapShot.data;
              return Text(
                snapShot.data!
                    .firstWhere((element) => element.id == _info!.id)
                    .gpa,
                textScaler: TextScaler.linear(1.25),
                style: const TextStyle(color: Colors.white),
              );
            },
            errorBuilder: (BuildContext context,
                AsyncSnapshot<List<GPAListItem>?> snapShot) {
              return nil;
            },
            loadingBuilder: (_, __) => PlatformCircularProgressIndicator(),
          ),
          subtitle: FutureWidget<List<GPAListItem>?>(
            future: _gpaListFuture,
            successBuilder: (BuildContext context,
                AsyncSnapshot<List<GPAListItem>?> snapShot) {
              GPAListItem myGPA = snapShot.data!
                  .firstWhere((element) => element.id == _info!.id);
              return Text(
                  S.of(context).your_gpa_subtitle(myGPA.rank, myGPA.credits),
                  style: TextStyle(color: ThemeData.dark().hintColor));
            },
            errorBuilder: (BuildContext context,
                AsyncSnapshot<List<GPAListItem>?> snapShot) {
              return Text(S.of(context).failed);
            },
            loadingBuilder: (_, __) => Text(S.of(context).loading),
          ),
          onTap: () {
            if (_gpa != null && _gpa!.isNotEmpty) {
              smartNavigatorPush(context, "/exam/gpa",
                  arguments: {"gpalist": _gpa});
            }
          },
        ),
      );

  List<Widget> _getListWidgetsHybrid() {
    List<Widget> widgets = [_buildGPACard()];
    List<Widget> secondaryWidgets = [
      _buildDividerWithText(S.of(context).other_types_exam,
          Theme.of(context).textTheme.bodyLarge!.color)
    ]; //These widgets are displayed after the ones above
    if (_examData.isEmpty) return widgets;
    for (var value in _examData) {
      if (value.testCategory.trim() == "论文" ||
          value.testCategory.trim() == "其他" ||
          value.type != "期末考试") {
        secondaryWidgets.add(_buildCardHybrid(value, context));
      } else {
        widgets.add(_buildCardHybrid(value, context));
      }
    }

    // Some courses do not require an exam but also have given their scores.
    // Append these courses to the bottom of the list.
    _cachedScoreData?.forEach((element) {
      if (_examData.every((exam) => exam.id != element.id)) {
        secondaryWidgets.add(_buildCardGrade(element, context));
      }
    });
    return widgets + secondaryWidgets;
  }

  Widget _buildDividerWithText(String text, Color? color) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(children: <Widget>[
        Expanded(child: Divider(color: color)),
        Text(" $text ", style: TextStyle(color: color)),
        Expanded(child: Divider(color: color)),
      ]));

  Widget _buildGradeContainer(String level, String? score) => Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
      ),
      child: Column(children: [
        Center(
          child: Text(
            level,
          ),
        ),
        Center(
          child: Text(score!, textScaler: TextScaler.linear(0.6)),
        ),
      ]));

  // Grade card with exam data
  Widget _buildCardHybrid(Exam value, BuildContext context) => Card(
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${value.testCategory} ${value.type}",
                      textScaler: TextScaler.linear(0.8),
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                    Text(
                      value.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (value.date.trim() != "" ||
                        value.location.trim() != "" ||
                        value.time.trim() != "")
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if (value.date != "" || value.time != "") ...[
                            Text("${value.date} ${value.time}",
                                textScaler: TextScaler.linear(0.8)),
                            const SizedBox(
                              width: 8,
                            ),
                          ] else
                            ...[],
                          Text("${value.location} ",
                              textScaler: TextScaler.linear(0.8)),
                        ],
                      ),
                    if (value.note.trim() != "")
                      Text(
                        value.note,
                        textScaler: TextScaler.linear(0.8),
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                  ],
                )),
                if (!value.type.contains("补") && !value.type.contains("缓")) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FutureWidget<List<ExamScore>?>(
                      // Using our cached data here
                      future: _cachedScoreData == null
                          ? EduServiceRepository.getInstance()
                              .loadExamScoreRemotely(_info,
                                  semesterId:
                                      _unpackedSemester![semester!].semesterId)
                          : Future.value(_cachedScoreData),
                      loadingBuilder: PlatformCircularProgressIndicator(),
                      errorBuilder: nil,
                      successBuilder: (context, snapshot) {
                        if (snapshot.hasData) {
                          _cachedScoreData = snapshot.data;
                          try {
                            return Row(
                              children: [
                                const SizedBox(
                                  width: 8,
                                ),
                                _buildGradeContainer(
                                    _cachedScoreData!
                                        .firstWhere(
                                            (element) => element.id == value.id)
                                        .level,
                                    _cachedScoreData!
                                        .firstWhere(
                                            (element) => element.id == value.id)
                                        .score)
                              ],
                            );
                            // If we cannot find such an element, we will build an empty SizedBox.
                          } catch (_) {}
                        }
                        return nil;
                      },
                    ),
                  )
                ] else ...[
                  Expanded(
                      child: Text(S.of(context).failed_exam_no_grade,
                          softWrap: true, textAlign: TextAlign.right))
                ]
              ],
            )),
      );

  // Grade card without exam data
  Widget _buildCardGrade(ExamScore value, BuildContext context) => Card(
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: ViewportUtils.getMainNavigatorWidth(context) - 80,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value.type,
                        textScaler: TextScaler.linear(0.8),
                        style: TextStyle(color: Theme.of(context).hintColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                      Text(
                        value.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                _buildGradeContainer(value.level, value.score)
              ],
            )),
      );
}
