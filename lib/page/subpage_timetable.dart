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
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/common/feature_registers.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/page/home_page.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/fdu/edu_service_repository.dart';
import 'package:dan_xi/repository/fdu/postgraduate_timetable_repository.dart';
import 'package:dan_xi/repository/fdu/time_table_repository.dart';
import 'package:dan_xi/repository/forum/forum_repository.dart';
import 'package:dan_xi/util/io/cache_manager_with_webvpn.dart';
import 'package:dan_xi/util/lazy_future.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/retrier.dart';
import 'package:dan_xi/util/stream_listener.dart';
import 'package:dan_xi/util/timetable_converter_impl.dart';
import 'package:dan_xi/widget/dialogs/manually_add_course_dialog.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/platform_context_menu.dart';
import 'package:dan_xi/widget/time_table/day_events.dart';
import 'package:dan_xi/widget/time_table/schedule_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/// Keys to locate buttons in the interactive tutorial.
GlobalKey keyButton = GlobalKey();
GlobalKey keyButton1 = GlobalKey();
GlobalKey keyButton2 = GlobalKey();

const kCompatibleUserGroup = [
  UserGroup.FUDAN_UNDERGRADUATE_STUDENT,
  UserGroup.FUDAN_POSTGRADUATE_STUDENT
];

/// Only some user groups can select the semester.
/// For other user groups, the semester selection button should be hidden.
const kSemesterSelectionCompatibleUserGroup = [
  UserGroup.FUDAN_UNDERGRADUATE_STUDENT
];

class TimetableSubPage extends PlatformSubpage<TimetableSubPage> {
  @override
  TimetableSubPageState createState() => TimetableSubPageState();

  const TimetableSubPage({super.key});

  @override
  Create<Widget> get title => (cxt) => Text(S.of(cxt).timetable);

  @override
  Create<List<AppBarButtonItem>> get trailing => (cxt) => [
        AppBarButtonItem(
          S.of(cxt).add_courses,
          Icon(
            PlatformX.isMaterial(cxt) ? Icons.add : CupertinoIcons.add_circled,
            key: keyButton,
          ),
          () => ManuallyAddCourseEvent().fire(),
        ),
        AppBarButtonItem(
          S.of(cxt).share,
          Icon(PlatformX.isMaterial(cxt)
              ? Icons.share
              : CupertinoIcons.square_arrow_up),
          () => ShareTimetableEvent().fire(),
        ),
      ];

  @override
  Create<List<AppBarButtonItem>> get leading => (cxt) => [
        if (checkGroup(kSemesterSelectionCompatibleUserGroup))
          AppBarButtonItem(
              S.of(cxt).select_semester,
              SemesterSelectionButton(
                key: keyButton1,
                onSelectionUpdate: () {
                  timetablePageKey.currentState?.indicatorKey.currentState
                      ?.show();
                },
              ),
              null,
              useCustomWidget: true),
      ];
}

class ShareTimetableEvent {}

class ManuallyAddCourseEvent {}

class TimetableSubPageState extends PlatformSubpageState<TimetableSubPage> {
  final StateStreamListener<ShareTimetableEvent> _shareSubscription =
      StateStreamListener();
  final StateStreamListener<ManuallyAddCourseEvent> _addCourseSubscription =
      StateStreamListener();

  static const String KEY_MANUALLY_ADDED_COURSE = "new_courses";

  /// A map of all converters.
  ///
  /// A converter is used to export the time table as a single file, e.g. .ics.
  late Map<String, TimetableConverter> converters;

  /// The time table it fetched.
  TimeTable? _table;

  ///The week it's showing on the time table.
  TimeNow? _showingTime;

  Future<TimeTable?>? _contentFuture;

  bool forceLoadFromRemote = false;

  List<Course> newCourses = [];

  List<int> courseAvailableList = [];

  final GlobalKey<RefreshIndicatorState> indicatorKey =
      GlobalKey<RefreshIndicatorState>();

  List<Course> getCourseList() {
    return SettingsProvider.getInstance().manualAddedCourses;
  }

