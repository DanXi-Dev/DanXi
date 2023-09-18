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
import 'dart:convert';

import 'package:clipboard/clipboard.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/danke/course.dart';
import 'package:dan_xi/model/danke/course_group.dart';
import 'package:dan_xi/model/danke/course_review.dart';
import 'package:dan_xi/model/opentreehole/division.dart';
import 'package:dan_xi/model/opentreehole/floor.dart';
import 'package:dan_xi/model/opentreehole/hole.dart';
import 'package:dan_xi/model/opentreehole/tag.dart';
import 'package:dan_xi/model/pair.dart';
import 'package:dan_xi/page/opentreehole/hole_editor.dart';
import 'package:dan_xi/page/opentreehole/image_viewer.dart';
import 'package:dan_xi/page/subpage_treehole.dart';
import 'package:dan_xi/provider/fduhole_provider.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/opentreehole/paged_listview_helper.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/widget/danke/course_review_widget.dart';
import 'package:dan_xi/widget/danke/course_widgets.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/platform_context_menu.dart';
import 'package:dan_xi/widget/libraries/top_controller.dart';
import 'package:dan_xi/widget/opentreehole/ottag_selector.dart';
import 'package:dan_xi/widget/opentreehole/post_render.dart';
import 'package:dan_xi/widget/opentreehole/render/base_render.dart';
import 'package:dan_xi/widget/opentreehole/render/render_impl.dart';
import 'package:dan_xi/widget/opentreehole/treehole_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:linkify/linkify.dart';
import 'package:nil/nil.dart';
import 'package:provider/provider.dart';

import '../../model/opentreehole/history.dart';
import '../../util/stream_listener.dart';
import '../../widget/libraries/round_chip.dart';

class RefreshFilterEvent {
  // 0: Teacher filter, 1: Time filter
  final int filterType;
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
  late CourseGroup _courses;
  String? _searchKeyword;
  FileImage? _backgroundImage;
  Set<String> teacherSet = {};
  Set<Pair<int, int>> timeSet = {};

  /// Fields related to the display states.
  bool shouldScrollToEnd = false;

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
  Future<List<CourseReview>?> _loadContent(int page) async {
    /*
    if (_searchKeyword != null) {
      var result = await OpenTreeHoleRepository.getInstance().loadSearchResults(
          _searchKeyword,
          startFloor: _listViewController.length());
      return result;
    } else {
      return await OpenTreeHoleRepository.getInstance()
          .loadFloors(_course, startFloor: page * Constant.POST_COUNT_PER_PAGE);
    }

     */
    List<CourseReview> result = [CourseReview.dummy()];
    for (var elem in _courses.courseList!) {
      result += elem.reviewList!;
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    if (widget.arguments!.containsKey('group')) {
      _courses = widget.arguments!['group'];
      /*
      // Cache preloaded floor only when user views the Hole
      for (var floor
      in _course.floors?.prefetch ?? List<OTFloor>.empty(growable: false)) {
        OpenTreeHoleRepository.getInstance().cacheFloor(floor);
      }

       */

      for (var elem in _courses.courseList!) {
        teacherSet.add(elem.teachers!);
        timeSet.add(Pair(elem.year!, elem.semester!));
      }
    }
    shouldScrollToEnd = widget.arguments!.containsKey('scroll_to_end') &&
        widget.arguments!['scroll_to_end'] == true;

    StateProvider.needScreenshotWarning = true;

    _refreshSubscription.bindOnlyInvalid(
        Constant.eventBus.on<RefreshFilterEvent>().listen((event) {
          setState(() {
            switch (event.filterType) {
              case 0:
                teacherFilter = event.newFilter;
                break;
              case 1:
                timeFilter = event.newFilter;
                break;
            }
          });

          indicatorKey.currentState?.show();
        }),
        hashCode);
  }

  /// Refresh the whole list.
  Future<void> refreshList() async {
    await refreshSelf();
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
          child: Text(_searchKeyword == null
              ? "#${_courses.code}"
              : S.of(context).search_result),
        ),
        trailingActions: [
          if (_searchKeyword == null) ...[
            PlatformIconButton(
              padding: EdgeInsets.zero,
              icon: PlatformX.isMaterial(context)
                  ? const Icon(Icons.reply)
                  : const Icon(CupertinoIcons.arrowshape_turn_up_left),
              onPressed: () async {
                /*
                if (await OTEditor.createNewReply(
                    context, _course.hole_id, null)) {
                  refreshListView(scrollToEnd: true);
                }

                 */
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
    Future<List<CourseReview>>? allDataReceiver;
    final pagedListView = PagedListView<CourseReview>(
      pagedController: _listViewController,
      noneItem: CourseReview.dummy(),
      withScrollbar: true,
      scrollController: PrimaryScrollController.of(context),
      dataReceiver: _loadContent,
      // If we need to scroll to the end, we should prefetch all the data beforehand.
      // See also [prefetchAllFloors] in [TreeHoleSubpageState].
      allDataReceiver: allDataReceiver,
      shouldScrollToEnd: shouldScrollToEnd,
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
          child: pagedListView,
        ),
      ),
    );
  }

  Widget _buildHead(BuildContext context) => Card(
      color: Theme.of(context).cardTheme.color?.withOpacity(0.8),
      child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(_courses.getFullName(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(_courses.code!,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: SizedBox(
                    width: 56,
                    child: OTLeadingTag(
                      color: Colors.orange,
                      text: "${_courses.credit!.toStringAsFixed(1)} 学分",
                    )),
              ),
              const Divider(
                height: 5,
                thickness: 1,
              ),
              Text(S.of(context).course_teacher_name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Wrap(children: [
                    FilterTagWidget(
                        selected: teacherFilter == "*",
                        text: "全部",
                        filter: "*",
                        filterType: 0),
                    ...teacherSet.map((e) => FilterTagWidget(
                        selected: teacherFilter == e,
                        text: e,
                        filter: e,
                        filterType: 0))
                  ])),
              const Divider(
                height: 5,
                thickness: 1,
              ),
              Text(S.of(context).course_schedule,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Wrap(children: [
                    FilterTagWidget(
                      selected: timeFilter == "*",
                      text: "全部",
                      filter: "*",
                      filterType: 1,
                    ),
                    ...timeSet.map((e) {
                      String filter = "${e.first} ${e.second}";
                      return FilterTagWidget(
                        selected: timeFilter == filter,
                        text: "${e.first}学年-${e.second == 1 ? "秋季" : "春季"}",
                        filter: filter,
                        filterType: 1,
                      );
                    })
                  ])),
            ],
          )));

  Future<void> _onTapScrollToEnd(_) async {
    /*
    ProgressFuture dialog = showProgressDialog(
        loadingText: S.of(context).loading, context: context);
    try {
      // If we haven't loaded before, we need to load all floors.
      if (!shouldScrollToEnd) _course = await prefetchAllFloors(_course);

      _listViewController.queueScrollToEnd();
      _listViewController.replaceDataWith((_course.floors?.prefetch)!);
      setState(() {});
      shouldScrollToEnd = true;
    } catch (error, st) {
      Noticing.showErrorDialog(context, error, trace: st);
    } finally {
      dialog.dismiss(showAnim: false);
    }

     */
  }

  List<OTTag> deepCopyTagList(List<OTTag> list) =>
      list.map((e) => OTTag.fromJson(jsonDecode(jsonEncode(e)))).toList();

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
