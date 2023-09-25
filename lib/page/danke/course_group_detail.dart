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

import 'package:clipboard/clipboard.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/danke/course_group.dart';
import 'package:dan_xi/model/danke/course_review.dart';
import 'package:dan_xi/model/opentreehole/floor.dart';
import 'package:dan_xi/page/danke/course_review_editor.dart';
import 'package:dan_xi/page/opentreehole/hole_editor.dart';
import 'package:dan_xi/page/subpage_treehole.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/danke/curriculum_board_repository.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/widget/danke/course_review_widget.dart';
import 'package:dan_xi/widget/danke/course_widgets.dart';
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
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
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
  CourseGroup? _courses;
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

  /*
  bool get hasPrefetchedAllData =>
      shouldScrollToEnd ||
          (_course.floors?.prefetch?.length ?? -1) > Constant.POST_COUNT_PER_PAGE;

   */

  /// Reload/load the (new) content and set the [_content] future.
  Future<List<CourseReview>?> _loadContent() async {
    List<CourseReview> result = [];
    for (var elem in _courses!.courseList!) {
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

    return result;
  }

  @override
  void initState() {
    super.initState();
    if (widget.arguments!.containsKey('group')) {
      groupId = widget.arguments!['group'];
      /*
      // Cache preloaded floor only when user views the Hole
      for (var floor
      in _course.floors?.prefetch ?? List<OTFloor>.empty(growable: false)) {
        OpenTreeHoleRepository.getInstance().cacheFloor(floor);
      }

       */
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
    try {
      if (forceRefetch) {
        _courses = await CurriculumBoardRepository.getInstance()
            .getCourseGroup(groupId);
      } else {
        _courses ??= await CurriculumBoardRepository.getInstance()
            .getCourseGroup(groupId);
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    _courses!.credit ??= _courses!.courseList!.first.credit;

    int totalScore = 0, scoreCount = 0;
    for (var elem in _courses!.courseList!) {
      teacherSet.add(elem.teachers!);
      timeSet.add(elem.formatTime());
      scoreCount += elem.reviewList!.length;

      for (var rev in elem.reviewList!) {
        rev.linkCourse(elem.getSummary());
        totalScore += rev.rank!.overall!;
      }
    }
    averageOverallLevel = (scoreCount > 0 ? (totalScore ~/ scoreCount) : 0) - 1;

    return _courses;
  }

  @override
  void dispose() {
    StateProvider.needScreenshotWarning = false;
    _refreshSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      /*
      try {
        // Replaced precached data with updated ones
        _listViewController.replaceInitialData(
            (await OpenTreeHoleRepository.getInstance().loadFloors(_course))!);
      } catch (_) {}

       */
    });
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
                    context, _courses!)) {
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
                Future<List<CourseReview>?> allDataReceiver = _loadContent();
                return PagedListView<CourseReview>(
                  pagedController: _listViewController,
                  withScrollbar: true,
                  scrollController: PrimaryScrollController.of(context),
                  // If we need to scroll to the end, we should prefetch all the data beforehand.
                  // See also [prefetchAllFloors] in [TreeHoleSubpageState].
                  allDataReceiver: allDataReceiver,
                  builder: _getListItems,
                  headBuilder: (ctx) => _buildHead(ctx),
                  loadingBuilder: (BuildContext context) => Container(
                    padding: const EdgeInsets.all(8),
                    child: Center(child: PlatformCircularProgressIndicator()),
                  ),
                  endBuilder: (context) => Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(S.of(context).end_reached),
                    ),
                  ),
                );
              },
              errorBuilder: (BuildContext context,
                      AsyncSnapshot<CourseGroup?> snapshot) =>
                  errorCard(snapshot, () => setState(() {})),
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
                Text(_courses!.getFullName(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_courses!.code!,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey)),
                        const SizedBox(
                          width: 8,
                        ),
                        ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 56),
                            child: OTLeadingTag(
                              color: Colors.orange,
                              text:
                                  "${_courses!.credit!.toStringAsFixed(1)} ${S.of(context).credits}",
                            )),
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
    ProgressFuture dialog = showProgressDialog(
        loadingText: S.of(context).loading, context: context);
    try {
      _listViewController.queueScrollToEnd();
    } catch (error, st) {
      Noticing.showErrorDialog(context, error, trace: st);
    } finally {
      dialog.dismiss(showAnim: false);
    }
  }

  List<Widget> _buildContextMenu(BuildContext menuContext, OTFloor e) {
    List<Widget> menu = [
      if (e.is_me == true && e.deleted == false)
        PlatformContextMenuItem(
          menuContext: menuContext,
          onPressed: () async {
            if (await OTEditor.modifyReply(
                context, e.hole_id, e.floor_id, e.content)) {
              Noticing.showMaterialNotice(
                  context, S.of(context).request_success);
            }
            // await refreshListView();
            // // Set duration to 0 to execute [jumpTo] to the top.
            // await _listViewController.scrollToIndex(0, const Duration());
            // await scrollDownToFloor(e);
          },
          child: Text(S.of(context).modify),
        ),

      // Standard Operations
      PlatformContextMenuItem(
        menuContext: menuContext,
        onPressed: () => smartNavigatorPush(context, "/text/detail",
            arguments: {"text": e.filteredContent}),
        child: Text(S.of(menuContext).free_select),
      ),
      PlatformContextMenuItem(
          menuContext: menuContext,
          child: Text(S.of(menuContext).copy),
          onPressed: () async {
            await FlutterClipboard.copy(renderText(e.filteredContent!, '', ''));
            if (mounted) {
              Noticing.showMaterialNotice(
                  context, S.of(menuContext).copy_success);
            }
          }),
      PlatformContextMenuItem(
        menuContext: menuContext,
        isDestructive: true,
        onPressed: () async {
          if (await OTEditor.reportPost(context, e.floor_id)) {
            Noticing.showMaterialNotice(context, S.of(context).report_success);
          }
        },
        child: Text(S.of(menuContext).report),
      )
    ];

    return menu;
  }

  Widget _getListItems(BuildContext context,
      ListProvider<CourseReview> dataProvider, int index, CourseReview review,
      {bool isNested = false}) {
    return CourseReviewWidget(review: review);
  }
}
