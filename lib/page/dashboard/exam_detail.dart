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
import 'package:dan_xi/provider/state_provider.dart' as sp;
import 'package:dan_xi/repository/fdu/data_center_repository.dart';
import 'package:dan_xi/repository/fdu/edu_service_repository.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/viewport_utils.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ical/serializer.dart';
import 'package:nil/nil.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'exam_detail.g.dart';

@riverpod
Future<List<GPAListItem>> gpa(Ref ref) async {
  return await EduServiceRepository.getInstance().loadGPARemotely();
}

@riverpod
Future<List<SemesterInfo>> semester(Ref ref) async {
  return (await EduServiceRepository.getInstance().loadSemestersRemotely())
      .semesters;
}

@riverpod
Future<List<Exam>> exam(Ref ref, String semesterId) async {
  return await EduServiceRepository.getInstance().loadExamListRemotely();
}

@riverpod
Future<List<ExamScore>> examScore(Ref ref, String semesterId) async {
  return await EduServiceRepository.getInstance()
      .loadExamScoreRemotely(semesterId);
}

@riverpod
Future<List<ExamScore>> examScoreFromDataCenter(Ref ref) async {
  return await DataCenterRepository.getInstance()
      .loadAllExamScore(sp.StateProvider.personInfo.value);
}

/// A list page showing user's GPA scores and exam information.
/// It will try to fetch [SemesterInfo] first.
/// If successful, it will fetch exams in this term. In case that there is no exam, it shows the score of this term.
/// If failed, it will try to fetch the list of score in all terms from DataCenter.
class ExamList extends HookConsumerWidget {
  final Map<String, dynamic>? arguments;

  const ExamList({super.key, this.arguments});

