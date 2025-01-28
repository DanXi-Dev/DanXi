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
import 'package:dan_xi/util/stream_listener.dart';
import 'package:dan_xi/widget/danke/course_review_widget.dart';
import 'package:dan_xi/widget/danke/course_widgets.dart';
import 'package:dan_xi/widget/libraries/chip_widgets.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/platform_context_menu.dart';
import 'package:dan_xi/widget/libraries/top_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

enum FilterType { TEACHER_FILTER, TIME_FILTER }

class RefreshFilterEvent {
  final FilterType filterType;
  final String newFilter;

  RefreshFilterEvent(this.newFilter, this.filterType);
}

class CourseGroupDetail extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const CourseGroupDetail({super.key, this.arguments});

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
  Future<CourseGroup?>? _courseGroupFuture;
  Future<List<CourseReview>?>? _reviewListFuture;
  bool shouldScrollToEnd = false;

  /// Reload/load the (new) content
  Future<List<CourseReview>?> _loadContent() async {
    await _courseGroupFuture;

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
    _courseGroupFuture = _fetchCourseGroup(forceRefetch: true);
    _reviewListFuture = _loadContent();

    await _courseGroupFuture;
    await refreshSelf();

    await _listViewController.notifyUpdate(
        useInitialData: false, queueDataClear: true);

    if (scrollToEnd) {
      setState(() {
        shouldScrollToEnd = true;
      });
    }
  }

  Future<CourseGroup?> _fetchCourseGroup({bool forceRefetch = false}) async {
    if (forceRefetch) {
      _courseGroup =
          await CurriculumBoardRepository.getInstance().getCourseGroup(groupId);
    } else {
      _courseGroup ??=
          await CurriculumBoardRepository.getInstance().getCourseGroup(groupId);
    }

    _processCourseGroup();
    return _courseGroup;
  }

  void _processCourseGroup() {
    int totalScore = 0, scoreCount = 0;
    for (var elem in _courseGroup!.courseList!) {
      teacherSet.add(elem.teachers!);
      timeSet.add(elem.formatTime());
      if (elem.reviewList != null) {
        scoreCount += elem.reviewList!.length;

        for (var rev in elem.reviewList!) {
          // Attach information about its parent course for each review
          rev.linkCourse(elem.getSummary());

          // calculate average score
          totalScore += rev.rank!.overall!;
        }
      }
    }
    averageOverallLevel = (scoreCount > 0 ? (totalScore ~/ scoreCount) : 0) - 1;
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
    _courseGroupFuture ??= _fetchCourseGroup();
    _reviewListFuture ??= _loadContent();

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
                  ? const Icon(Icons.add)
                  : const Icon(CupertinoIcons.add),
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
    return Container(
      decoration: _backgroundImage == null
          ? null
          : BoxDecoration(
              image:
                  DecorationImage(image: _backgroundImage!, fit: BoxFit.cover)),
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
            future: _courseGroupFuture,
            successBuilder: (context, snapshot) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (mounted) {
                  if (locateReview != null) {
                    // Scroll to the specific floor.
                    final floorToJump = locateReview!;
                    _listViewController.scheduleLoadedCallback(
                        () async =>
                            await _listViewController.scrollToItem(floorToJump),
                        rebuild: true);
                    locateReview = null;
                  }

                  if (shouldScrollToEnd) {
                    try {
                      // Scroll to end.
                      _listViewController.scheduleLoadedCallback(
                          () async => await _listViewController.scrollToEnd(),
                          rebuild: true);
                      shouldScrollToEnd = false;
                    } catch (_) {
                      // we don't care if we failed to scroll to the end.
                    }
                  }
                }
              });

              return PagedListView<CourseReview>(
                pagedController: _listViewController,
                withScrollbar: true,
                scrollController: PrimaryScrollController.of(context),
                // [_loadContent] does no internet request so it shall be quick
                allDataReceiver: _reviewListFuture,
                builder: _getListItems,
                headBuilder: _buildHead,
                loadingBuilder: (BuildContext context) => Container(
                  padding: const EdgeInsets.all(8),
                  child: Center(child: PlatformCircularProgressIndicator()),
                ),
                emptyBuilder: (context) =>
                    Center(child: Text(S.of(context).no_course_review)),
                endBuilder: (context) => Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(S.of(context).end_reached),
                  ),
                ),
              );
            },
            errorBuilder:
                (BuildContext context, AsyncSnapshot<CourseGroup?> snapshot) =>
                    ErrorPageWidget.buildWidget(context, snapshot.error,
                        stackTrace: snapshot.stackTrace,
                        onTap: () => setState(() {})),
            loadingBuilder: Center(child: PlatformCircularProgressIndicator())),
      ),
    );
  }

  Widget _buildHead(BuildContext context) {
    final overallWord =
        S.of(context).curriculum_ratings_overall_words.split(';');

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
        color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.8),
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
                            child: LeadingChip(
                              color: Colors.orange,
                              label:
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
                            overallWord[averageOverallLevel],
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
      setState(() {
        shouldScrollToEnd = true;
      });
    } catch (error, st) {
      Noticing.showErrorDialog(context, error, trace: st);
    }
  }

  Widget _getListItems(BuildContext context,
      ListProvider<CourseReview> dataProvider, int index, CourseReview review) {
    return CourseReviewWidget(
      review: review,
      courseGroup: _courseGroup!,
      reviewOperationCallback: (affectedReview) async {
        if (affectedReview != null) {
          locateReview = affectedReview;
        }

        indicatorKey.currentState?.show();
      },
    );
  }
}
