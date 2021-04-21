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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/post.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:dan_xi/repository/card_repository.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/top_controller.dart';
import 'package:data_plugin/bmob/response/bmob_registered.dart';
import 'package:data_plugin/bmob/table/bmob_user.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

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
  ConnectionStatus _loginStatus = ConnectionStatus.NONE;

  int _currentBBSPage;
  List<Widget> _lastPageItems;
  AsyncSnapshot _lastSnapshotData;
  bool _isRefreshing;
  bool isEndIndicatorShown;
  static const POST_COUNT_PER_PAGE = 10;

  @override
  void initState() {
    super.initState();

    _currentBBSPage = 1;
    _lastPageItems = [];
    _lastSnapshotData = null;
    _isRefreshing = true;
    isEndIndicatorShown = false;

    if (_postSubscription == null) {
      _postSubscription = Constant.eventBus.on<AddNewPostEvent>().listen((_) {
        // TODO
        // Navigator.of(context).pushNamed("/bbs/newPost",
        //     arguments: {"post": BBSPost.newPost(_loginUser.objectId)});
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
    if(_controller != null) {
      //Overscroll event
      _controller.addListener(() {
        if(_controller.offset >= _controller.position.maxScrollExtent && !_isRefreshing) {
          _isRefreshing = true;
          setState(() {
            _currentBBSPage++;
          });
        }
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

  /// Pop up a dialog to request for signing up and complete registration
  Future<BmobUser> register(PersonInfo info) async {
    BmobRegistered result = await showPlatformDialog<BmobRegistered>(
      barrierDismissible: false,
      context: context,
      builder: (_) => PlatformAlertDialog(
        title: Text(S.of(context).login_with_uis),
        content: Material(
            child: ListTile(
          leading: PlatformX.isAndroid
              ? Icon(Icons.account_circle)
              : Icon(SFSymbols.person_crop_circle_fill),
          title: Text(info.name),
          subtitle: Text(info.id),
        )),
        actions: [
          PlatformButton(
              onPressed: () async {
                BmobRegistered registered =
                    await PostRepository.getInstance().register(info);
                Navigator.pop(context, registered);
              },
              child: Text(S.of(context).login)),
          PlatformButton(
              onPressed: () async {
                Navigator.pop(context, null);
              },
              child: Text(S.of(context).cancel)),
        ],
      ),
    );
    if (result == null) {
      throw LoginException();
    } else {
      _loginStatus = ConnectionStatus.DONE;
      return BmobUser()
        ..username = info.name
        ..email = info.id
        ..password = info.password
        ..sessionToken = result.sessionToken
        ..objectId = result.objectId
        ..createdAt = result.createdAt;
    }
  }

  /// Handle login error.
  ///
  /// Some common types:
  /// Connection failed: DioError [DioErrorType.CONNECT_TIMEOUT]: Connecting timed out [10000ms]
  /// Password is wrong or no account: DioError [DioErrorType.RESPONSE]: Http status error [400]
  ///
  FutureOr<BmobUser> handleError(
      PersonInfo info, dynamic e, StackTrace trace) async {
    if (e is DioError) {
      DioError error = e;
      if (error.type == DioErrorType.RESPONSE) {
        _loginStatus = ConnectionStatus.FATAL_ERROR;
        return await register(info);
      } else {
        // If timeout
        _loginStatus = ConnectionStatus.FAILED;
        return null;
      }
    }
    throw e;
  }

  /// Login in and load all of the posts.
  ///
  /// TODO: Load posts by page, instead of loading all of them at once
  Future<List<BBSPost>> loginAndLoadPost(PersonInfo info) async {
    //TODO:
    await PostRepository.getInstance().initializeUser(info);
    return await PostRepository.getInstance().loadPosts(_currentBBSPage);
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
            child: FutureBuilder(
                builder: (_, AsyncSnapshot<List<BBSPost>> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                    case ConnectionState.active:
                      _isRefreshing = true;
                      if (_lastSnapshotData == null) return _buildLoadingPage();
                      return _buildPageWhileLoading(_lastSnapshotData.data);
                      break;
                    case ConnectionState.done:
                      _isRefreshing = false;
                      if (snapshot.hasError || !snapshot.hasData) {
                        return _buildErrorPage(error: snapshot.error);
                      } else {
                        _lastSnapshotData = snapshot;
                        return _buildPage(snapshot.data);
                      }
                      break;
                  }
                  return null;
                },
                future: loginAndLoadPost(context.personInfo))));
  }

  Widget _buildLoadingPage() => Container(
    padding: EdgeInsets.all(7),
    child: Center(child: CircularProgressIndicator()),
  );

  Widget _buildErrorPage({Exception error}) {
    /*return Column(
      children: [
        if (_lastSnapshotData != null) _buildPage(_lastSnapshotData.data),*/
    return GestureDetector(
          child: Center(
            child: Text(S.of(context).failed),
          ),
          onTap: () {
            _loginStatus = ConnectionStatus.NONE;
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
              itemCount: (_currentBBSPage) * POST_COUNT_PER_PAGE + 1,
              itemBuilder: (context, index) => _buildListItem(index, data, true),
            ),),
        cupertino: (_, __) => CupertinoScrollbar(
            controller: _controller,
            child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _controller,
                itemCount: _currentBBSPage * POST_COUNT_PER_PAGE,
                itemBuilder: (context, index) => _buildListItem(index, data, true),
            ),
        )
    );
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
              itemCount: (_lastSnapshotData == null ? _currentBBSPage : _currentBBSPage - 1) * POST_COUNT_PER_PAGE + 1, //TODO: Move this hard-coded number to a Constant
              itemBuilder: (context, index) => _buildListItem(index, data, false),
            ),),
        cupertino: (_, __) => CupertinoScrollbar(
          controller: _controller,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _controller,
            itemCount: (_lastSnapshotData == null ? _currentBBSPage : _currentBBSPage - 1) * POST_COUNT_PER_PAGE + 1, //TODO: Move this hard-coded number to a Constant
            itemBuilder: (context, index) => _buildListItem(index, data, false),
          ),
        )
    );
  }

  Widget _buildListItem(int index, List<BBSPost> data, bool isNewData) {
    print("index: " + index.toString() + " length: " + _lastPageItems.length.toString() + " isNEWDATA " + isNewData.toString());
    if(isNewData && index >= _lastPageItems.length) {
      try {
        _lastPageItems.add(_getListItem(data[index % POST_COUNT_PER_PAGE]));
      }
      catch (e) {
        if (!isEndIndicatorShown) {
          isEndIndicatorShown = true;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget> [Divider(),Text(S.of(context).end_reached),],
          );
        }
        return null;
      }
    }
    if(index >= _lastPageItems.length) return _buildLoadingPage();
    return _lastPageItems[index];
  }

  Widget _getListItem(BBSPost e) {
    return Material(
        color: PlatformX.isCupertino(context) ? Colors.white : null,
        child: Card(
          child: ListTile(
              leading: Icon(SFSymbols.quote_bubble_fill),
              visualDensity: VisualDensity(vertical: 2),
              dense: false,
              title: HtmlWidget(
                e.first_post.content,
                textStyle: TextStyle(fontSize: 16),
                onTapUrl: (url) => launch(url),
                customStylesBuilder: (element) {
                    return {'max-lines': '1', 'text-overflow': 'ellipsis'};
                },
              ),
              /*Text(
                e.first_post.content,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16),
              ),*/
              subtitle: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "\n#" + e.id.toString(),
                    style: TextStyle(
                        color: Theme.of(context).hintColor, fontSize: 12),
                  ),
                  Text(
                    "\n" + e.date_created,
                    style: TextStyle(
                        color: Theme.of(context).hintColor, fontSize: 12),
                  ),
                  Text(
                    "\n" + e.count.toString(),
                    style: TextStyle(
                        color: Theme.of(context).hintColor, fontSize: 12),
                  ),
                ],
              ),
              onTap: () {
                Navigator.of(context)
                    .pushNamed("/bbs/postDetail", arguments: {"post": e});
              }),
        ));
  }

  @override
  bool get wantKeepAlive => true;
}
