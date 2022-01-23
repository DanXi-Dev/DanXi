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
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/opentreehole/floor.dart';
import 'package:dan_xi/model/opentreehole/hole.dart';
import 'package:dan_xi/page/opentreehole/hole_editor.dart';
import 'package:dan_xi/page/subpage_treehole.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/platform_context_menu.dart';
import 'package:dan_xi/widget/libraries/top_controller.dart';
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

/// This function preprocesses content downloaded from FDUHOLE so that
/// (1) HTML href is added to raw links
/// (2) Markdown Images are converted to HTML images.
String preprocessContentForDisplay(String content) {
  String result = "";

  linkify(content, options: const LinkifyOptions(humanize: false))
      .forEach((element) {
    if (element is UrlElement) {
      // Only add tag if tag has not yet been added.
      if (RegExp("\\[.*?\\]\\(${RegExp.escape(element.url)}\\)")
              .hasMatch(content) ||
          RegExp("\\[.*?${RegExp.escape(element.url)}.*?\\]\\(http.*?\\)")
              .hasMatch(content)) {
        result += element.url;
      } else {
        result += "[${element.text}](${element.url})";
      }
    } else {
      result += element.text;
    }
  });

  return result;
}

/// A list page showing the content of a bbs post.
///
/// Arguments:
/// [OTHole] or [Future<List<Reply>>] post: if [post] is BBSPost, show the page as a post.
/// Otherwise as a list of search result.
/// [bool] scroll_to_end: if [scroll_to_end] is true, the page will scroll to the end of
/// the post as soon as the page shows. This implies that [post] should be a [BBSPost].
///
class BBSPostDetail extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const BBSPostDetail({Key? key, this.arguments}) : super(key: key);

  @override
  _BBSPostDetailState createState() => _BBSPostDetailState();
}

class _BBSPostDetailState extends State<BBSPostDetail> {
  /// Unrelated to the state.
  /// These field should only be initialized once when created.
  late OTHole _hole;
  String? _searchKeyword;
  FileImage? _backgroundImage;

  /// Fields related to the display states.
  bool? _isFavored;
  bool shouldUsePreloadedContent = true;

  bool shouldScrollToEnd = false;
  OTFloor? locateFloor;

  final PagedListViewController<OTFloor> _listViewController =
      PagedListViewController<OTFloor>();

  /// Reload/load the (new) content and set the [_content] future.
  Future<List<OTFloor>?> _loadContent(int page) async {
    if (_searchKeyword != null) {
      return OpenTreeHoleRepository.getInstance().loadSearchResults(
          _searchKeyword,
          startFloor: _listViewController.length());
    } else {
      return await OpenTreeHoleRepository.getInstance()
          .loadFloors(_hole, startFloor: page * 10);
    }
  }

  Future<bool?> _isHoleFavorite() async {
    if (_isFavored != null) return _isFavored;
    final List<int>? favorites =
        await (OpenTreeHoleRepository.getInstance().getFavoriteHoleId());
    return favorites!.any((element) {
      return element == _hole.hole_id;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.arguments!.containsKey('post')) {
      _hole = widget.arguments!['post'];
      // Cache preloaded floor only when user views the Hole
      for (var floor
          in _hole.floors?.prefetch ?? List<OTFloor>.empty(growable: false)) {
        OpenTreeHoleRepository.getInstance().cacheFloor(floor);
      }
    } else if (widget.arguments!.containsKey('searchKeyword')) {
      _searchKeyword = widget.arguments!['searchKeyword'];
      // Create a dummy post for displaying search result
      _hole = OTHole.dummy();
    }
    shouldScrollToEnd = widget.arguments!.containsKey('scroll_to_end') &&
        widget.arguments!['scroll_to_end'] == true;
    if (widget.arguments!.containsKey('locate')) {
      locateFloor = widget.arguments!["locate"];
    }
    StateProvider.needScreenshotWarning = true;
  }

  Future<void> scrollDownToFloor(OTFloor floor) async {
    try {
      // Scroll to the corresponding post
      while (!(await _listViewController.scrollToItem(floor))) {
        // Prevent deadlock
        if (_listViewController.isEnded) {
          break;
        }
        await _listViewController.scrollDelta(
            100, const Duration(milliseconds: 1), Curves.linear);
      }
    } catch (_) {}
  }

  /// Rebuild everything and refresh itself.
  Future<void> refreshSelf({scrollToEnd = false}) async {
    //if (scrollToEnd) _listViewController.queueScrollToEnd();
    await _listViewController.notifyUpdate(
        useInitialData: false, queueDataClear: true);
  }

  @override
  void dispose() {
    StateProvider.needScreenshotWarning = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      try {
        // Replaced precached data with updated ones
        _listViewController.replaceInitialData(
            (await OpenTreeHoleRepository.getInstance().loadFloors(_hole))!);
      } catch (_) {}
      if (locateFloor != null) {
        try {
          // Scroll to the specific floor
          await scrollDownToFloor(locateFloor!);
          locateFloor = null;
        } catch (_) {}
      }
    });
    _backgroundImage = SettingsProvider.getInstance().backgroundImage;

