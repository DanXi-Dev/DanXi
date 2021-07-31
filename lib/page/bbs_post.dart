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
import 'package:dan_xi/model/post.dart';
import 'package:dan_xi/model/reply.dart';
import 'package:dan_xi/page/subpage_bbs.dart';
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
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:flutter_progress_dialog/src/progress_dialog.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:linkify/linkify.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final Map<String, dynamic> arguments;

  const BBSPostDetail({Key key, this.arguments});

  @override
  _BBSPostDetailState createState() => _BBSPostDetailState();
}

class _BBSPostDetailState extends State<BBSPostDetail> {
  /// Unrelated to the state.
  /// These field should only be initialized once when created.
  BBSPost _post;
  String _searchKeyword;
  SharedPreferences _preferences;

  /// Fields related to the display states.
  bool _isFavored;
  bool shouldUsePreloadedContent = true;

  bool shouldScrollToEnd = false;

  final PagedListViewController _listViewController = PagedListViewController();

  /// Reload/load the (new) content and set the [_content] future.
  Future<List<Reply>> _loadContent(int page) {
    if (_searchKeyword != null)
      return PostRepository.getInstance()
          .loadSearchResults(_searchKeyword, page);
    else
      return PostRepository.getInstance().loadReplies(_post, page);
  }

  Future<bool> _isDiscussionFavored() async {
    if (_isFavored != null) return _isFavored;
    final List<BBSPost> favorites =
        await PostRepository.getInstance().getFavoredDiscussions();
    return favorites.any((element) => element.id == _post.id);
  }

  @override
  void initState() {
    super.initState();
    if (widget.arguments.containsKey('post')) {
      _post = widget.arguments['post'];
    } else if (widget.arguments.containsKey('searchKeyword')) {
      _searchKeyword = widget.arguments['searchKeyword'];
      // Create a dummy post for displaying search result
      _post = BBSPost.dummy();
    }
    shouldScrollToEnd = widget.arguments.containsKey('scroll_to_end') &&
        widget.arguments['scroll_to_end'] == true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getSharedPreferences();
  }

  _getSharedPreferences() async {
    _preferences = await SharedPreferences.getInstance();
  }

