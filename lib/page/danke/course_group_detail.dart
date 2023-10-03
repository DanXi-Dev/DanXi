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

import 'dart:async';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/danke/course_group.dart';
import 'package:dan_xi/model/danke/course_review.dart';
import 'package:dan_xi/page/danke/course_review_editor.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/danke/curriculum_board_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/widget/danke/course_review_widget.dart';
import 'package:dan_xi/widget/danke/course_widgets.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/platform_context_menu.dart';
import 'package:dan_xi/widget/libraries/top_controller.dart';
import 'package:dan_xi/widget/opentreehole/treehole_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import '../../util/stream_listener.dart';

enum FilterType { TEACHER_FILTER, TIME_FILTER }

class RefreshFilterEvent {
  // 0: Teacher filter, 1: Time filter
  final FilterType filterType;
  final String newFilter;

  RefreshFilterEvent(this.newFilter, this.filterType);
}

class CourseGroupDetail extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const CourseGroupDetail({Key? key, this.arguments}) : super(key: key);

  @override
  CourseGroupDetailState createState() => CourseGroupDetailState();
}

class CourseGroupDetailState extends State<CourseGroupDetail> {
  /// Unrelated to the state.
  /// These fields should only be initialized once when created.
  late int groupId;
  CourseGroup? _courseGroup;
  late int averageOverallLevel;
  String? _searchKeyword;
  FileImage? _backgroundImage;
  Set<String> teacherSet = {};
  Set<String> timeSet = {};

  String teacherFilter = "*";
  String timeFilter = "*";

  final StateStreamListener<RefreshFilterEvent> _refreshSubscription =
      StateStreamListener();

  final PagedListViewController<CourseReview> _listViewController =
      PagedListViewController<CourseReview>();

  final GlobalKey<RefreshIndicatorState> indicatorKey =
      GlobalKey<RefreshIndicatorState>();

  CourseReview? locateReview;

  /// Reload/load the (new) content
  List<CourseReview>? _loadContent(BuildContext contxt) {
    List<CourseReview> result = [];
    for (var elem in _courseGroup!.courseList!) {
      if (elem.reviewList != null) {
        result += elem.reviewList!.filter((element) {
          if (teacherFilter != "*" &&
              element.courseInfo.teachers != teacherFilter) {
            return false;
          }

          if (timeFilter != "*" && element.courseInfo.time != timeFilter) {
            return false;
          }

          return true;
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (locateReview != null && mounted) {
        try {
          // Scroll to the specific item
          await _listViewController.scrollToItem(locateReview!);
          locateReview = null;
        } catch (e) {
          debugPrint(e.toString());
        }
      }
    });

    return result;
  }

  @override
  void initState() {
    super.initState();
    if (widget.arguments!.containsKey('group_id')) {
      groupId = widget.arguments!['group_id'];
    }
    if (widget.arguments!.containsKey('locate')) {
      locateReview = widget.arguments!['locate'];
    }

    StateProvider.needScreenshotWarning = true;

    _refreshSubscription.bindOnlyInvalid(
        Constant.eventBus.on<RefreshFilterEvent>().listen((event) {
          switch (event.filterType) {
            case FilterType.TEACHER_FILTER:
              teacherFilter = event.newFilter;
              break;
            case FilterType.TIME_FILTER:
              timeFilter = event.newFilter;
              break;
          }
          indicatorKey.currentState?.show();
        }),
        hashCode);
  }

  /// Refresh the whole list (excluding the head)
  Future<void> refreshList({bool scrollToEnd = false}) async {
    await _fetchCourseGroup(forceRefetch: true);
    await refreshSelf();
    if (scrollToEnd) _listViewController.queueScrollToEnd();
    return _listViewController.notifyUpdate(
        useInitialData: false, queueDataClear: true);
  }

  Future<CourseGroup?> _fetchCourseGroup({bool forceRefetch = false}) async {
    if (forceRefetch) {
      _courseGroup =
          await CurriculumBoardRepository.getInstance().getCourseGroup(groupId);
    } else {
      _courseGroup ??=
          await CurriculumBoardRepository.getInstance().getCourseGroup(groupId);
    }

    // The old api doesn't return a credit list in the course group
    // So we have to generate it here
    _courseGroup!.credits ??=
        _courseGroup!.courseList!.map((e) => e.credit!).toSet().toList();

    int totalScore = 0, scoreCount = 0;
    for (var elem in _courseGroup!.courseList!) {
      teacherSet.add(elem.teachers!);
      timeSet.add(elem.formatTime());
      if (elem.reviewList != null) {
        scoreCount += elem.reviewList!.length;

        for (var rev in elem.reviewList!) {
          rev.linkCourse(elem.getSummary());
          totalScore += rev.rank!.overall!;
        }
      }
    }
    averageOverallLevel = (scoreCount > 0 ? (totalScore ~/ scoreCount) : 0) - 1;

    return _courseGroup;
  }

  @override
  void dispose() {
    StateProvider.needScreenshotWarning = false;
    _refreshSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _backgroundImage = SettingsProvider.getInstance().backgroundImage;

    return PlatformScaffold(
      iosContentPadding: false,
      iosContentBottomPadding: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
        title: TopController(
          controller: PrimaryScrollController.of(context),
          child: Text(S.of(context).curriculum_details),
        ),
        trailingActions: [
          if (_searchKeyword == null) ...[
            PlatformIconButton(
              padding: EdgeInsets.zero,
              icon: PlatformX.isMaterial(context)
                  ? const Icon(Icons.reply)
                  : const Icon(CupertinoIcons.arrowshape_turn_up_left),
              onPressed: () async {
                if (await CourseReviewEditor.createNewPost(
                    context, _courseGroup!)) {
                  refreshList(scrollToEnd: true);
                }
              },
            ),
            PlatformPopupMenuX(
              options: [
                PopupMenuOption(
                    label: S.of(context).scroll_to_end,
                    onTap: _onTapScrollToEnd),
              ],
              cupertino: (context, platform) => CupertinoPopupMenuData(
                  cancelButtonData: CupertinoPopupMenuCancelButtonData(
                      child: Text(S.of(context).cancel))),
              icon: PlatformX.isMaterial(context)
                  ? const Icon(Icons.more_vert)
                  : const Icon(CupertinoIcons.ellipsis),
            ),
          ]
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Builder(
      // The builder widget updates context so that MediaQuery below can use the correct context (that is, Scaffold considered)
      builder: (context) => Container(
        decoration: _backgroundImage == null
            ? null
            : BoxDecoration(
                image: DecorationImage(
                    image: _backgroundImage!, fit: BoxFit.cover)),
        child: RefreshIndicator(
          key: indicatorKey,
          edgeOffset: MediaQuery.of(context).padding.top,
          color: Theme.of(context).colorScheme.secondary,
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            // Refresh the list...
            await refreshList();
          },
          child: FutureWidget<CourseGroup?>(
              future: _fetchCourseGroup(),
              successBuilder: (context, snapshot) {
                return PagedListView<CourseReview>(
                  pagedController: _listViewController,
                  withScrollbar: true,
                  scrollController: PrimaryScrollController.of(context),

                  /// [_loadContent] does no internet request so it shall be quick
                  allDataReceiver: Future.value(_loadContent(context)),
                  builder: _getListItems,
                  headBuilder: (ctx) => _buildHead(ctx),
                  loadingBuilder: (BuildContext context) => Container(
                    padding: const EdgeInsets.all(8),
                    child: Center(child: PlatformCircularProgressIndicator()),
                  ),
                  emptyBuilder: (context) =>
                      Center(child: Text(S.of(context).no_course_review)),
                  endBuilder: (context) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(S.of(context).end_reached),
                      ),
                    );
                  },
                );
              },
              errorBuilder: (BuildContext context,
                      AsyncSnapshot<CourseGroup?> snapshot) =>
                  ErrorPageWidget.buildWidget(context, snapshot.error,
                      stackTrace: snapshot.stackTrace,
                      onTap: () => setState(() {})),
              loadingBuilder:
                  Center(child: PlatformCircularProgressIndicator())),
        ),
      ),
    );
  }