  /// Set the future that fetches the content.
  ///
  /// Note: in this method, when forceLoadFromRemote = false (i.e. called from [initState]),
  /// [context] is NOT available. DO NOT use [context] in that case.
  /// For example, instead of using [S.of(context)], use [S.current].
  void _setContent() {
    newCourses = getCourseList();
    if (checkGroup(kCompatibleUserGroup)) {
      if (StateProvider.personInfo.value!.group ==
          UserGroup.FUDAN_UNDERGRADUATE_STUDENT) {
        _contentFuture = LazyFuture.pack(Retrier.runAsyncWithRetry(() =>
            TimeTableRepository.getInstance().loadTimeTable(
                StateProvider.personInfo.value,
                forceLoadFromRemote: forceLoadFromRemote)));
      } else if (forceLoadFromRemote) {
        _contentFuture = LazyFuture.pack(
            PostgraduateTimetableRepository.getInstance().loadTimeTable(
                StateProvider.personInfo.value!, (imageUrl) async {
          TextEditingController controller = TextEditingController();
          // TODO: dispose
          await showPlatformDialog(
              context: context,
              barrierDismissible: false,
              builder: (cxt) => PlatformAlertDialog(
                    title: Text(S.of(context).enter_captcha),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CachedNetworkImage(
                            imageUrl: imageUrl,
                            cacheManager: DefaultCacheManagerWithWebvpn(),
                            // Ensure shape is the same as the loading indicator
                            fit: BoxFit.contain,
                            progressIndicatorBuilder:
                                (context, url, progress) =>
                                    PlatformCircularProgressIndicator()),
                        TextField(controller: controller)
                      ],
                    ),
                    actions: [
                      PlatformDialogAction(
                        child: Text(S.of(context).ok),
                        onPressed: () => Navigator.of(cxt).pop(),
                      )
                    ],
                  ));
          return controller.text;
        }, forceLoadFromRemote: forceLoadFromRemote));
      } else {
        try {
          _contentFuture = Future.value(
              PostgraduateTimetableRepository.getInstance()
                  .loadTimeTableLocally());
          // If throw an error, it means we don't have a valid timetable.
        } catch (_) {
          _contentFuture = LazyFuture.pack(Future<TimeTable?>.error(
              NotLoginError(S.current.postgraduates_need_login)));
        }
      }
      forceLoadFromRemote = false;
    } else {
      _contentFuture = LazyFuture.pack(
          Future<TimeTable?>.error(NotLoginError(S.current.not_fudan_student)));
    }
    _contentFuture?.then(
        (value) => TimeTable.mergeManuallyAddedCourses(value, newCourses));
  }

  void _startShare(
      BuildContext menuContext, TimetableConverter converter) async {
    // Close the dialog first
    Navigator.of(menuContext).pop();
    if (_table == null) {
      Noticing.showNotice(context, S.of(context).fatal_error);
      return;
    }
    String? converted = converter.convertTo(_table!);
    if (converted == null ||
        converter.mimeType == null ||
        converter.fileName == null) {
      return;
    } // If the converter does not export a file, return.
    Directory documentDir = await getApplicationDocumentsDirectory();
    File outputFile = PlatformX.createPlatformFile(
        "${documentDir.absolute.path}/output_timetable/${converter.fileName}");
    outputFile.createSync(recursive: true);
    await outputFile.writeAsString(converted, flush: true);
    if (PlatformX.isIOS) {
      OpenFile.open(outputFile.absolute.path, type: converter.mimeType);
    } else if (PlatformX.isAndroid) {
      Share.shareXFiles(
          [XFile(outputFile.absolute.path, mimeType: converter.mimeType!)]);
    } else if (mounted) {
      Noticing.showNotice(context, outputFile.absolute.path);
    }
  }

  List<Widget> _buildShareList(BuildContext context) {
    return converters.entries
        .map<Widget>((MapEntry<String, TimetableConverter> e) {
      return PlatformWidget(
        cupertino: (_, __) => CupertinoActionSheetAction(
          onPressed: () => _startShare(context, e.value),
          child: Text(e.key),
        ),
        material: (_, __) => ListTile(
          title: Text(e.key),
          subtitle: Text(e.value.fileName ?? ""),
          onTap: () => _startShare(context, e.value),
        ),
      );
    }).toList();
  }

  @override
  void initState() {
    if (!SettingsProvider.getInstance().hasVisitedTimeTable) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => createTutorial().show(context: context));
      SettingsProvider.getInstance().hasVisitedTimeTable = true;
    }
    super.initState();
    _setContent();
    converters = {S.current.share_as_ics: ICSConverter()};
    _shareSubscription.bindOnlyInvalid(
        Constant.eventBus.on<ShareTimetableEvent>().listen((_) {
          if (_table == null) return;
          if (!mounted) return;
          showPlatformModalSheet(
            context: context,
            builder: (BuildContext context) => PlatformContextMenu(
              actions: _buildShareList(context),
              cancelButton: CupertinoActionSheetAction(
                child: Text(S.of(context).cancel),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          );
        }),
        hashCode);
    _addCourseSubscription.bindOnlyInvalid(
        Constant.eventBus.on<ManuallyAddCourseEvent>().listen((_) async {
          if (_table == null) return;
          if (!mounted) return;
          newCourses = (await showPlatformDialog<Course?>(
            context: context,
            builder: (_) => ManuallyAddCourseDialog(courseAvailableList),
          ).then<List<Course>>((course) {
            List<Course> courseList = getCourseList();
            if (course == null) {
              return courseList;
            }
            List<Course> newCourseList = courseList + [course];
            SettingsProvider.getInstance().manualAddedCourses = newCourseList;
            return newCourseList;
          }));
          refresh();
        }),
        hashCode);
  }

  TutorialCoachMark createTutorial() => TutorialCoachMark(
        targets: _createTargets(),
        colorShadow: const Color.fromARGB(255, 9, 110, 192),
        textSkip: S.of(context).skip,
        paddingFocus: 10,
        opacityShadow: 0.5,
        pulseAnimationDuration: const Duration(milliseconds: 1000),
        imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      );

  List<TargetFocus> _createTargets() => [
        _createTarget(
          identify: "SemesterSelectionButton",
          keyTarget: keyButton1,
          title: S.of(context).choose_semester,
          message: S.of(context).choose_semester_message,
          hasActionWidget: false,
        ),
        _createTarget(
          identify: "ManuallyAddCourseButton",
          keyTarget: keyButton,
          title: S.of(context).manually_add_course,
          message: S.of(context).manually_add_course_message,
          hasActionWidget: true,
          shape: ShapeLightFocus.RRect,
        ),
        _createTarget(
          identify: "StartDateSelectionButton",
          keyTarget: keyButton2,
          title: S.of(context).start_date_select,
          message: S.of(context).start_date_select_message,
          hasActionWidget: true,
        ),
      ];

  TargetFocus _createTarget({
    required String identify,
    required GlobalKey keyTarget,
    required String title,
    required String message,
    ShapeLightFocus shape = ShapeLightFocus.Circle,
    double radius = 5,
    bool? hasActionWidget,
  }) =>
      TargetFocus(
        identify: identify,
        keyTarget: keyTarget,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20.0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (hasActionWidget != false)
                  ElevatedButton(
                    onPressed: controller.previous,
                    child: const Icon(Icons.chevron_left),
                  ),
              ],
            ),
          ),
        ],
        shape: shape,
        radius: radius,
      );

  Future<void> refresh(
      {bool reloadWhenEmptyData = false,
      bool forceReloadFromRemote = false}) async {
    if (forceReloadFromRemote) forceLoadFromRemote = true;
    _setContent();
    // If there is no data before, we call setState once to show a ProgressIndicator.
    if (reloadWhenEmptyData) setState(() {});
    await _contentFuture;
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    _shareSubscription.cancel();
    _addCourseSubscription.cancel();
  }

  @override
  Widget buildPage(BuildContext context) {
    return FutureWidget<TimeTable?>(
      successBuilder:
          (BuildContext context, AsyncSnapshot<TimeTable?> snapshot) {
        if (snapshot.hasData) {
          return _buildPage(context, snapshot.data!);
        } else {
          return const CircularProgressIndicator();
        }
      },
      future: _contentFuture,
      errorBuilder: (BuildContext context,
              AsyncSnapshot<TimeTable?> snapshot) =>
          ErrorPageWidget.buildWidget(context, snapshot.error,
              stackTrace: snapshot.stackTrace, onTap: () {
        forceLoadFromRemote = true;
        refresh(reloadWhenEmptyData: true);
      },
              buttonText:
                  snapshot.error is NotLoginError ? S.of(context).login : null),
      loadingBuilder: Center(child: PlatformCircularProgressIndicator()),
    );
  }

  goToPrev() {
    setState(() {
      _showingTime!.week--;
    });
  }

  goToNext() {
    setState(() {
      _showingTime!.week++;
    });
  }

  Widget _buildCourseItem(Event event, BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.course.courseName ?? "null",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (event.course.teacherNames != null)
                    Text(event.course.teacherNames!.join(",")),
                  if (event.course.roomName != null)
                    Text(event.course.roomName!),
                  if (event.course.courseId != null)
                    Text(event.course.courseId!),
                ],
              )),
              if (event.course.roomId == "999999") ...[
                PlatformIconButton(
                  icon: Icon(PlatformX.isMaterial(context)
                      ? Icons.delete
                      : CupertinoIcons.delete),
                  onPressed: () {
                    newCourses.removeWhere(
                        (e) => e.courseId == event.course.courseId);
                    SettingsProvider.getInstance().manualAddedCourses =
                        newCourses;
                    Navigator.of(context).pop();
                    refresh();
                  },
                ),
              ]
            ],
          ),
        ),
      );

  void _onTapCourse(ScheduleBlock block) {
    showPlatformModalSheet(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children:
              block.event.map((e) => _buildCourseItem(e, context)).toList(),
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, TimeTable table) {
    DateTime? lastUpdatedTime = context.select<SettingsProvider, DateTime?>(
        (value) => value.timetableLastUpdated);

    const TimetableStyle style = TimetableStyle();
    _table = table;
    _showingTime ??= _table!.now();

    // Limit [_showingTime] to an appropriate range
    if (_showingTime!.week < 0) _showingTime!.week = 0;
    if (_showingTime!.week > TimeTable.MAX_WEEK) {
      _showingTime!.week = TimeTable.MAX_WEEK;
    }
    if (_showingTime!.weekday < 0) _showingTime!.weekday = 0;
    if (_showingTime!.weekday > 6) _showingTime!.weekday = 6;

    final List<DayEvents> scheduleData = _table!
        .toDayEvents(_showingTime!.week, compact: TableDisplayType.STANDARD);
    return RefreshIndicator(
      key: indicatorKey,
      edgeOffset: MediaQuery.of(context).padding.top,
      color: Theme.of(context).colorScheme.secondary,
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      onRefresh: () async {
        forceLoadFromRemote = true;
        HapticFeedback.mediumImpact();
        await refresh();
      },
      child: ListView(
        // This ListView is a workaround, so that we can apply a custom scroll physics to it.
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PlatformIconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _showingTime!.week > 0 ? goToPrev : null,
              ),
              Text(S.of(context).week(_showingTime!.week)),
              PlatformIconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed:
                    _showingTime!.week < TimeTable.MAX_WEEK ? goToNext : null,
              )
            ],
          ),
          ScheduleView(
            scheduleData,
            style,
            _table!.now(),
            _showingTime!.week,
            tapCallback: _onTapCourse,
          ),
          SizedBox(
            height: 10,
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(S.of(context).timetable_last_updated),
            lastUpdatedTime == null
                ? Text(S.of(context).timetable_no_last_updated)
                : Text(DateFormat("yyyy-MM-dd HH:mm").format(lastUpdatedTime))
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(S.of(context).semester_start_date),
            StartDateSelectionButton(
                key: keyButton2,
                onUpdate: (() => indicatorKey.currentState?.show())),
          ]),
        ],
      ),
    );
  }
}

