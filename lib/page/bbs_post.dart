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

import 'package:clipboard/clipboard.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/post.dart';
import 'package:dan_xi/model/reply.dart';
import 'package:dan_xi/page/subpage_bbs.dart';
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:dan_xi/util/human_duration.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/bbs_editor.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

class BBSPostDetail extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const BBSPostDetail({Key key, this.arguments});

  @override
  _BBSPostDetailState createState() => _BBSPostDetailState();
}

class _BBSPostDetailState extends State<BBSPostDetail> {
  BBSPost _post;
  int _currentBBSPage;
  List<Reply> _lastReplies;
  AsyncSnapshot _lastSnapshotData;
  bool _isRefreshing;
  bool _isEndIndicatorShown;
  static const POST_COUNT_PER_PAGE = 10;

  @override
  void initState() {
    super.initState();
    _post = widget.arguments['post'];

    _currentBBSPage = 1;
    _lastReplies = [];
    _lastSnapshotData = null;
    _isRefreshing = true;
    _isEndIndicatorShown = false;
  }

  void refreshSelf() {
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(() {
        _currentBBSPage = 1;
        _lastReplies = [];
        _lastSnapshotData = null;
        _isRefreshing = true;
        _isEndIndicatorShown = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentPadding: true,
      iosContentBottomPadding: true,
      appBar: PlatformAppBarX(
        title: Text(S.of(context).forum),
        trailingActions: [
          PlatformIconButton(
            padding: EdgeInsets.zero,
            icon: PlatformX.isAndroid
                ? const Icon(Icons.reply)
                : const Icon(SFSymbols.arrowshape_turn_up_left),
            onPressed: () {
              BBSEditor.createNewReply(context, _post.id, null)
                  .then((value) => refreshSelf());
            },
          )
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
            child: FutureBuilder(
                builder: (_, AsyncSnapshot<List<Reply>> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                    case ConnectionState.active:
                      _isRefreshing = true;
                      if (_lastSnapshotData == null)
                        return Container(
                          padding: EdgeInsets.all(8),
                          child: Center(
                              child: PlatformCircularProgressIndicator()),
                        );
                      return _buildPage(_lastSnapshotData.data, true);
                      break;
                    case ConnectionState.done:
                      _lastReplies.addAll(snapshot.data);
                      _isRefreshing = false;
                      if (snapshot.hasError) {
                        return _buildErrorWidget();
                      } else {
                        _lastSnapshotData = snapshot;
                        return _buildPage(snapshot.data, false);
                      }
                      break;
                  }
                  return null;
                },
                future: PostRepository.getInstance()
                    .loadReplies(_post, _currentBBSPage)),
          )),
    );
  }

  Widget _buildPage(List<Reply> data, bool isLoading) =>
      NotificationListener<ScrollNotification>(
        child: WithScrollbar(
          child: ListView.builder(
            primary: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount:
                (_currentBBSPage) * POST_COUNT_PER_PAGE + (isLoading ? 1 : 0),
            itemBuilder: (context, index) => _buildListItem(index, data, true),
          ),
          controller: PrimaryScrollController.of(context),
        ),
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.extentAfter < 500 &&
              !_isRefreshing &&
              !_isEndIndicatorShown) {
            _isRefreshing = true;
            setState(() {
              _currentBBSPage++;
            });
          }
          return false;
        },
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
          : GestureDetector(
              child: Center(child: PlatformCircularProgressIndicator()),
            );
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
    List<Widget> list = [];
    list.add(PlatformWidget(
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
    ));
    list.add(PlatformWidget(
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
    ));
    return list;
  }

  Widget _wrapListItemInCanvas(Reply e, bool generateTags) =>
      Material(child: _getListItems(e, generateTags, false));

  Widget _getListItems(Reply e, bool generateTags, bool isNested) =>
      GestureDetector(
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
                      child: Row(
                        children: generateTagWidgets(_post),
                      ),
                    ),
                  Row(
                    children: [
                      if (e.username == _post.first_post.username)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          decoration: BoxDecoration(
                              color: Constant.getColorFromString(
                                      _post.tag.first.color)
                                  .withOpacity(0.8),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(4.0))),
                          child: Text(
                            "OP",
                            style: TextStyle(
                                color: Theme.of(context)
                                            .hintColor
                                            .computeLuminance() >=
                                        0.5
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 12),
                          ),
                        ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: Text(
                          "[${e.username}]",
                        ),
                      ),
                    ],
                  ),
                  if (e.reply_to != null && !isNested)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: _getListItems(
                          _lastReplies.firstWhere(
                              (element) => element.id == e.reply_to),
                          false,
                          true),
                    ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: isNested
                        // If content is being quoted, limit its height so that the view won't be too long.
                        ? Text(
                            renderText(e.content, S.of(context).image_tag),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : HtmlWidget(
                            e.content,
                            textStyle: TextStyle(fontSize: 16),
                            onTapUrl: (url) => launch(url),
                          ),
                  ),
                ],
              ),
              subtitle: Column(children: [
                const SizedBox(
                  height: 8,
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "#${e.id}",
                        style: TextStyle(
                            color: Theme.of(context).hintColor, fontSize: 12),
                      ),
                      Text(
                        HumanDuration.format(
                            context, DateTime.parse(e.date_created)),
                        style: TextStyle(
                            color: Theme.of(context).hintColor, fontSize: 12),
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
              onTap: () {
                BBSEditor.createNewReply(context, _post.id, e.id)
                    .then((value) => refreshSelf());
              },
            )),
      );
}