  Widget _buildHead(BuildContext context) {
    var wildCard = S.of(context).all;
    var teacherList = [
      FilterTag(wildCard, "*"),
      ...teacherSet.map((e) => FilterTag(e, e))
    ];
    var timeList = [
      FilterTag(wildCard, "*"),
      ...timeSet.map((e) => FilterTag(e, e))
    ];

    return Card(
        color: Theme.of(context).cardTheme.color?.withOpacity(0.8),
        child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(_courseGroup!.getFullName(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_courseGroup!.code!,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey)),
                        ..._courseGroup!.credits!.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: OTLeadingTag(
                              color: Colors.orange,
                              text:
                                  "${e.toStringAsFixed(1)} ${S.of(context).credits}",
                            )))
                      ],
                    )),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(S.of(context).curriculum_average_rating,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 15)),
                    const SizedBox(
                      width: 6,
                    ),
                    averageOverallLevel >= 0
                        ? Text(
                            overallWord![averageOverallLevel],
                            style: TextStyle(
                                color: wordColor[averageOverallLevel],
                                fontSize: 15),
                          )
                        : Text(S.of(context).curriculum_unknown_rating,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 15))
                  ],
                ),
                const Divider(
                  height: 5,
                  thickness: 1,
                ),
                Text(S.of(context).course_teacher_name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: FilterListWidget(
                        filters: teacherList,
                        onTap: (e) {
                          RefreshFilterEvent(e, FilterType.TEACHER_FILTER)
                              .fire();
                        },
                        defaultIndex: teacherList.indexWhere(
                            (element) => element.filter == teacherFilter))),
                const Divider(
                  height: 5,
                  thickness: 1,
                ),
                Text(S.of(context).course_schedule,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: FilterListWidget(
                        filters: timeList,
                        onTap: (e) {
                          RefreshFilterEvent(e, FilterType.TIME_FILTER).fire();
                        },
                        defaultIndex: timeList.indexWhere(
                            (element) => element.filter == timeFilter))),
              ],
            )));
  }

  Future<void> _onTapScrollToEnd(_) async {
    try {
      _listViewController.queueScrollToEnd();
      _listViewController.notifyUpdate(
          useInitialData: false, queueDataClear: false);
    } catch (error, st) {
      Noticing.showErrorDialog(context, error, trace: st);
    }
  }

  Widget _getListItems(BuildContext context,
      ListProvider<CourseReview> dataProvider, int index, CourseReview review) {
    return CourseReviewWidget(
      review: review,
      courseGroup: _courseGroup!,
    );
  }
}