  /// Rebuild everything and refresh itself.
  void refreshSelf() {
    _listViewController.notifyUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      material: (_, __) =>
          MaterialScaffoldData(resizeToAvoidBottomInset: false),
      cupertino: (_, __) =>
          CupertinoPageScaffoldData(resizeToAvoidBottomInset: false),
      iosContentPadding: false,
      iosContentBottomPadding: true,
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
                  : const Icon(SFSymbols.arrowshape_turn_up_left),
              onPressed: () {
                BBSEditor.createNewReply(context, _post.id, null)
                    .then((_) => refreshSelf());
              },
            ),
        ],
      ),
      body: RefreshIndicator(
          color: Theme.of(context).accentColor,
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            refreshSelf();
          },
          child: Material(
              child: PagedListView<Reply>(
            initialData: _post?.posts ?? [],
            startPage: 1,
            pagedController: _listViewController,
            withScrollbar: true,
            scrollController: PrimaryScrollController.of(context),
            dataReceiver: _loadContent,
            // Load all data if user instructed us to scroll to end
            allDataReceiver: (shouldScrollToEnd && _post.count > 10)
                ? PostRepository.getInstance().loadReplies(_post, -1)
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
            errorBuilder: _buildErrorWidget,
          ) /*FutureWidget<List<Reply>>(
                  future: _content,
                  loadingBuilder: (BuildContext context,
                      AsyncSnapshot<List<Reply>> snapshot) {
                    _isRefreshing = true;
                    // If there is no data at all, show a full-screen loading indicator.
                    if (_lastSnapshotData == null)
                      return Container(
                        padding: EdgeInsets.all(8),
                        child:
                            Center(child: PlatformCircularProgressIndicator()),
                      );
                    // If the page is showing search results, just show it whatever.
                    if (_searchResult != null) return _buildPage();

                    // Otherwise, showing a list page with loading indicator at the bottom.
                    return NotificationListener<ScrollNotification>(
                        child: _buildPage(), onNotification: onScrollToBottom);
                  },
                  successBuilder: (BuildContext context,
                      AsyncSnapshot<List<Reply>> snapshot) {
                    _isRefreshing = false;
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => scrollToEndIfNeeded());
                    // Prevent showing duplicate replies caused by refreshing repeatedly
                    if (_lastReplies.isEmpty ||
                        snapshot.data.isEmpty ||
                        _lastReplies.last.id != snapshot.data.last.id)
                      _lastReplies.addAll(snapshot.data);
                    _lastSnapshotData = snapshot;
                    if (_searchResult != null) return _buildPage();
                    // Only use scroll notification when data is paged
                    return NotificationListener<ScrollNotification>(
                        child: _buildPage(), onNotification: onScrollToBottom);
                  },
                  errorBuilder: () => _buildErrorWidget(),
                ),*/
              )),
    );
  }

  Widget _buildFavoredActionButton() => PlatformIconButton(
        padding: EdgeInsets.zero,
        icon: FutureWidget<bool>(
          future: _isDiscussionFavored(),
          loadingBuilder: PlatformCircularProgressIndicator(),
          successBuilder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            _isFavored = snapshot.data;
            return _isFavored
                ? Icon(SFSymbols.star_fill)
                : Icon(SFSymbols.star);
          },
          errorBuilder: () => null,
        ),
        onPressed: () async {
          if (_isFavored == null) return;
          setState(() => _isFavored = !_isFavored);
          await PostRepository.getInstance()
              .setFavoredDiscussion(
                  _isFavored
                      ? SetFavoredDiscussionMode.ADD
                      : SetFavoredDiscussionMode.DELETE,
                  _post.id)
              .onError((error, stackTrace) {
            Noticing.showNotice(context, S.of(context).operation_failed);
            setState(() => _isFavored = !_isFavored);
            return null;
          });
        },
      );

  Widget _buildErrorWidget(
          BuildContext context, AsyncSnapshot<List<Reply>> snapshot) =>
      GestureDetector(
        child: Center(
          child: Text(S.of(context).failed),
        ),
        onTap: () {
          refreshSelf();
        },
      );

  List<Widget> _buildContextMenu(Reply e) => [
        if (!isHtml(e.content))
          PlatformWidget(
            cupertino: (_, __) => CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                smartNavigatorPush(context, "/text/detail",
                    arguments: {"text": e.content});
              },
              child: Text(S.of(context).free_select),
            ),
            material: (_, __) => ListTile(
              title: Text(S.of(context).free_select),
              onTap: () {
                Navigator.of(context).pop();
                smartNavigatorPush(context, "/text/detail",
                    arguments: {"text": e.content});
              },
            ),
          ),
        PlatformWidget(
          cupertino: (_, __) => CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              FlutterClipboard.copy(renderText(e.content, ''));
            },
            child: Text(S.of(context).copy),
          ),
          material: (_, __) => ListTile(
            title: Text(S.of(context).copy),
            onTap: () {
              Navigator.of(context).pop();
              FlutterClipboard.copy(renderText(e.content, '')).then((value) =>
                  Noticing.showNotice(context, S.of(context).copy_success));
            },
          ),
        ),
        PlatformWidget(
          cupertino: (_, __) => CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              BBSEditor.reportPost(context, e.id);
            },
            child: Text(S.of(context).report),
          ),
          material: (_, __) => ListTile(
            title: Text(S.of(context).report),
            onTap: () {
              Navigator.of(context).pop();
              BBSEditor.reportPost(context, e.id);
            },
          ),
        ),
      ];

  Widget _opLeadingTag() => Container(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        decoration: BoxDecoration(
            color: Constant.getColorFromString(_post.tag.first.color)
                .withOpacity(0.8),
            borderRadius: BorderRadius.all(Radius.circular(4.0))),
        child: Text(
          "OP",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Constant.getColorFromString(_post.tag.first.color)
                          .withOpacity(0.8)
                          .computeLuminance() <=
                      0.5
                  ? Colors.white
                  : Colors.black,
              fontSize: 12),
        ),
      );

  Widget _getListItems(BuildContext context, ListProvider<Reply> dataProvider,
      int index, Reply e,
      {bool isNested = false}) {
    final bool generateTags = (index == 0);
    LinkTapCallback onLinkTap = (url) {
      BrowserUtil.openUrl(url, context);
    };
    ImageTapCallback onImageTap = (rawImage, url) {
      smartNavigatorPush(context, '/image/detail',
          arguments: {'raw_image': rawImage, 'url': url});
    };
    return GestureDetector(
      onLongPress: () {
        showPlatformModalSheet(
            context: context,
            builder: (_) => PlatformWidget(
                  cupertino: (_, __) => CupertinoActionSheet(
                    actions: _buildContextMenu(e),
                    cancelButton: CupertinoActionSheetAction(
                      child: Text(S.of(context).cancel),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  material: (_, __) => Container(
                    height: 300,
                    child: Column(
                      children: _buildContextMenu(e),
                    ),
                  ),
                ));
      },
      child: Card(
          color: isNested && PlatformX.isCupertino(context)
              ? Theme.of(context).dividerColor.withOpacity(0.05)
              : null,
          child: ListTile(
            dense: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (generateTags)
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: generateTagWidgets(_post, (String tagName) {
                        smartNavigatorPush(context, '/bbs/discussions',
                            arguments: {
                              "tagFilter": tagName,
                              'preferences': _preferences,
                            });
                      })),
                Padding(
                  padding: EdgeInsets.fromLTRB(2, 4, 2, 4),
                  child: Row(
                    children: [
                      if (e.username == _post.first_post.username)
                        _opLeadingTag(),
                      if (e.username == _post.first_post.username)
                        const SizedBox(
                          width: 2,
                        ),
                      Text(
                        "[${e.username}]",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      if (isNested)
                        Center(
                          child: Icon(SFSymbols.search,
                              color:
                                  Theme.of(context).hintColor.withOpacity(0.2),
                              size: 12),
                        ),
                    ],
                  ),
                ),
                if (e.reply_to != null && !isNested && _searchKeyword == null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 4),
                    child:
                        /*Text(
                      S.of(context).reply_to(e.reply_to),
                      textScaleFactor: 0.8,
                      style: TextStyle(
                          color: Constant.getColorFromString(
                              _post.tag.first.color)),
                    ),*/
                        _getListItems(
                            context,
                            dataProvider,
                            -1,
                            dataProvider.getElementFirstWhere(
                                (element) => element.id == e.reply_to,
                                orElse: () => Reply(
                                    -1,
                                    S.of(context).unable_to_find_quote,
                                    S.of(context).fatal_error,
                                    null,
                                    DateTime.now().toIso8601String(),
                                    -1,
                                    null)),
                            isNested: true),
                  ),
                Align(
                    alignment: Alignment.topLeft,
                    child: isNested
                        // If content is being quoted, limit its height so that the view won't be too long.
                        ? Linkify(
                            text: renderText(e.content, S.of(context).image_tag)
                                .trim(),
                            textScaleFactor: 0.8,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            onOpen: (link) async {
                              if (await canLaunch(link.url)) {
                                BrowserUtil.openUrl(link.url, context);
                              } else {
                                Noticing.showNotice(
                                    context, S.of(context).cannot_launch_url);
                              }
                            },
                          )
                        : smartRender(e.content, onLinkTap, onImageTap)),
              ],
            ),
            subtitle: isNested
                ? null
                : Column(children: [
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "#${e.id}",
                            style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontSize: 12),
                          ),
                          Text(
                            HumanDuration.format(
                                context, DateTime.parse(e.date_created)),
                            style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontSize: 12),
                          ),
                          GestureDetector(
                            child: Text(S.of(context).report,
                                style: TextStyle(
                                    color: Theme.of(context).hintColor,
                                    fontSize: 12)),
                            onTap: () {
                              BBSEditor.reportPost(context, e.id);
                            },
                          ),
                        ]),
                  ]),
            onTap: () async {
              if (_searchKeyword == null) {
                if (isNested) {
                  // Scroll to the corrosponding post
                  _listViewController.scrollToItem(e);
                  return;
                }

                int replyId;
                // Set the replyId to null when tapping on the first reply.
                if (_post.first_post.id != e.id) {
                  replyId = e.id;
                }
                BBSEditor.createNewReply(context, _post.id, replyId)
                    .then((value) => refreshSelf());
              } else {
                ProgressFuture progressDialog = showProgressDialog(
                    loadingText: S.of(context).loading, context: context);
                smartNavigatorPush(context, "/bbs/postDetail", arguments: {
                  "post": await PostRepository.getInstance()
                      .loadSpecificPost(e.discussion)
                });
                progressDialog.dismiss();
              }
            },
          )),
    );
  }

  PostRenderWidget smartRender(String content, LinkTapCallback onTapLink,
          ImageTapCallback onTapImage) =>
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
}
