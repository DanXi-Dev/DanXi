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

import 'package:beautifulsoup/beautifulsoup.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/post.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:dan_xi/util/human_duration.dart';
import 'package:dan_xi/util/stream_listener.dart';
import 'package:dan_xi/widget/bbs_editor.dart';
import 'package:dan_xi/widget/future_widget.dart';
import 'package:dan_xi/widget/material_x.dart';
import 'package:dan_xi/widget/round_chip.dart';
import 'package:dan_xi/widget/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bbs_editor.dart';

/// Render the text from a clip of [html].
String renderText(String html, String imagePlaceholder) {
  var soup = Beautifulsoup(html);
  var images = soup.find_all("img");
  if (images.length > 0) return soup.get_text() + imagePlaceholder;
  return soup.get_text();
}

const KEY_NO_TAG = "默认";

/// Turn tags into Widgets
Widget generateTagWidgets(BBSPost e, void Function(String) onTap) {
  if (e == null || e.tag == null) return Container();
  List<Widget> _tags = [];
  e.tag.forEach((element) {
    if (element.name == KEY_NO_TAG) return [Container()];
    _tags.add(Flex(
        direction: Axis.horizontal,
        mainAxisSize: MainAxisSize.min,
        children: [
          RoundChip(
            onTap: () => onTap(element.name),
            label: element.name,
            color: Constant.getColorFromString(element.color),
          ),
        ]));
  });
  return Wrap(
    direction: Axis.horizontal,
    spacing: 4,
    runSpacing: 4,
    children: _tags,
  );
}

class BBSSubpage extends PlatformSubpage {
  @override
  bool get needPadding => true;

  @override
  _BBSSubpageState createState() => _BBSSubpageState();

  BBSSubpage({Key key});
}

class AddNewPostEvent {}

class RetrieveNewPostEvent {}

class SortOrderChangedEvent {
  SortOrder newOrder;

  SortOrderChangedEvent(this.newOrder);
}

