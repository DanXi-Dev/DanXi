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
import 'package:dan_xi/model/opentreehole/division.dart';
import 'package:dan_xi/model/opentreehole/floor.dart';
import 'package:dan_xi/model/opentreehole/hole.dart';
import 'package:dan_xi/model/opentreehole/tag.dart';
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

class CourseGroupDetail extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const CourseGroupDetail({Key? key, this.arguments}) : super(key: key);

  @override
  CourseGroupDetailState createState() => CourseGroupDetailState();
}

class CourseGroupDetailState extends State<CourseGroupDetail> {
  /// Unrelated to the state.
  /// These fields should only be initialized once when created.
  late CourseGroup _course;
  String? _searchKeyword;
  FileImage? _backgroundImage;

  /// Fields related to the display states.
  bool shouldScrollToEnd = false;

  final PagedListViewController<OTFloor> _listViewController =
      PagedListViewController<OTFloor>();

  /*
  bool get hasPrefetchedAllData =>
      shouldScrollToEnd ||
          (_course.floors?.prefetch?.length ?? -1) > Constant.POST_COUNT_PER_PAGE;

   */

  /// Reload/load the (new) content and set the [_content] future.
  Future<List<OTFloor>?> _loadContent(int page) async {
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
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.arguments!.containsKey('group')) {
      _course = widget.arguments!['group'];
      /*
      // Cache preloaded floor only when user views the Hole
      for (var floor
      in _course.floors?.prefetch ?? List<OTFloor>.empty(growable: false)) {
        OpenTreeHoleRepository.getInstance().cacheFloor(floor);
      }

       */
    }
    shouldScrollToEnd = widget.arguments!.containsKey('scroll_to_end') &&
        widget.arguments!['scroll_to_end'] == true;

