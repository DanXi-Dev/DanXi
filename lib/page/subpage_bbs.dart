/*
 *     Copyright (C) 2021  w568w
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

import 'package:beautifulsoup/beautifulsoup.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/post.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:dan_xi/repository/card_repository.dart';
import 'package:dan_xi/util/bmob/bmob/response/bmob_registered.dart';
import 'package:dan_xi/util/bmob/bmob/table/bmob_user.dart';
import 'package:dan_xi/util/human_duration.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/bbs_editor.dart';
import 'package:dan_xi/widget/future_widget.dart';
import 'package:dan_xi/widget/material_x.dart';
import 'package:dan_xi/widget/round_chip.dart';
import 'package:dan_xi/widget/top_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:html_editor_enhanced/html_editor.dart';

import 'bbs_editor.dart';

class BBSSubpage extends PlatformSubpage {
  @override
  bool get needPadding => true;

  @override
  _BBSSubpageState createState() => _BBSSubpageState();

  BBSSubpage({Key key});
}

class AddNewPostEvent {}

class RetrieveNewPostEvent {}

class _BBSSubpageState extends State<BBSSubpage>
    with AutomaticKeepAliveClientMixin {
  static StreamSubscription _postSubscription;
  static StreamSubscription _refreshSubscription;
  static StreamSubscription _goTopSubscription;
  ScrollController _controller = ScrollController();
  HtmlEditorController controller = HtmlEditorController();

  int _currentBBSPage;
  List<Widget> _lastPageItems;
  AsyncSnapshot _lastSnapshotData;
  bool _isRefreshing;
  bool _isEndIndicatorShown;
  static const POST_COUNT_PER_PAGE = 10;

  void refreshSelf() {
    if (mounted) {
      _currentBBSPage = 1;
      _lastPageItems = [];
      _lastSnapshotData = null;
      _isRefreshing = true;
      _isEndIndicatorShown = false;
      // ignore: invalid_use_of_protected_member
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();

    _currentBBSPage = 1;
    _lastPageItems = [];
    _lastSnapshotData = null;
    _isRefreshing = true;
    _isEndIndicatorShown = false;

    if (_postSubscription == null) {
      _postSubscription = Constant.eventBus.on<AddNewPostEvent>().listen((_) {
        Navigator.pushNamed(context, "/bbs/newPost")
            .then<int>((value) => value is PostEditorText
                ? PostRepository.getInstance()
                    .newPost(value?.content, tags: value?.tags)
                : 0)
            .then((value) => refreshSelf());
      });
    }
    if (_refreshSubscription == null) {
      _refreshSubscription = Constant.eventBus
          .on<RetrieveNewPostEvent>()
          .listen((_) => refreshSelf());
    }
    if (_goTopSubscription == null) {
      _goTopSubscription =
          Constant.eventBus.on<ScrollToTopEvent>().listen((event) {
        TopController.scrollToTop(_controller);
      });
    }
    if (_controller != null) {
      // Over-scroll event
      _controller.addListener(_scrollListener);
    }
  }

  void _scrollListener() {
    if (_controller.position.extentAfter < 500 &&
        !_isRefreshing &&
        !_isEndIndicatorShown) {
      _isRefreshing = true;
      setState(() {
        _currentBBSPage++;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (_postSubscription != null) _postSubscription.cancel();
    if (_refreshSubscription != null) _refreshSubscription.cancel();
    _postSubscription = null;
    _refreshSubscription = null;
  }

  /// Login in and load all of the posts.
  Future<List<BBSPost>> loginAndLoadPost(PersonInfo info) async {
    var _postRepoInstance = PostRepository.getInstance();
    if (!_postRepoInstance.isUserInitialized)
      await _postRepoInstance.initializeUser(info);
    return await _postRepoInstance.loadPosts(_currentBBSPage);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
        color: Theme.of(context).accentColor,
        onRefresh: () async => refreshSelf(),
        child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: FutureWidget<List<BBSPost>>(
                future: loginAndLoadPost(context.personInfo),
                successBuilder: (BuildContext context,
                    AsyncSnapshot<List<BBSPost>> snapshot) {
                  _isRefreshing = false;
                  _lastSnapshotData = snapshot;
                  return _buildPage(snapshot.data);
                },
                errorBuilder: (BuildContext context,
                    AsyncSnapshot<List<BBSPost>> snapshot) {
                  return _buildErrorPage(error: snapshot.error);
                },
                loadingBuilder: () {
                  _isRefreshing = true;
                  if (_lastSnapshotData == null)
                    return Container(
                      padding: EdgeInsets.all(8),
                      child: Center(
                        child: PlatformCircularProgressIndicator(),
                      ),
                    );
                  return _buildPageWhileLoading(_lastSnapshotData.data);
                })));
  }

  Widget _buildLoadingPage() => Container(
        padding: EdgeInsets.all(8),
        child: Center(child: CircularProgressIndicator()),
      );

  Widget _buildErrorPage({Exception error}) {
    return GestureDetector(
      child: Center(
        child: Text(S.of(context).failed),
      ),
      onTap: () {
        refreshSelf();
      },
    );
    //  ],);
  }

  Widget _buildPage(List<BBSPost> data) {
    return PlatformWidget(
        // Add a scrollbar on desktop platform
        material: (_, __) => Scrollbar(
              controller: _controller,
              interactive: PlatformX.isDesktop,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _controller,
                itemCount: (_currentBBSPage) * POST_COUNT_PER_PAGE,
                itemBuilder: (context, index) =>
                    _buildListItem(index, data, true),
              ),
            ),
        cupertino: (_, __) => CupertinoScrollbar(
              controller: _controller,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _controller,
                itemCount: _currentBBSPage * POST_COUNT_PER_PAGE,
                itemBuilder: (context, index) =>
                    _buildListItem(index, data, true),
              ),
            ));
  }

  Widget _buildPageWhileLoading(List<BBSPost> data) {
    return PlatformWidget(
      // Add a scrollbar on desktop platform
        material: (_, __) => Scrollbar(
              controller: _controller,
              interactive: PlatformX.isDesktop,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _controller,
                itemCount: (_lastSnapshotData == null
                            ? _currentBBSPage
                            : _currentBBSPage - 1) *
                        POST_COUNT_PER_PAGE +
                    1,
                itemBuilder: (context, index) =>
                    _buildListItem(index, data, false),
              ),
            ),
        cupertino: (_, __) => CupertinoScrollbar(
              controller: _controller,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _controller,
                itemCount: (_lastSnapshotData == null
                            ? _currentBBSPage
                            : _currentBBSPage - 1) *
                        POST_COUNT_PER_PAGE +
                    1,
                itemBuilder: (context, index) =>
                    _buildListItem(index, data, false),
              ),
            ));
  }

  Widget _buildListItem(int index, List<BBSPost> data, bool isNewData) {
    if (isNewData && index >= _lastPageItems.length) {
      try {
        _lastPageItems.add(_getListItem(data[index % POST_COUNT_PER_PAGE]));
      } catch (e) {
        if (!_isEndIndicatorShown) {
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
        return null;
      }
    }
    if (index >= _lastPageItems.length) return _buildLoadingPage();
    return _lastPageItems[index];
  }

  /// Render the text from a clip of [html].
  String _renderTitle(String html) {
    var soup = Beautifulsoup(html);
    return soup.get_text();
  }

  List<Widget> _generateTagWidgets(BBSPost e) {
    List<Widget> _tags = [
      const SizedBox(
        width: 2,
      ),
    ];
    e.tag.forEach((element) {
      _tags.add(RoundChip(
        label: element.name,
        color: Constant.getColorFromString(element.color),
      ));
      _tags.add(const SizedBox(
        width: 6,
      ));
    });
    return _tags;
  }

  Widget _getListItem(BBSPost e) {
    return ThemedMaterial(
      child: Card(
          child: Column(children: [
        ListTile(
            contentPadding: EdgeInsets.fromLTRB(17, 4, 10, 0),
            dense: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: _generateTagWidgets(e),
                ),
                const SizedBox(
                  height: 10,
                ),
                e.is_folded
                    ? ListTileTheme(
                        dense: true,
                        child: ExpansionTile(
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          expandedAlignment: Alignment.topLeft,
                          childrenPadding: EdgeInsets.symmetric(vertical: 4),
                          tilePadding: EdgeInsets.zero,
                          title: Text(
                            S.of(context).folded,
                            style:
                                TextStyle(color: Theme.of(context).hintColor),
                          ),
                          children: [
                            Text(
                              _renderTitle(e.first_post.content),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      )
                    : Text(
                        _renderTitle(e.first_post.content),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
              ],
            ),
            subtitle: Column(
              children: [
                const SizedBox(
                  height: 12,
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
                    Row(
                      children: [
                        Text(
                          e.count.toString() + " ",
                          style: TextStyle(
                              color: Theme.of(context).hintColor, fontSize: 12),
                        ),
                        Icon(
                          SFSymbols.ellipses_bubble,
                          size: 12,
                          color: Theme.of(context).hintColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context)
                  .pushNamed("/bbs/postDetail", arguments: {"post": e});
            }),
        if (!e.is_folded && e.last_post.id != e.first_post.id)
          Divider(
            height: 4,
          ),
        if (!e.is_folded && e.last_post.id != e.first_post.id)
          ListTile(
            dense: true,
            minLeadingWidth: 16,
            leading: Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 4),
              child: Icon(
                SFSymbols.quote_bubble,
                color: Theme.of(context).hintColor,
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 8, 0, 4),
                  child: Text(
                    S.of(context).latest_reply(
                        e.last_post.username,
                        HumanDuration.format(
                            context, DateTime.parse(e.last_post.date_created))),
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ),
                Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
                    child: Text(
                      _renderTitle(e.last_post.content).trim().isEmpty
                          ? S.of(context).no_summary
                          : _renderTitle(e.last_post.content),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      //style: TextStyle(color: Theme.of(context).hintColor),
                    )),
              ],
            ),
            onTap: () {
              BBSEditor.createNewReply(context, e.id, e.last_post.id);
            },
          )
      ])),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
