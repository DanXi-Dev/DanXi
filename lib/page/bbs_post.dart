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
import 'package:dan_xi/model/post.dart';
import 'package:dan_xi/model/reply.dart';
import 'package:dan_xi/page/image_viewer.dart';
import 'package:dan_xi/page/subpage_bbs.dart';
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/human_duration.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/bbs_editor.dart';
import 'package:dan_xi/widget/future_widget.dart';
import 'package:dan_xi/widget/image_render_x.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:flutter_progress_dialog/src/progress_dialog.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:linkify/linkify.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// This function preprocesses content downloaded from FDUHOLE so that
/// (1) HTML href is added to raw links
/// (2) Markdown Images are converted to HTML images.
String preprocessContentForDisplay(String content) {
  String result = "";
  int hrefCount = 0;

  // Workaround Markdown images
  content = content.replaceAllMapped(RegExp(r"!\[\]\((https://.*?)\)"),
      (match) => "<img src=\"${match.group(1)}\"></img>");

  linkify(content, options: LinkifyOptions(humanize: false)).forEach((element) {
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
  return result;
}

/// A list page showing the content of a bbs post.
///
/// Arguments:
/// [BBSPost] or [Future<List<Reply>>] post: if [post] is BBSPost, show the page as a post.
/// Otherwise as a list of search result.
///
class BBSPostDetail extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const BBSPostDetail({Key key, this.arguments});

  @override
  _BBSPostDetailState createState() => _BBSPostDetailState();
}

class _BBSPostDetailState extends State<BBSPostDetail> {
  BBSPost _post;
  int _currentBBSPage = 1;
  List<Reply> _lastReplies = [];
  AsyncSnapshot _lastSnapshotData;
  bool _isRefreshing = true;
  bool _isEndIndicatorShown = false;
  bool _isFavorited;
  static const POST_COUNT_PER_PAGE = 10;

  bool shouldUsePreloadedContent = true;

  Future<List<Reply>> _searchResult;
  SharedPreferences _preferences;

  Future<List<Reply>> _content;

  void _setContent() {
    if (_searchResult != null)
      _content = _searchResult;
    else if (_currentBBSPage == 1 && shouldUsePreloadedContent)
      _content = Future.value((widget.arguments['post'] as BBSPost).posts);
    else
      _content =
          PostRepository.getInstance().loadReplies(_post, _currentBBSPage);
  }

  Future<bool> _isDiscussionFavorited() async {
    if (_isFavorited != null) return _isFavorited;
    final List<BBSPost> favorites =
        await PostRepository.getInstance().getFavoredDiscussions();
    return favorites.any((element) => element.id == _post.id);
  }

  @override
  void initState() {
    super.initState();

    if (widget.arguments['post'] is BBSPost) {
      _post = widget.arguments['post'];
    } else {
      _searchResult = widget.arguments['post'];
      // Create a dummy post for displaying search result
      _post = new BBSPost(
          -1,
          new Reply(-1, "", "", null, "", -1, false),
          -1,
          null,
          null,
          false,
          "",
          "",
          [new Reply(-1, "", "", null, "", -1, false)]);
    }
  }

  @override
  void didChangeDependencies() async {
    _setContent();
    super.didChangeDependencies();
    _getSharedPreferences();
  }

  _getSharedPreferences() async {
    _preferences = await SharedPreferences.getInstance();
  }

  /// Rebuild everything on refreshing.
  void refreshSelf() {
    if (mounted) {
      setState(() {
        _currentBBSPage = 1;
        _lastReplies = [];
        _lastSnapshotData = null;
        _isRefreshing = true;
        _isEndIndicatorShown = false;
        shouldUsePreloadedContent = false;
        _setContent();
      });
    }
  }

  @override
  void didUpdateWidget(covariant BBSPostDetail oldWidget) {
    _setContent();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    // A listener to a scroll view, loading new content when scroll to the bottom.
    NotificationListenerCallback<ScrollNotification> onScrollToBottom =
        (ScrollNotification scrollInfo) {
      if (scrollInfo.metrics.extentAfter < 500 &&
          !_isRefreshing &&
          !_isEndIndicatorShown) {
        _isRefreshing = true;
        setState(() {
          _currentBBSPage++;
          _setContent();
        });
      }
      return false;
    };

    return PlatformScaffold(
      iosContentPadding: true,
      iosContentBottomPadding: true,
      appBar: PlatformAppBarX(
        title: Text(_searchResult == null
            ? S.of(context).forum
            : S.of(context).search_result),
        trailingActions: [
          if (_searchResult == null)
            PlatformIconButton(
              padding: EdgeInsets.zero,
              icon: FutureWidget<bool>(
                future: _isDiscussionFavorited(),
                loadingBuilder: PlatformCircularProgressIndicator(),
                successBuilder:
                    (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  _isFavorited = snapshot.data;
                  return _isFavorited
                      ? Icon(SFSymbols.star_fill)
                      : Icon(SFSymbols.star);
                },
                errorBuilder: () => null,
              ),
              onPressed: () async {
                if (_isFavorited == null) return;
                setState(() => _isFavorited = !_isFavorited);
                await PostRepository.getInstance()
                    .setFavoredDiscussion(
                        _isFavorited
                            ? SetFavoredDiscussionMode.ADD
                            : SetFavoredDiscussionMode.DELETE,
                        _post.id)
                    .onError((error, stackTrace) {
                  Noticing.showNotice(context, S.of(context).operation_failed);
                  setState(() => _isFavorited = !_isFavorited);
                  return null;
                });
              },
            ),
          if (_searchResult == null)
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
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            refreshSelf();
          },
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: FutureWidget<List<Reply>>(
              future: _content,
              loadingBuilder:
                  (BuildContext context, AsyncSnapshot<List<Reply>> snapshot) {
                _isRefreshing = true;
                // If there is no data at all, show a full-screen loading indicator.
                if (_lastSnapshotData == null)
                  return Container(
                    padding: EdgeInsets.all(8),
                    child: Center(child: PlatformCircularProgressIndicator()),
                  );
                // If the page is showing search results, just show it whatever.
                if (_searchResult != null)
                  return _buildPage(_lastSnapshotData.data, true);

                // Otherwise, showing a list page with loading indicator at the bottom.
                return NotificationListener<ScrollNotification>(
                    child: _buildPage(snapshot.data, true),
                    onNotification: onScrollToBottom);
              },
              successBuilder:
                  (BuildContext context, AsyncSnapshot<List<Reply>> snapshot) {
                _isRefreshing = false;
                // Prevent showing duplicate replies caused by refreshing repeatedly
                if (_lastReplies.isEmpty ||
                    snapshot.data.isEmpty ||
                    _lastReplies.last.id != snapshot.data.last.id)
                  _lastReplies.addAll(snapshot.data);
                _lastSnapshotData = snapshot;
                if (_searchResult != null)
                  return _buildPage(snapshot.data, false);
                // Only use scroll notification when data is paged
                return NotificationListener<ScrollNotification>(
                    child: _buildPage(snapshot.data, false),
                    onNotification: onScrollToBottom);
              },
              errorBuilder: () => _buildErrorWidget(),
            ),
          )),
    );
  }

  Widget _buildPage(List<Reply> data, bool isLoading) => WithScrollbar(
        child: ListView.builder(
          primary: true,
          physics: const AlwaysScrollableScrollPhysics(),
          cacheExtent: 2000,
          itemCount: (_currentBBSPage) * POST_COUNT_PER_PAGE +
              (isLoading ? 1 - POST_COUNT_PER_PAGE : 0),
          itemBuilder: (context, index) => _buildListItem(index, data, true),
        ),
        controller: PrimaryScrollController.of(context),
      );

  Widget _buildListItem(int index, List<Reply> e, bool isNewData) {
    if (isNewData &&
        index >= _lastReplies.length &&
        !_isEndIndicatorShown &&
        !_isRefreshing) {
      _isEndIndicatorShown = true;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(S.of(context).end_reached),
          const SizedBox(
            height: 16,
          )
        ],
      );
    }
    if (index >= _lastReplies.length)
      return _isEndIndicatorShown
          ? Container()
          : Center(child: PlatformCircularProgressIndicator());
    return _wrapListItemInCanvas(_lastReplies[index], index == 0);
  }

  Widget _buildErrorWidget() => GestureDetector(
        child: Center(
          child: Text(S.of(context).failed),
        ),
        onTap: () {
          refreshSelf();
        },
      );

  List<Widget> _buildContextMenu(Reply e) {
    return [
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
  }

  Widget _wrapListItemInCanvas(Reply e, bool generateTags) =>
      Material(child: _getListItems(e, generateTags, false));

  Widget _OPLeadingTag() => Container(
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

  Widget _getListItems(Reply e, bool generateTags, bool isNested) {
    OnTap onLinkTap = (url, _, __, ___) {
      if (ImageViewerPage.isImage(url)) {
        Navigator.of(context)
            .pushNamed('/image/detail', arguments: {'url': url});
      } else {
        BrowserUtil.openUrl(url);
      }
    };
    double imageWidth = MediaQuery.of(context).size.width / 2;
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
          color:
              isNested ? Theme.of(context).bannerTheme.backgroundColor : null,
          child: ListTile(
            dense: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (generateTags)
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: generateTagWidgets(_post, (String tagname) {
                        Navigator.of(context)
                            .pushNamed('/bbs/discussions', arguments: {
                          "tagFilter": tagname,
                          'preferences': _preferences,
                        });
                      })),
                Padding(
                  padding: EdgeInsets.fromLTRB(2, 4, 2, 4),
                  child: Row(
                    children: [
                      if (e.username == _post.first_post.username)
                        _OPLeadingTag(),
                      if (e.username == _post.first_post.username)
                        const SizedBox(
                          width: 2,
                        ),
                      Text(
                        "[${e.username}]",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (e.reply_to != null && !isNested && _searchResult == null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 4),
                    child: _getListItems(
                        _lastReplies.firstWhere(
                          (element) => element.id == e.reply_to,
                        ),
                        false,
                        true),
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
                              BrowserUtil.openUrl(link.url);
                            } else {
                              Noticing.showNotice(
                                  context, S.of(context).cannot_launch_url);
                            }
                          },
                        )
                      : Container(
                          //constraints: BoxConstraints(maxHeight: 400),
                          child: Html(
                            shrinkWrap: true,
                            data: preprocessContentForDisplay(e.content),
                            style: {
                              "body": Style(
                                margin: EdgeInsets.zero,
                                padding: EdgeInsets.zero,
                                fontSize: FontSize(16),
                              ),
                              "p": Style(
                                margin: EdgeInsets.zero,
                                padding: EdgeInsets.zero,
                                fontSize: FontSize(16),
                              ),
                            },
                            customImageRenders: {
                              networkSourceMatcher(): networkImageClipRender(
                                  loadingWidget: () => Center(
                                        child: Container(
                                          padding:
                                              EdgeInsets.symmetric(vertical: 4),
                                          foregroundDecoration: BoxDecoration(
                                              color: Colors.black12),
                                          width: imageWidth,
                                          height: imageWidth,
                                          child: Center(
                                            child:
                                                PlatformCircularProgressIndicator(),
                                          ),
                                        ),
                                      ),
                                  maxHeight: imageWidth),
                            },
                            onLinkTap: onLinkTap,
                            onImageTap: onLinkTap,
                          ),
                        ),
                ),
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
              if (_searchResult == null)
                BBSEditor.createNewReply(context, _post.id, e.id)
                    .then((value) => refreshSelf());
              else {
                ProgressFuture progressDialog = showProgressDialog(
                    loadingText: S.of(context).loading, context: context);
                Navigator.of(context).pushNamed("/bbs/postDetail", arguments: {
                  "post": await PostRepository.getInstance()
                      .loadSpecificPost(e.discussion)
                });
                progressDialog.dismiss();
              }
            },
          )),
    );
  }
}