/// Show a button to select the semester.
class SemesterSelectionButton extends StatefulWidget {
  final void Function()? onSelectionUpdate;

  const SemesterSelectionButton({super.key, this.onSelectionUpdate});

  @override
  SemesterSelectionButtonState createState() => SemesterSelectionButtonState();
}

class SemesterSelectionButtonState extends State<SemesterSelectionButton> {
  List<SemesterInfo>? _semesterInfo;
  SemesterInfo? _selectionInfo;
  late Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = LazyFuture.pack(loadSemesterInfo());
  }

  Future<void> loadSemesterInfo() async {
    _semesterInfo = await EduServiceRepository.getInstance()
        .loadSemesters(StateProvider.personInfo.value);
    // Reverse the order to make the newest item at top
    _semesterInfo = _semesterInfo?.reversed.toList();
    String? chosenSemester = SettingsProvider.getInstance().timetableSemester;
    if (chosenSemester == null || chosenSemester.isEmpty) {
      chosenSemester = await TimeTableRepository.getInstance()
          .getDefaultSemesterId(StateProvider.personInfo.value);
    }
    _selectionInfo = _semesterInfo!
        .firstWhere((element) => element.semesterId == chosenSemester!);
  }

  @override
  Widget build(BuildContext context) => FutureWidget<void>(
      future: _future,
      nullable: true,
      successBuilder: (BuildContext context, AsyncSnapshot<void> snapshot) =>
          PlatformIconButton(
            padding: EdgeInsets.zero,
            icon: AutoSizeText(
                "${_selectionInfo!.schoolYear} ${_selectionInfo!.name!}",
                minFontSize: 10),
            onPressed: () => showPlatformModalSheet(
              context: context,
              builder: (menuContext) => PlatformContextMenu(
                cancelButton: CupertinoActionSheetAction(
                    child: Text(S.of(menuContext).cancel),
                    onPressed: () => Navigator.of(menuContext).pop()),
                actions: _semesterInfo!
                    .map((e) => PlatformContextMenuItem(
                        menuContext: menuContext,
                        onPressed: () {
                          SettingsProvider.getInstance().timetableSemester =
                              e.semesterId;
                          setState(() => _selectionInfo = e);

                          // Try to parse the start date
                          String? parsedStartDate =
                              SettingsProvider.getInstance()
                                  .semesterStartDates
                                  ?.parseStartDate(
                                      StateProvider.personInfo.value!.group,
                                      e.semesterId!);
                          if (parsedStartDate != null) {
                            SettingsProvider.getInstance()
                                .thisSemesterStartDate = parsedStartDate;
                          } else {
                            Noticing.showNotice(
                                this.context,
                                S.of(context).unknown_start_date(
                                    "${e.schoolYear} ${e.name!}"));
                          }
                          widget.onSelectionUpdate?.call();
                        },
                        child: Text(
                          "${e.schoolYear} ${e.name!}",
                          // Highlight the selected item
                          style: TextStyle(
                              color: PlatformX.isMaterial(context) &&
                                      e.semesterId == _selectionInfo?.semesterId
                                  ? Theme.of(context).colorScheme.secondary
                                  : null),
                        )))
                    .toList(),
              ),
            ),
          ),
      errorBuilder: () => PlatformIconButton(
            padding: EdgeInsets.zero,
            icon: Text(S.of(context).failed),
            onPressed: () => setState(() {
              _future = LazyFuture.pack(loadSemesterInfo());
            }),
          ),
      loadingBuilder: () => PlatformIconButton(
            padding: EdgeInsets.zero,
            icon: Text(S.of(context).loading),
          ));
}