  void _exportICal(BuildContext context, List<Exam> examList) async {
    if (examList.isEmpty) {
      Noticing.showNotice(context, S.of(context).exam_unavailable,
          title: S.of(context).fatal_error);
      return;
    }
    ICalendar cal = ICalendar(company: 'DanXi', lang: "CN");
    for (var element in examList) {
      if (element.date.trim().isNotEmpty && element.time.trim().isNotEmpty) {
        try {
          cal.addElement(IEvent(
            summary: element.name,
            location: element.location,
            status: IEventStatus.CONFIRMED,
            description:
                "${element.testCategory} ${element.type}\n${element.note}",
            // toUtc: https://github.com/DanXi-Dev/DanXi/issues/522
            start:
                DateTime.parse('${element.date} ${element.time.split('~')[0]}')
                    .toUtc(),
            end: DateTime.parse('${element.date} ${element.time.split('~')[1]}')
                .toUtc(),
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
      SharePlus.instance.share(ShareParams(
          files: [XFile(outputFile.absolute.path, mimeType: "text/calendar")]));
    } else if (context.mounted) {
      Noticing.showNotice(context, outputFile.absolute.path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semesters = ref.watch(semesterProvider);
    final currentSemesterIndex = useState<int?>(null);
    final currentExamRef = useState<List<Exam>?>(null);

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
              onPressed: currentExamRef.value != null
                  ? () => _exportICal(context, currentExamRef.value!)
                  : null,
            ),
          ],
        ),
        body: SafeArea(
          child: switch (semesters) {
            AsyncData(:final value) => _loadExamGradeHybridView(
                context, ref, value, currentSemesterIndex,
                currentExamRef: currentExamRef),
            AsyncError() => _loadGradeViewFromDataCenter(context, ref),
            _ => Center(child: PlatformCircularProgressIndicator()),
          },
        ));
  }

  Widget _loadExamGradeHybridView(BuildContext context, WidgetRef ref,
      List<SemesterInfo> semesters, ValueNotifier<int?> currentSemesterIndex,
      {ValueNotifier<List<Exam>?>? currentExamRef}) {
    final currentSemesterIndexValue =
        currentSemesterIndex.value ?? semesters.length - 3;
    final currentSemester = semesters[currentSemesterIndexValue];

    final currentExamProvider = examProvider(currentSemester.semesterId!);
    final currentScoreProvider = examScoreProvider(currentSemester.semesterId!);
    final exams = ref.watch(currentExamProvider);
    final scores = ref.watch(currentScoreProvider);

    void reloadData() {
      ref.invalidate(currentExamProvider);
      ref.invalidate(currentScoreProvider);
    }

    Widget body;
    List<Exam>? examList;
    switch ((exams, scores)) {
      // Both exams and scores are available
      case (AsyncData(value: final exams), AsyncData(value: final scores)):
        examList = exams;
        body = exams.isEmpty
            ? _buildGradeLayout(context, ref, scores)
            : ListView(
                children: _getListWidgetsHybrid(context, ref, exams, scores));
      // There are some exams in this semester, but no score has been published
      case (AsyncData(value: final exams), AsyncError(error: final scoreError))
          when scoreError is RangeError:
        body =
            ListView(children: _getListWidgetsHybrid(context, ref, exams, []));
      // There is no exam in this semester, but never mind, we are still loading scores
      case (AsyncError(:final error), AsyncLoading())
          when error is SemesterNoExamException:
        body = Center(child: PlatformCircularProgressIndicator());
      // There is no exam in this semester, but we indeed have scores!
      case (AsyncError(:final error), AsyncData(value: final scores))
          when error is SemesterNoExamException:
        body = _buildGradeLayout(context, ref, scores);
      // There is no exam in this semester, and no scores have been published
      case (
            AsyncError(error: final examError),
            AsyncError(error: final scoreError)
          )
          when examError is SemesterNoExamException && scoreError is RangeError:
        body = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Center(
              child: Text(S.of(context).no_data),
            ));
      // Other cases, such as loading or error
      case (AsyncError(:final error, :final stackTrace), _):
        body = ErrorPageWidget.buildWidget(
          context,
          error,
          stackTrace: stackTrace,
          onTap: reloadData,
        );
      case (_, AsyncError(:final error, :final stackTrace)):
        if (error is RangeError) {
          body = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Center(
                child: Text(S.of(context).no_data),
              ));
        } else {
          body = ErrorPageWidget.buildWidget(context, error,
              stackTrace: stackTrace, onTap: reloadData);
        }
      default:
        body = Center(child: PlatformCircularProgressIndicator());
    }
    currentExamRef?.value = examList;

    final List<Widget> mainWidgets = [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PlatformIconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentSemesterIndexValue > 0
                ? () =>
                    currentSemesterIndex.value = currentSemesterIndexValue - 1
                : null,
          ),
          Text(S.of(context).semester(
              currentSemester.schoolYear ?? "?", currentSemester.name ?? "?")),
          PlatformIconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentSemesterIndexValue < semesters.length - 1
                ? () =>
                    currentSemesterIndex.value = currentSemesterIndexValue + 1
                : null,
          )
        ],
      ),
      Expanded(child: body)
    ];
    return Column(children: mainWidgets);
  }

  Widget _loadGradeViewFromDataCenter(BuildContext context, WidgetRef ref) {
    final scores = ref.watch(examScoreFromDataCenterProvider);
    switch (scores) {
      case AsyncData(value: final data):
        return _buildGradeLayout(context, ref, data, isFallback: true);
      case AsyncError(:final error, :final stackTrace):
        return ErrorPageWidget(
          errorMessage:
              '${S.of(context).failed}\n${S.of(context).need_campus_network}\n\nError:\n${ErrorPageWidget.generateUserFriendlyDescription(S.of(context), error)}',
          error: error,
          trace: stackTrace,
          onTap: () => ref.invalidate(examScoreFromDataCenterProvider),
          buttonText: S.of(context).retry,
        );
      default:
        return Center(child: PlatformCircularProgressIndicator());
    }
  }

  Widget _buildGradeLayout(
          BuildContext context, WidgetRef ref, List<ExamScore> examScores,
          {bool isFallback = false}) =>
      WithScrollbar(
          controller: PrimaryScrollController.of(context),
          child: ListView(
              primary: true,
              children: _getListWidgetsGrade(context, ref, examScores,
                  isFallback: isFallback)));

  Widget _buildGPACard(BuildContext context, WidgetRef ref) {
    final gpa = ref.watch(gpaProvider);
    GPAListItem? userGPA;
    if (gpa case AsyncData(value: final gpaList)) {
      try {
        userGPA = gpaList.firstWhere(
            (element) => element.id == sp.StateProvider.personInfo.value!.id);
      } catch (_) {
        // If we cannot find such an element, we will just return null.
      }
    }
    return Card(
      color: PlatformX.backgroundAccentColor(context),
      child: ListTile(
        visualDensity: VisualDensity.comfortable,
        title: Text(
          S.of(context).your_gpa,
          style: const TextStyle(color: Colors.white),
        ),
        trailing: switch (gpa) {
          AsyncData() => Text(
              userGPA?.gpa ?? "N/A",
              textScaler: TextScaler.linear(1.25),
              style: const TextStyle(color: Colors.white),
            ),
          AsyncError() => nil,
          _ => PlatformCircularProgressIndicator(),
        },
        subtitle: switch (gpa) {
          AsyncData() => Text(
              S.of(context).your_gpa_subtitle(
                  userGPA?.rank ?? "N/A", userGPA?.credits ?? "N/A"),
              style: TextStyle(color: Colors.white)),
          AsyncError() => nil,
          _ => Text(S.of(context).loading),
        },
        onTap: () {
          if (gpa case AsyncData(value: final gpaList)) {
            smartNavigatorPush(context, "/exam/gpa",
                arguments: {"gpalist": gpaList});
          }
        },
      ),
    );
  }

  List<Widget> _getListWidgetsGrade(
      BuildContext context, WidgetRef ref, List<ExamScore> scores,
      {bool isFallback = false}) {
    Widget buildLimitedCard() => Card(
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

    List<Widget> widgets = [];
    if (isFallback) {
      widgets.add(buildLimitedCard());
    } else {
      widgets.add(_buildGPACard(context, ref));
    }
    for (var value in scores) {
      widgets.add(_buildCardGrade(value, context));
    }
    return widgets;
  }

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

  Widget _buildCardHybrid(
      BuildContext context, Exam value, List<ExamScore> scores) {
    ExamScore? score;
    try {
      score = scores.firstWhere((element) => element.id == value.id);
    } catch (_) {
      // If we cannot find such an element, we will just return null.
    }
    return Card(
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
                          const SizedBox(width: 8),
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
                  child: score != null
                      ? Row(
                          children: [
                            const SizedBox(width: 8),
                            _buildGradeContainer(score.level, score.score)
                          ],
                        )
                      : nil,
                )
              ] else ...[
                Expanded(
                    child: Text(S.of(context).failed_exam_no_grade,
                        softWrap: true, textAlign: TextAlign.right))
              ]
            ],
          )),
    );
  }

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

  List<Widget> _getListWidgetsHybrid(BuildContext context, WidgetRef ref,
      List<Exam> exams, List<ExamScore> scores) {
    Widget buildDividerWithText(String text, Color? color) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(children: <Widget>[
          Expanded(child: Divider(color: color)),
          Text(" $text ", style: TextStyle(color: color)),
          Expanded(child: Divider(color: color)),
        ]));

    List<Widget> widgets = [_buildGPACard(context, ref)];
    List<Widget> secondaryWidgets = [
      buildDividerWithText(S.of(context).other_types_exam,
          Theme.of(context).textTheme.bodyLarge!.color)
    ]; //These widgets are displayed after the ones above
    if (exams.isEmpty) return widgets;
    for (var value in exams) {
      if (value.testCategory.trim() == "论文" ||
          value.testCategory.trim() == "其他" ||
          value.type != "期末考试") {
        secondaryWidgets.add(_buildCardHybrid(context, value, scores));
      } else {
        widgets.add(_buildCardHybrid(context, value, scores));
      }
    }

    // Some courses do not require an exam but also have given their scores.
    // Append these courses to the bottom of the list.
    for (var element in scores) {
      if (exams.every((exam) => exam.id != element.id)) {
        secondaryWidgets.add(_buildCardGrade(element, context));
      }
    }
    return widgets + secondaryWidgets;
  }
}