class _BBSSubpageState extends State<BBSSubpage>
    with AutomaticKeepAliveClientMixin {
  StateStreamListener _postSubscription = StateStreamListener();
  StateStreamListener _refreshSubscription = StateStreamListener();
  StateStreamListener _searchSubscription = StateStreamListener();
  StateStreamListener _sortOrderChangedSubscription = StateStreamListener();

  int _currentBBSPage;
  SortOrder _sortOrder;
  String _tagFilter;

  List<Widget> _lastPageItems;
  AsyncSnapshot _lastSnapshotData;
  bool _isRefreshing;
  bool _isEndIndicatorShown;
  static const POST_COUNT_PER_PAGE = 10;

  SharedPreferences _preferences;

  void refreshSelf() {
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(() {
        _initialize();
      });
    }
  }

  void _initialize() {
    _currentBBSPage = 1;
    _lastPageItems = [_buildSearchTextField()];
    _lastSnapshotData = null;
    _isRefreshing = true;
    _isEndIndicatorShown = false;
    _tagFilter = null;
  }

  Widget _buildSearchTextField() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: CupertinoSearchTextField(
        onSubmitted: (value) {
          if (value.trim() == "") return;
          Navigator.of(context).pushNamed("/bbs/postDetail", arguments: {
            "post": PostRepository.getInstance().loadSearchResults(value)
          });
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _sortOrder = SortOrder.LAST_REPLIED;
    _initialize();

    _postSubscription.bindOnlyInvalid(
        Constant.eventBus.on<AddNewPostEvent>().listen((_) {
          Navigator.pushNamed(context, "/bbs/newPost")
              .then<int>((value) => value is PostEditorText
                  ? PostRepository.getInstance()
                      .newPost(value?.content, tags: value?.tags)
                  : 0)
              .then((value) => refreshSelf());
        }),
        hashCode);
    _refreshSubscription.bindOnlyInvalid(
        Constant.eventBus
            .on<RetrieveNewPostEvent>()
            .listen((_) => refreshSelf()),
        hashCode);
    _sortOrderChangedSubscription.bindOnlyInvalid(
        Constant.eventBus.on<SortOrderChangedEvent>().listen((event) {
          _sortOrder = event.newOrder;
          refreshSelf();
        }),
        hashCode);
  }

  @override
  void didChangeDependencies() {
    _preferences = Provider.of<SharedPreferences>(context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
    _postSubscription.cancel();
    _refreshSubscription.cancel();
    _searchSubscription.cancel();
    _sortOrderChangedSubscription.cancel();
  }

  /// Log in and load all of the posts.
  Future<List<BBSPost>> loginAndLoadPost(
      PersonInfo info, SortOrder sortOrder) async {
    if (!PostRepository.getInstance().isUserInitialized)
      await PostRepository.getInstance().initializeUser(info, _preferences);
    return await PostRepository.getInstance()
        .loadPosts(_currentBBSPage, sortOrder);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
        color: Theme.of(context).accentColor,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          refreshSelf();
        },
        child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: FutureWidget<List<BBSPost>>(
                future: _tagFilter == null
                    ? loginAndLoadPost(context.personInfo, _sortOrder)
                    : PostRepository.getInstance()
                        .loadTagFilteredPosts(_tagFilter, _sortOrder),
                successBuilder: (BuildContext context,
                    AsyncSnapshot<List<BBSPost>> snapshot) {
                  snapshot.data.forEach((element) {
                    _lastPageItems.add(_getListItem(element));
                  });
                  _isRefreshing = false;
                  _lastSnapshotData = snapshot;
                  return _buildPage(snapshot.data, false);
                },
                errorBuilder: (BuildContext context,
                    AsyncSnapshot<List<BBSPost>> snapshot) {
                  if (snapshot.error == LoginExpiredError) {
                    SettingsProvider.of(_preferences).deleteSavedFduholeToken();
                    return _buildErrorPage(
                        error: S.of(context).error_login_expired);
                  } else if (snapshot.error is NotLoginError)
                    return _buildErrorPage(
                        error: (snapshot.error as NotLoginError).errorMessage);
                  return _buildErrorPage(error: snapshot.error.toString());
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
                  return _buildPage(_lastSnapshotData.data, true);
                })));
  }

  Widget _buildLoadingPage() => Container(
        padding: EdgeInsets.all(8),
        child: Center(child: PlatformCircularProgressIndicator()),
      );

  Widget _buildErrorPage({String error}) {
    return GestureDetector(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            S.of(context).failed + '\n\nThe error was:\n' + error,
          ),
        ),
      ),
      onTap: () {
        refreshSelf();
      },
    );
    //  ],);
  }

  Widget _buildPage(List<BBSPost> data, bool isLoading) =>
      NotificationListener<ScrollNotification>(
        child: WithScrollbar(
          child: ListView.builder(
            primary: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: (_currentBBSPage) * POST_COUNT_PER_PAGE +
                (isLoading ? 1 - POST_COUNT_PER_PAGE : 0),
            itemBuilder: (context, index) => _buildListItem(index, data),
          ),
          controller: PrimaryScrollController.of(context),
        ),
        onNotification: (ScrollNotification scrollInfo) {
          if (_tagFilter == null &&
              scrollInfo.metrics.extentAfter < 500 &&
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

  Widget _buildListItem(int index, List<BBSPost> data) {
    if (!_isEndIndicatorShown &&
        !_isRefreshing &&
        index >= _lastPageItems.length) {
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
    if (index >= _lastPageItems.length)
      return _isEndIndicatorShown ? Container() : _buildLoadingPage();
    return _lastPageItems[index];
  }

  Widget _getListItem(BBSPost postElement) {
    return ThemedMaterial(
      child: Card(
          child: Column(children: [
        ListTile(
            contentPadding: EdgeInsets.fromLTRB(17, 4, 10, 0),
            dense: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                generateTagWidgets(postElement, (String tagname) {
                  setState(() {
                    _tagFilter = tagname;
                    _currentBBSPage = 1;
                    _lastPageItems = [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(S.of(context).filtering_by_tag(_tagFilter)),
                      )
                    ];
                    _lastSnapshotData = null;
                    _isRefreshing = true;
                    _isEndIndicatorShown = false;
                  });
                }),
                const SizedBox(
                  height: 10,
                ),
                postElement.is_folded
                    ? Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          expandedAlignment: Alignment.topLeft,
                          childrenPadding: EdgeInsets.symmetric(vertical: 4),
                          tilePadding: EdgeInsets.zero,
                          title: Text(
                            S.of(context).folded,
                            style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontSize: 12),
                          ),
                          children: [
                            Text(
                              renderText(postElement.first_post.content,
                                  S.of(context).image_tag),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      )
                    : Text(
                        renderText(postElement.first_post.content,
                            S.of(context).image_tag),
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
                      "#${postElement.id}",
                      style: TextStyle(
                          color: Theme.of(context).hintColor, fontSize: 12),
                    ),
                    Text(
                      HumanDuration.format(
                          context, DateTime.parse(postElement.date_created)),
                      style: TextStyle(
                          color: Theme.of(context).hintColor, fontSize: 12),
                    ),
                    Row(
                      children: [
                        Text(
                          postElement.count.toString() + " ",
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
              Navigator.of(context).pushNamed("/bbs/postDetail",
                  arguments: {"post": postElement});
            }),
        if (!postElement.is_folded &&
            postElement.last_post.id != postElement.first_post.id)
          Divider(
            height: 4,
          ),
        if (!postElement.is_folded &&
            postElement.last_post.id != postElement.first_post.id)
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
                        postElement.last_post.username,
                        HumanDuration.format(
                            context,
                            DateTime.parse(
                                postElement.last_post.date_created))),
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ),
                Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
                    child: Text(
                      renderText(postElement.last_post.content,
                                  S.of(context).image_tag)
                              .trim()
                              .isEmpty
                          ? S.of(context).no_summary
                          : renderText(postElement.last_post.content,
                              S.of(context).image_tag),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      //style: TextStyle(color: Theme.of(context).hintColor),
                    )),
              ],
            ),
            onTap: () => BBSEditor.createNewReply(
                context, postElement.id, postElement.last_post.id),
          )
      ])),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