    StateProvider.needScreenshotWarning = true;
  }

  /// Refresh the list view.
  ///
  /// if [ignorePrefetch] and [hasPrefetchedAllData], it will discard the prefetched data first.
  Future<void> refreshListView(
      {bool scrollToEnd = false, bool ignorePrefetch = true}) async {
    Future<void> realRefresh() async {
      if (scrollToEnd) _listViewController.queueScrollToEnd();
      await _listViewController.notifyUpdate(
          useInitialData: false, queueDataClear: true);
    }

    /*
    if (ignorePrefetch && hasPrefetchedAllData) {
      // Reset variable to make [hasPrefetchedAllData] false
      setState(() {
        shouldScrollToEnd = false;
        _course.floors?.prefetch =
            _course.floors?.prefetch?.take(Constant.POST_COUNT_PER_PAGE).toList();
      });

      // Wait build() complete (so `allDataReceiver` has been set to `null`), then trigger a refresh in
      // the list view.
      Completer<void> completer = Completer();
      WidgetsBinding.instance.addPostFrameCallback((_) => realRefresh()
          .then(completer.complete, onError: completer.completeError));
      return completer.future;
    }

     */
    return realRefresh();
  }

  @override
  void dispose() {
    StateProvider.needScreenshotWarning = false;
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
    Future<List<OTFloor>>? allDataReceiver;
    final pagedListView = PagedListView<OTFloor>(
      initialData: [],
      pagedController: _listViewController,
      noneItem: OTFloor.dummy(),
      withScrollbar: true,
      scrollController: PrimaryScrollController.of(context),
      dataReceiver: _loadContent,
      // If we need to scroll to the end, we should prefetch all the data beforehand.
      // See also [prefetchAllFloors] in [TreeHoleSubpageState].
      allDataReceiver: allDataReceiver,
      shouldScrollToEnd: shouldScrollToEnd,
      builder: _getListItems,
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

    return PlatformScaffold(
      iosContentPadding: false,
      iosContentBottomPadding: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
        title: TopController(
          controller: PrimaryScrollController.of(context),
          child: Text(_searchKeyword == null
              ? "#${_course.code}"
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
      body: Builder(
        // The builder widget updates context so that MediaQuery below can use the correct context (that is, Scaffold considered)
        builder: (context) => Container(
          decoration: _backgroundImage == null
              ? null
              : BoxDecoration(
                  image: DecorationImage(
                      image: _backgroundImage!, fit: BoxFit.cover)),
          child: _searchKeyword == null
              ? RefreshIndicator(
                  edgeOffset: MediaQuery.of(context).padding.top,
                  color: Theme.of(context).colorScheme.secondary,
                  backgroundColor: Theme.of(context).dialogBackgroundColor,
                  onRefresh: () async {
                    HapticFeedback.mediumImpact();
                    await refreshListView();
                  },
                  child: pagedListView,
                )
              : pagedListView,
        ),
      ),
    );
  }

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
    List<Widget> buildAdminPenaltyMenu(BuildContext menuContext, OTFloor e) {
      Future<void> onExecutePenalty(int level) async {
        // Confirm the operation
        bool? confirmed = await Noticing.showConfirmationDialog(context,
            "You are going to add a penalty of level $level to floor ${e.floor_id} in its division. Are you sure?",
            isConfirmDestructive: true);
        if (confirmed != true) return;

        int? result = await OpenTreeHoleRepository.getInstance()
            .adminAddPenalty(e.floor_id, level);
        if (result != null && result < 300 && mounted) {
          Noticing.showMaterialNotice(
              context, S.of(context).operation_successful);
        }
      }

      Future<void> onExecutePenaltyDays() async {
        // Input the number of days
        String? dayStr = await Noticing.showInputDialog(
            context, "Please input the number of days");
        if (dayStr == null) return;
        int? days = int.tryParse(dayStr);
        if (days == null) return;

        // Confirm the operation
        bool? confirmed = await Noticing.showConfirmationDialog(context,
            "You are going to add a penalty of $days days to floor ${e.floor_id} in its division. Are you sure?",
            isConfirmDestructive: true);
        if (confirmed != true) return;

        int? result = await OpenTreeHoleRepository.getInstance()
            .adminAddPenaltyDays(e.floor_id, days);
        if (result != null && result < 300 && mounted) {
          Noticing.showMaterialNotice(
              context, S.of(context).operation_successful);
        }
      }

      return [
        PlatformContextMenuItem(
          onPressed: () => onExecutePenalty(1),
          menuContext: menuContext,
          child: Text(S.of(context).level(1)),
        ),
        PlatformContextMenuItem(
          onPressed: () => onExecutePenalty(2),
          menuContext: menuContext,
          child: Text(S.of(context).level(2)),
        ),
        PlatformContextMenuItem(
          onPressed: () => onExecutePenalty(3),
          menuContext: menuContext,
          isDestructive: true,
          child: Text(S.of(context).level(3)),
        ),
        PlatformContextMenuItem(
          onPressed: onExecutePenaltyDays,
          menuContext: menuContext,
          isDestructive: true,
          child: const Text("Custom penalty..."),
        ),
      ];
    }

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

  Widget _getListItems(BuildContext context, ListProvider<OTFloor> dataProvider,
      int index, OTFloor floor,
      {bool isNested = false}) {
    Future<List<ImageUrlInfo>?> loadPageImage(
        BuildContext pageContext, int pageIndex) async {
      List<OTFloor>? result;
      result = [];
      if (result == null || result.isEmpty) {
        return null;
      } else {
        List<ImageUrlInfo> imageList = [];
        for (var floor in result) {
          if (floor.content == null) continue;
          imageList.addAll(extractAllImagesInFloor(floor.content!));
        }
        return imageList;
      }
    }

    return OTFloorWidget(
      hasBackgroundImage: _backgroundImage != null,
      floor: floor,
      index: _searchKeyword == null ? index : null,
      isInMention: isNested,
      parentHole: null,
      onLongPress: () async {
        showPlatformModalSheet(
            context: context,
            builder: (BuildContext context) => PlatformContextMenu(
                actions: _buildContextMenu(context, floor),
                cancelButton: CupertinoActionSheetAction(
                  child: Text(S.of(context).cancel),
                  onPressed: () => Navigator.of(context).pop(),
                )));
      },
      onTap: () async {
        if (_searchKeyword == null) {
          int? replyId;
          if (await OTEditor.createNewReply(context, _course.id, replyId)) {
            await refreshListView(scrollToEnd: true);
          }
        } else {
          // fixme: duplicate of [OTFloorMentionWidget.showFloorDetail].
          ProgressFuture progressDialog = showProgressDialog(
              loadingText: S.of(context).loading, context: context);
          try {
            OTHole? hole = await OpenTreeHoleRepository.getInstance()
                .loadSpecificHole(floor.hole_id!);
            if (mounted) {
              smartNavigatorPush(context, "/bbs/postDetail", arguments: {
                "post": await prefetchAllFloors(hole!),
                "locate": floor
              });
            }
          } catch (e, st) {
            Noticing.showErrorDialog(context, e, trace: st);
          } finally {
            progressDialog.dismiss(showAnim: false);
          }
        }
      },
      onTapImage: (String? url, Object heroTag) {
        final int length = _listViewController.length();
        smartNavigatorPush(context, '/image/detail', arguments: {
          'preview_url': url,
          'hd_url': OpenTreeHoleRepository.getInstance()
              .extractHighDefinitionImageUrl(url!),
          'hero_tag': heroTag,
          'image_list': extractAllImages(),
          'loader': loadPageImage,
          'last_page': length % Constant.POST_COUNT_PER_PAGE == 0
              ? (length ~/ Constant.POST_COUNT_PER_PAGE - 1)
              : length ~/ Constant.POST_COUNT_PER_PAGE
        });
      },
    );
  }

  Iterable<ImageUrlInfo> extractAllImagesInFloor(String content) {
    final imageExp = RegExp(r'!\[.*?\]\((.*?)\)');
    return imageExp.allMatches(content).map((e) => ImageUrlInfo(
        e.group(1),
        OpenTreeHoleRepository.getInstance()
            .extractHighDefinitionImageUrl(e.group(1)!)));
  }

  List<ImageUrlInfo> extractAllImages() {
    List<ImageUrlInfo> imageList = [];
    final int length = _listViewController.length();
    for (int i = 0; i < length; i++) {
      var floor = _listViewController.getElementAt(i);
      if (floor.content == null) continue;
      imageList.addAll(extractAllImagesInFloor(floor.content!));
    }
    return imageList;
  }
}