class StartDateSelectionButton extends StatelessWidget {
  const StartDateSelectionButton({super.key, this.onUpdate});

  final void Function()? onUpdate;

  @override
  Widget build(BuildContext context) {
    DateTime startTime = context.select<SettingsProvider, DateTime>((value) {
      var startDateStr = value.thisSemesterStartDate;
      DateTime? startDate;
      if (startDateStr != null) startDate = DateTime.tryParse(startDateStr);
      return startDate ?? Constant.DEFAULT_SEMESTER_START_DATE;
    });
    return PlatformTextButton(
      padding: PlatformX.isCupertino(context) ? EdgeInsets.zero : null,
      child: Text(DateFormat("yyyy-MM-dd").format(startTime)),
      onPressed: () async {
        DateTime? newDate = await showPlatformDatePicker(
            context: context,
            cupertino: (cxt, __) => CupertinoDatePickerData(
                doneLabel: S.of(cxt).ok, cancelLabel: S.of(cxt).cancel),
            material: (cxt, __) => MaterialDatePickerData(
                helpText: S.of(cxt).semester_start_date,
                confirmText: S.of(cxt).ok),
            initialDate: startTime,
            firstDate: DateTime.fromMillisecondsSinceEpoch(0),
            lastDate: startTime.add(const Duration(days: 365 * 100)));
        if (newDate != null && newDate != startTime && context.mounted) {
          // Notice user that newDate is not a Monday.
          if (newDate.weekday != DateTime.monday) {
            bool? confirmed = await Noticing.showConfirmationDialog(
                context, S.of(context).semester_start_at_monday);
            if (confirmed != true) {
              return;
            }
          }
          SettingsProvider.getInstance().thisSemesterStartDate =
              newDate.toIso8601String();
          onUpdate?.call();
        }
      },
    );
  }
}
