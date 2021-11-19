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
import 'package:dan_xi/master_detail/master_detail_view.dart';
import 'package:dan_xi/model/opentreehole/floor.dart';
import 'package:dan_xi/model/opentreehole/hole.dart';
import 'package:dan_xi/model/post.dart';
import 'package:dan_xi/page/subpage_bbs.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/human_duration.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/bbs_editor.dart';
import 'package:dan_xi/widget/future_widget.dart';
import 'package:dan_xi/widget/paged_listview.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/post_render.dart';
import 'package:dan_xi/widget/render/base_render.dart';
import 'package:dan_xi/widget/render/render_impl.dart';
import 'package:dan_xi/widget/top_controller.dart';
import 'package:dan_xi/widget/treehole_widgets.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:linkify/linkify.dart';
import 'package:url_launcher/url_launcher.dart';

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
/// [BBSPost] or [Future<List<Reply>>] post: if [post] is BBSPost, show the page as a post.
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
  OTHole? _post;
  String? _searchKeyword;

  /// Fields related to the display states.
  bool? _isFavored;
  bool shouldUsePreloadedContent = true;

  bool shouldScrollToEnd = false;

  final PagedListViewController _listViewController = PagedListViewController();

  /// Reload/load the (new) content and set the [_content] future.
  Future<List<OTFloor>?> _loadContent(int page) async {
    if (_searchKeyword != null)
      return await PostRepository.getInstance()
          .loadSearchResults(_searchKeyword, page);
    else
      return await PostRepository.getInstance()
          .loadReplies(_post!, page * 10, 10);
  }

  Future<bool?> _isDiscussionFavored() async {
    if (_isFavored != null) return _isFavored;
    final List<int>? favorites =
        await (PostRepository.getInstance().getFavoredDiscussions());
    return favorites!.any((element) {
      return element == _post!.hole_id;
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
  }

  /// Rebuild everything and refresh itself.
  Future<void> refreshSelf({scrollToEnd = false}) async {
    //if (scrollToEnd) _listViewController.queueScrollToEnd();
    await _listViewController.notifyUpdate(useInitialData: false);
  }

  @override
  Widget build(BuildContext context) {
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
              ? S.of(context).forum
              : S.of(context).search_result),
        ),
        trailingActions: [
          if (_searchKeyword == null) _buildFavoredActionButton(),
          if (_searchKeyword == null)
            PlatformIconButton(
              padding: EdgeInsets.zero,
              icon: PlatformX.isMaterial(context)
                  ? const Icon(Icons.reply)
                  : const Icon(CupertinoIcons.arrowshape_turn_up_left),
              onPressed: () {
                BBSEditor.createNewReply(context, _post!.hole_id, null)
                    .then((_) => refreshSelf(scrollToEnd: true));
              },
            ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: Theme.of(context).accentColor,
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            await refreshSelf();
          },
          child: Material(
            child: PagedListView<OTFloor>(
              initialData: _post?.floors?.prefetch ?? [],
              pagedController: _listViewController,
              withScrollbar: true,
              scrollController: PrimaryScrollController.of(context),
              dataReceiver: _loadContent,
              // Load all data if user instructed us to scroll to end
              allDataReceiver: (shouldScrollToEnd && _post!.reply! > 10)
                  ? PostRepository.getInstance().loadReplies(_post!, 0, 0)
                  : null,
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
    );
  }

  Widget _buildFavoredActionButton() => PlatformIconButton(
        padding: EdgeInsets.zero,
        icon: FutureWidget<bool?>(
          future: _isDiscussionFavored(),
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
          await PostRepository.getInstance()
              .setFavoredDiscussion(
                  _isFavored!
                      ? SetFavoredDiscussionMode.ADD
                      : SetFavoredDiscussionMode.DELETE,
                  _post!.hole_id)
              .onError((dynamic error, stackTrace) {
            Noticing.showNotice(context, error.toString(),
                title: S.of(context).operation_failed, useSnackBar: false);
            setState(() => _isFavored = !_isFavored!);
            return null;
          });
        },
      );

  List<Widget> _buildContextMenu(BuildContext menuContext, OTFloor e) => [
        // Admin Operations
        if (PostRepository.getInstance().isUserAdminNonAsync())
          PlatformWidget(
            cupertino: (_, __) => CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(menuContext).pop();
                BBSEditor.adminModifyReply(
                    menuContext, e.hole_id, e.floor_id, e.content);
              },
              child: Text("Modify Post"),
            ),
            material: (_, __) => ListTile(
              title: Text("Modify Post"),
              onTap: () {
                Navigator.of(menuContext).pop();
                BBSEditor.adminModifyReply(
                    menuContext, e.hole_id, e.floor_id, e.content);
              },
            ),
          ),
        if (PostRepository.getInstance().isUserAdminNonAsync())
          PlatformWidget(
            cupertino: (_, __) => CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(menuContext).pop();
                PostRepository.getInstance()
                    .adminDisablePost(e.hole_id, e.floor_id)
                    .onError((dynamic error, stackTrace) {
                  if (error is DioError) {
                    Noticing.showNotice(
                        context,
                        error.message +
                            '\n' +
                            (error.response?.data?.toString() ?? ""),
                        title: error.type.toString(),
                        useSnackBar: false);
                  } else
                    Noticing.showNotice(context, error.toString(),
                        title: S.of(menuContext).fatal_error,
                        useSnackBar: false);
                  return -1;
                });
              },
              child: Text("Disable Post"),
            ),
            material: (_, __) => ListTile(
              title: Text("Disable Post"),
              onTap: () {
                Navigator.of(menuContext).pop();
                PostRepository.getInstance()
                    .adminDisablePost(e.hole_id, e.floor_id)
                    .onError((dynamic error, stackTrace) {
                  if (error is DioError) {
                    Noticing.showNotice(
                        context,
                        error.message +
                            '\n' +
                            (error.response?.data?.toString() ?? ""),
                        title: error.type.toString(),
                        useSnackBar: false);
                  } else
                    Noticing.showNotice(context, error.toString(),
                        title: S.of(menuContext).fatal_error,
                        useSnackBar: false);
                  return -1;
                });
              },
            ),
          ),
        if (PostRepository.getInstance().isUserAdminNonAsync())
          PlatformWidget(
            cupertino: (_, __) => CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(menuContext).pop();
                PostRepository.getInstance()
                    .adminDisableDiscussion(e.hole_id)
                    .onError((dynamic error, stackTrace) {
                  if (error is DioError) {
                    Noticing.showNotice(
                        context,
                        error.message +
                            '\n' +
                            (error.response?.data?.toString() ?? ""),
                        title: error.type.toString(),
                        useSnackBar: false);
                  } else
                    Noticing.showNotice(context, error.toString(),
                        title: S.of(menuContext).fatal_error,
                        useSnackBar: false);
                  return -1;
                });
              },
              child: Text("Disable Discussion"),
            ),
            material: (_, __) => ListTile(
              title: Text("Disable Discussion"),
              onTap: () {
                Navigator.of(menuContext).pop();
                PostRepository.getInstance()
                    .adminDisableDiscussion(e.hole_id)
                    .onError((dynamic error, stackTrace) {
                  if (error is DioError) {
                    Noticing.showNotice(
                        context,
                        error.message +
                            '\n' +
                            (error.response?.data?.toString() ?? ""),
                        title: error.type.toString(),
                        useSnackBar: false);
                  } else
                    Noticing.showNotice(context, error.toString(),
                        title: S.of(menuContext).fatal_error,
                        useSnackBar: false);
                  return -1;
                });
              },
            ),
          ),
        if (PostRepository.getInstance().isUserAdminNonAsync())
          PlatformWidget(
            cupertino: (_, __) => CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(menuContext).pop();
                PostRepository.getInstance()
                    .adminGetUser(e.hole_id, e.floor_id)
                    .then((value) => Noticing.showNotice(context, value,
                        useSnackBar: false));
              },
              child: Text("Get Username"),
            ),
            material: (_, __) => ListTile(
              title: Text("Get Username"),
              onTap: () {
                Navigator.of(menuContext).pop();
                PostRepository.getInstance()
                    .adminGetUser(e.hole_id, e.floor_id)
                    .then((value) {
                  Noticing.showNotice(context, value, useSnackBar: false);
                });
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
              FlutterClipboard.copy(renderText(e.filteredContent!, ''));
            },
            child: Text(S.of(menuContext).copy),
          ),
          material: (_, __) => ListTile(
            title: Text(S.of(menuContext).copy),
            onTap: () {
              Navigator.of(menuContext).pop();
              FlutterClipboard.copy(renderText(e.filteredContent!, '')).then(
                  (value) => Noticing.showNotice(
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
    final bool generateTags = (index == 0);
    final LinkTapCallback onLinkTap = (url) {
      BrowserUtil.openUrl(url!, context);
    };
    final ImageTapCallback onImageTap = (url) {
      smartNavigatorPush(context, '/image/detail', arguments: {'url': url});
    };
    return OTFloorWidget(
      floor: floor,
      index: index,
      isNested: isNested,
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
                  ),
                ));
      },
      onTap: () async {
        if (_searchKeyword == null) {
          if (isNested) {
            // Scroll to the corrosponding post
            while (!(await _listViewController.scrollToItem(floor))) {
              if (_listViewController.getScrollController()!.offset < 10)
                break; // Prevent deadlock
              await _listViewController.scrollDelta(
                  -100, Duration(milliseconds: 1), Curves.linear);
            }
            return;
          }

          int? replyId;
          // Set the replyId to null when tapping on the first reply.
          if (_post!.floors!.first_floor!.floor_id != floor.floor_id) {
            replyId = floor.floor_id;
          }
          BBSEditor.createNewReply(context, _post!.hole_id, replyId)
              .then((value) => refreshSelf(scrollToEnd: true));
        } else {
          ProgressFuture progressDialog = showProgressDialog(
              loadingText: S.of(context).loading, context: context);
          smartNavigatorPush(context, "/bbs/postDetail", arguments: {
            "post": await PostRepository.getInstance()
                .loadSpecificDiscussion(floor.hole_id!)
          });
          progressDialog.dismiss();
        }
      },
    );
  }
}

PostRenderWidget smartRender(String content, LinkTapCallback? onTapLink,
        ImageTapCallback? onTapImage) =>
    isHtml(content)
        ? PostRenderWidget(
            render: kHtmlRender,
            content: preprocessContentForDisplay(content),
            onTapImage: onTapImage,
            onTapLink: onTapLink,
          )
        : PostRenderWidget(
            render: kMarkdownRender,
            content: preprocessContentForDisplay(content),
            onTapImage: onTapImage,
            onTapLink: onTapLink,
          );
