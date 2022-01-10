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
import 'package:dan_xi/page/subpage_treehole.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/top_controller.dart';
import 'package:dan_xi/widget/opentreehole/bbs_editor.dart';
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
import 'package:screen_capture_event/screen_capture_event.dart';

/// This function preprocesses content downloaded from FDUHOLE so that
/// (1) HTML href is added to raw links
/// (2) Markdown Images are converted to HTML images.
String preprocessContentForDisplay(String content,
    {bool forceMarkdown = false}) {
  String result = "";
  int hrefCount = 0;

  /* Workaround Markdown images
  content = content.replaceAllMapped(RegExp(r"!\[\]\((https://.*?)\)"),
      (match) => "<img src=\"${match.group(1)}\"></img>");*/
  if (isHtml(content) && !forceMarkdown) {
    linkify(content, options: LinkifyOptions(humanize: false))
        .forEach((element) {
      if (element is UrlElement) {
        // Only add tag if tag has not yet been added.
        if (hrefCount == 0) {
          result += "<a href=\"" + element.url + "\">" + element.text + "</a>";
        } else {
          result += element.text;
          hrefCount--;
        }
      } else {
        if (element.text.contains('<a href='))
          hrefCount++;
        else if (element.text.contains('<img src="')) hrefCount++;
        result += element.text;
      }
    });
  } else {
    linkify(content, options: LinkifyOptions(humanize: false))
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
      } else
        result += element.text;
    });
  }
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

  const BBSPostDetail({Key? key, this.arguments});

  @override
  _BBSPostDetailState createState() => _BBSPostDetailState();
}

class _BBSPostDetailState extends State<BBSPostDetail> {
  /// Unrelated to the state.
  /// These field should only be initialized once when created.
  late OTHole _post;
  String? _searchKeyword;

  final ScreenCaptureEvent screenListener = ScreenCaptureEvent();

  /// Fields related to the display states.
  bool? _isFavored;
  bool shouldUsePreloadedContent = true;

  bool shouldScrollToEnd = false;

  final TimeBasedLoadAdaptLayer<OTFloor> adaptLayer =
      new TimeBasedLoadAdaptLayer(10, 1);

  final PagedListViewController<OTFloor> _listViewController =
      PagedListViewController<OTFloor>();

  /// Reload/load the (new) content and set the [_content] future.
  Future<List<OTFloor>?> _loadContent(int page) async {
    if (_searchKeyword != null) {
      return OpenTreeHoleRepository.getInstance().loadSearchResults(
          _searchKeyword,
          start_floor: _listViewController.length());
    } else
      return await OpenTreeHoleRepository.getInstance()
          .loadFloors(_post, startFloor: page * 10);
  }