    final pagedListView = PagedListView<OTFloor>(
      initialData: _hole.floors?.prefetch,
      pagedController: _listViewController,
      withScrollbar: true,
      scrollController: PrimaryScrollController.of(context),
      dataReceiver: _loadContent,
      shouldScrollToEnd: shouldScrollToEnd,
      builder: _getListItems,
      loadingBuilder: (BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        child: Center(child: PlatformCircularProgressIndicator()),
      ),
      endBuilder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text((_hole.view ?? -1) >= 0
              ? S.of(context).view_count(_hole.view.toString())
              : S.of(context).end_reached),
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
              ? "#${_hole.hole_id}"
              : S.of(context).search_result),
        ),
        trailingActions: [
          if (_searchKeyword == null) ...[
            _buildFavoredActionButton(),
            PlatformIconButton(
              padding: EdgeInsets.zero,
              icon: PlatformX.isMaterial(context)
                  ? const Icon(Icons.reply)
                  : const Icon(CupertinoIcons.arrowshape_turn_up_left),
              onPressed: () async {
                if (await OTEditor.createNewReply(
                    context, _hole.hole_id, null)) {
                  await refreshSelf();
                }
              },
            ),
          ]
        ],
      ),
      body: Builder(
        // The builder widget updates context so that MediaQuery below can use the correct context (that is, Scaffold considered)
        builder: (context) => Material(
          child: Container(
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
                      await refreshSelf();
                    },
                    child: pagedListView,
                  )
                : pagedListView,
          ),
        ),
      ),
    );
  }

  Widget _buildFavoredActionButton() => PlatformIconButton(
        padding: EdgeInsets.zero,
        icon: FutureWidget<bool?>(
          future: _isHoleFavorite(),
          loadingBuilder: PlatformCircularProgressIndicator(),
          successBuilder:
              (BuildContext context, AsyncSnapshot<bool?> snapshot) {
            _isFavored = snapshot.data;
            return _isFavored!
                ? const Icon(CupertinoIcons.star_fill)
                : const Icon(CupertinoIcons.star);
          },
          errorBuilder: () => Icon(
            PlatformIcons(context).error,
            color: Theme.of(context).errorColor,
          ),
        ),
        onPressed: () async {
          if (_isFavored == null) return;
          setState(() => _isFavored = !_isFavored!);
          await OpenTreeHoleRepository.getInstance()
              .setFavorite(
                  _isFavored! ? SetFavoriteMode.ADD : SetFavoriteMode.DELETE,
                  _hole.hole_id)
              .onError((dynamic error, stackTrace) {
            Noticing.showNotice(context, error.toString(),
                title: S.of(context).operation_failed, useSnackBar: false);
            setState(() => _isFavored = !_isFavored!);
            return null;
          });
        },
      );

  List<Widget> _buildContextMenu(BuildContext menuContext, OTFloor e) {
    List<Widget> _buildAdminPenaltyMenu(BuildContext menuContext, OTFloor e) {
      Future<void> onExecutePenalty(int level) async {
        await OpenTreeHoleRepository.getInstance().adminAddPenalty(
            e.floor_id, level, TreeHoleSubpageState.divisionId);
        await refreshSelf();
      }

      return [
        PlatformContextMenuItem(
          onPressed: () => onExecutePenalty(1),
          child: const Text("Level 1: Ban for Day * 1 "),
          menuContext: menuContext,
        ),
        PlatformContextMenuItem(
          onPressed: () => onExecutePenalty(2),
          child: const Text("Level 2: Ban for Day * 5 "),
          menuContext: menuContext,
        ),
        PlatformContextMenuItem(
          onPressed: () => onExecutePenalty(3),
          child: const Text("Level 3: BAN FOREVER"),
          menuContext: menuContext,
          isDestructive: true,
        )
      ];
    }

    List<Widget> menu = [
      if (e.is_me == true && e.deleted == false)
        PlatformContextMenuItem(
          menuContext: menuContext,
          onPressed: () async {
            await OTEditor.modifyReply(
                menuContext, e.hole_id, e.floor_id, e.content);
            await refreshSelf();
          },
          child: Text(S.of(context).modify),
        ),

      // Standard Operations
      PlatformContextMenuItem(
        menuContext: menuContext,
        onPressed: () => smartNavigatorPush(menuContext, "/text/detail",
            arguments: {"text": e.filteredContent}),
        child: Text(S.of(menuContext).free_select),
      ),
      PlatformContextMenuItem(
          menuContext: menuContext,
          child: Text(S.of(menuContext).copy),
          onPressed: () async {
            await FlutterClipboard.copy(renderText(e.filteredContent!, '', ''));
            if (PlatformX.isMaterial(context)) {
              await Noticing.showNotice(
                  menuContext, S.of(menuContext).copy_success);
            }
          }),
      PlatformContextMenuItem(
        isDestructive: true,
        onPressed: () => OTEditor.reportPost(menuContext, e.floor_id),
        child: Text(S.of(menuContext).report),
      ),
    ];
    if (OpenTreeHoleRepository.getInstance().isAdmin) {
      menu.addAll([
        PlatformContextMenuItem(
          onPressed: () async {
            await OTEditor.modifyReply(
                menuContext, e.hole_id, e.floor_id, e.content);
            await refreshSelf();
          },
          child: const Text("Modify this floor"),
          isDestructive: true,
          menuContext: menuContext,
        ),
        PlatformContextMenuItem(
          onPressed: () async {
            if (await Noticing.showConfirmationDialog(context,
                    "Are you sure to hide this floor? It is hard to undo the operation.",
                    title: "Confirmation") ==
                true) {
              final reason = await Noticing.showInputDialog(
                  context, "Delete Reason (cancel for default)");
              await OpenTreeHoleRepository.getInstance()
                  .adminDeleteFloor(e.floor_id, reason);
              await refreshSelf();
            }
          },
          child: const Text("Delete this floor"),
          isDestructive: true,
          menuContext: menuContext,
        ),
        PlatformContextMenuItem(
          onPressed: () async {
            await showPlatformModalSheet(
                context: context,
                builder: (subMenuContext) => PlatformContextMenu(
                    actions: _buildAdminPenaltyMenu(subMenuContext, e),
                    cancelButton: CupertinoActionSheetAction(
                      child: Text(S.of(subMenuContext).cancel),
                      onPressed: () => Navigator.of(subMenuContext).pop(),
                    )));
          },
          child: const Text("Punish this user"),
          menuContext: menuContext,
        ),
        PlatformContextMenuItem(
          onPressed: () async {
            var pinned = StateProvider.currentDivision!.pinned!
                .map((hole) => hole.hole_id!)
                .toList();
            if (pinned.contains(e.hole_id!)) {
              pinned.remove(e.hole_id!);
            } else {
              pinned.add(e.hole_id!);
            }
            await OpenTreeHoleRepository.getInstance().adminModifyDivision(
                StateProvider.currentDivision!.division_id!,
                null,
                null,
                pinned);
          },
          child: const Text("Pin/Unpin this hole"),
          menuContext: menuContext,
        ),
        PlatformContextMenuItem(
          onPressed: () async {
            final tag = await Noticing.showInputDialog(context, "Special Tag");
            if (tag == null) {
              return; // Note: don't return if tag is empty string, because user may want to clear the special tag with this
            }
            await OpenTreeHoleRepository.getInstance()
                .adminAddSpecialTag(tag, e.floor_id);
          },
          child: const Text("Add Special Tag"),
          menuContext: menuContext,
        ),
      ]);
    }
    return menu;
  }

  Widget _getListItems(BuildContext context, ListProvider<OTFloor> dataProvider,
      int index, OTFloor floor,
      {bool isNested = false}) {
    return OTFloorWidget(
      hasBackgroundImage: _backgroundImage != null,
      floor: floor,
      index: _searchKeyword == null ? index : null,
      isInMention: isNested,
      parentHole: _hole,
      onLongPress: () {
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
          // Set the replyId to null when tapping on the first reply.
          if (_hole.floors!.first_floor!.floor_id != floor.floor_id) {
            replyId = floor.floor_id;
            OpenTreeHoleRepository.getInstance().cacheFloor(floor);
          }
          if (await OTEditor.createNewReply(context, _hole.hole_id, replyId)) {
            await refreshSelf();
          }
        } else {
          ProgressFuture progressDialog = showProgressDialog(
              loadingText: S.of(context).loading, context: context);
          smartNavigatorPush(context, "/bbs/postDetail", arguments: {
            "post": await OpenTreeHoleRepository.getInstance()
                .loadSpecificHole(floor.hole_id!),
            "locate": floor
          });
          progressDialog.dismiss(showAnim: false);
        }
      },
    );
  }
}

StatelessWidget smartRender(
    BuildContext context,
    String content,
    LinkTapCallback? onTapLink,
    ImageTapCallback? onTapImage,
    bool translucentCard,
    {bool preview = false}) {
  try {
    return PostRenderWidget(
      render: kMarkdownRender,
      content: preprocessContentForDisplay(content),
      onTapImage: onTapImage,
      onTapLink: onTapLink,
      hasBackgroundImage: translucentCard,
      isPreviewWidget: preview,
    );
  } catch (e) {
    return Text(S.of(context).parse_fatal_error);
  }
}