  Future<bool?> _isHoleFavorite() async {
    if (_isFavored != null) return _isFavored;
    final List<int>? favorites =
        await (OpenTreeHoleRepository.getInstance().getFavoriteHoleId());
    return favorites!.any((element) {
      return element == _post.hole_id;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.arguments!.containsKey('post')) {
      _post = widget.arguments!['post'];
    } else if (widget.arguments!.containsKey('searchKeyword')) {
      _searchKeyword = widget.arguments!['searchKeyword'];
      // Create a dummy post for displaying search result
      _post = OTHole.dummy();
    }
    shouldScrollToEnd = widget.arguments!.containsKey('scroll_to_end') &&
        widget.arguments!['scroll_to_end'] == true;

    screenListener.addScreenRecordListener((recorded) {
      Noticing.showScreenshotWarning(context);
    });
    screenListener.addScreenShotListener((filePath) {
      Noticing.showScreenshotWarning(context);
    });
    screenListener.watch();
  }

  @override
  void dispose() {
    screenListener.dispose();
    super.dispose();
  }

  /// Rebuild everything and refresh itself.
  Future<void> refreshSelf({scrollToEnd = false}) async {
    //if (scrollToEnd) _listViewController.queueScrollToEnd();
    await _listViewController.notifyUpdate(useInitialData: false);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      // Replaced precached data with updated ones
      OpenTreeHoleRepository.getInstance().loadFloors(_post).then((value) {
        _listViewController.replaceDataInRangeWith(value, 0);
      }, onError: (error, st) {});
    });
    return PlatformScaffold(
      material: (_, __) =>
          MaterialScaffoldData(resizeToAvoidBottomInset: false),
      cupertino: (_, __) =>
          CupertinoPageScaffoldData(resizeToAvoidBottomInset: false),
      iosContentPadding: false,
      iosContentBottomPadding: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
        title: TopController(
          controller: PrimaryScrollController.of(context),
          child: Text(_searchKeyword == null
              ? "#${_post.hole_id}"
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
                if (await BBSEditor.createNewReply(
                    context, _post.hole_id, null)) {
                  await refreshSelf();
                }
              },
            ),
          ]
        ],
      ),
      body: Material(
        child: Container(
          // decoration: BoxDecoration(
          //   image: DecorationImage(
          //     image: AssetImage("assets/graphics/kavinzhao.jpeg"),
          //     fit: BoxFit.cover,
          //   ),
          // ),
          child: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: Theme.of(context).colorScheme.secondary,
              backgroundColor: Theme.of(context).dialogBackgroundColor,
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                await refreshSelf();
              },
              child: PagedListView<OTFloor>(
                initialData: _post.floors?.prefetch,
                pagedController: _listViewController,
                withScrollbar: true,
                scrollController: PrimaryScrollController.of(context),
                dataReceiver: _loadContent,
                shouldScrollToEnd: shouldScrollToEnd,
                builder: _getListItems,
                loadingBuilder: (BuildContext context) => Container(
                  padding: EdgeInsets.all(8),
                  child: Center(child: PlatformCircularProgressIndicator()),
                ),
                endBuilder: (context) => Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(S.of(context).end_reached),
                  ),
                ),
              ),
            ),
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
                ? Icon(CupertinoIcons.star_fill)
                : Icon(CupertinoIcons.star);
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
                  _post.hole_id)
              .onError((dynamic error, stackTrace) {
            Noticing.showNotice(context, error.toString(),
                title: S.of(context).operation_failed, useSnackBar: false);
            setState(() => _isFavored = !_isFavored!);
            return null;
          });
        },
      );

  List<Widget> _buildContextMenu(BuildContext menuContext, OTFloor e) => [
        PlatformWidget(
          cupertino: (_, __) => CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(menuContext).pop();
              BBSEditor.modifyReply(
                  menuContext, e.hole_id, e.floor_id, e.content);
            },
            child: Text(S.of(context).modify),
          ),
          material: (_, __) => ListTile(
            title: Text(S.of(context).modify),
            onTap: () {
              Navigator.of(menuContext).pop();
              BBSEditor.modifyReply(
                  menuContext, e.hole_id, e.floor_id, e.content);
            },
          ),
        ),

        // Standard Operations
        if (!isHtml(e.filteredContent!))
          PlatformWidget(
            cupertino: (_, __) => CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(menuContext).pop();
                smartNavigatorPush(menuContext, "/text/detail",
                    arguments: {"text": e.filteredContent});
              },
              child: Text(S.of(menuContext).free_select),
            ),
            material: (_, __) => ListTile(
              title: Text(S.of(menuContext).free_select),
              onTap: () {
                Navigator.of(menuContext).pop();
                smartNavigatorPush(menuContext, "/text/detail",
                    arguments: {"text": e.filteredContent});
              },
            ),
          ),
        PlatformWidget(
          cupertino: (_, __) => CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(menuContext).pop();
              FlutterClipboard.copy(renderText(e.filteredContent!, '', ''));
            },
            child: Text(S.of(menuContext).copy),
          ),
          material: (_, __) => ListTile(
            title: Text(S.of(menuContext).copy),
            onTap: () {
              Navigator.of(menuContext).pop();
              FlutterClipboard.copy(renderText(e.filteredContent!, '', ''))
                  .then((value) => Noticing.showNotice(
                      menuContext, S.of(menuContext).copy_success));
            },
          ),
        ),
        PlatformWidget(
          cupertino: (_, __) => CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(menuContext).pop();
              BBSEditor.reportPost(menuContext, e.floor_id);
            },
            child: Text(S.of(menuContext).report),
          ),
          material: (_, __) => ListTile(
            title: Text(S.of(menuContext).report),
            onTap: () {
              Navigator.of(menuContext).pop();
              BBSEditor.reportPost(menuContext, e.floor_id);
            },
          ),
        ),
      ];

  Widget _getListItems(BuildContext context, ListProvider<OTFloor> dataProvider,
      int index, OTFloor floor,
      {bool isNested = false}) {
    return OTFloorWidget(
      floor: floor,
      index: index,
      isInMention: isNested,
      parentHole: _post,
      onLongPress: () {
        showPlatformModalSheet(
            context: context,
            // IMPORTANT:
            // This BuildContext below is exclusive to this builder and must be passed
            // to its children. Otherwise, context of bbs_post will be used, which
            // will result in incorrect Navigator.pop() behavior.
            builder: (BuildContext context) => PlatformWidget(
                cupertino: (_, __) => CupertinoActionSheet(
                      actions: _buildContextMenu(context, floor),
                      cancelButton: CupertinoActionSheetAction(
                        child: Text(S.of(context).cancel),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                material: (_, __) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _buildContextMenu(context, floor),
                    )));
      },
      onTap: () async {
        if (_searchKeyword == null) {
          int? replyId;
          // Set the replyId to null when tapping on the first reply.
          if (_post.floors!.first_floor!.floor_id != floor.floor_id) {
            replyId = floor.floor_id;
            OpenTreeHoleRepository.getInstance().cacheFloor(floor);
          }
          if (await BBSEditor.createNewReply(context, _post.hole_id, replyId)) {
            await refreshSelf();
          }
        } else {
          ProgressFuture progressDialog = showProgressDialog(
              loadingText: S.of(context).loading, context: context);
          smartNavigatorPush(context, "/bbs/postDetail", arguments: {
            "post": await OpenTreeHoleRepository.getInstance()
                .loadSpecificHole(floor.hole_id!)
          });
          progressDialog.dismiss();
        }
      },
    );
  }
}

PostRenderWidget smartRender(String content, LinkTapCallback? onTapLink,
        ImageTapCallback? onTapImage) =>
    PostRenderWidget(
      render: kMarkdownRender,
      content: preprocessContentForDisplay(content),
      onTapImage: onTapImage,
      onTapLink: onTapLink,
    );
