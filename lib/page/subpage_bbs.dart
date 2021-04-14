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
import 'package:data_plugin/bmob/response/bmob_registered.dart';
import 'package:data_plugin/bmob/table/bmob_user.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';

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
  BmobUser _loginUser;
  static StreamSubscription _postSubscription;
  static StreamSubscription _refreshSubscription;
  ScrollController _controller = ScrollController();
  ConnectionStatus _loginStatus = ConnectionStatus.NONE;

  @override
  void initState() {
    super.initState();
    if (_postSubscription == null) {
      _postSubscription = Constant.eventBus.on<AddNewPostEvent>().listen((_) {
        Navigator.of(context).pushNamed("/bbs/newPost",
            arguments: {"post": BBSPost.newPost(_loginUser.objectId)});
      });
    }
    if (_refreshSubscription == null) {
      _refreshSubscription = Constant.eventBus
          .on<RetrieveNewPostEvent>()
          .listen((_) => refreshSelf());
    }
  }

  @override
  void dispose() {
    super.dispose();
    _postSubscription.cancel();
    _refreshSubscription.cancel();
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
            //color: isCupertino(context) ? Colors.white : null,
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
    print(e);
    print(trace);
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
    if (_loginUser == null || _loginUser.email != info.id) {
      _loginStatus = ConnectionStatus.CONNECTING;
      _loginUser = await PostRepository.getInstance()
          .login(info)
          .catchError((e, s) => handleError(info, e, s));
    }
    if (_loginUser != null) {
      _loginStatus = ConnectionStatus.DONE;
      return await PostRepository.getInstance().loadPosts();
    } else {
      return null;
    }
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
                if (snapshot.hasData) {
                  // If login failed
                  if (snapshot.data == null) {
                    return _buildErrorPage();
                  } else {
                    return _buildPage(snapshot.data);
                  }
                } else if (snapshot.hasError) {
                  return _buildErrorPage(error: snapshot.error);
                } else {
                  return _buildLoadingPage();
                }
              },
              future: loginAndLoadPost(context.personInfo))
        )
    );
  }

  Widget _buildLoadingPage() {
    return GestureDetector(
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorPage({Exception error}) {
    return GestureDetector(
      child: Center(
        child: Text(S.of(context).failed),
      ),
      onTap: () {
        _loginStatus = ConnectionStatus.NONE;
        refreshSelf();
      },
    );
  }

  Widget _buildPage(List<BBSPost> data) {
    return PlatformWidget(
        // Add a scrollbar on desktop platform
        material: (_, __) => Scrollbar(
            controller: _controller,
            interactive: PlatformX.isDesktop,
            child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _controller,
                children: data.map((e) => _getListItem(e)).toList())),
        cupertino: (_, __) => CupertinoScrollbar(
            controller: _controller,
            child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _controller,
                children: data.map((e) => _getListItem(e)).toList())));
  }

  Widget _getListItem(BBSPost e) {
    return Material(
        color: PlatformX.isCupertino(context) ? Colors.white : null,
        child: Card(
          child: ListTile(
              leading: Icon(SFSymbols.quote_bubble_fill),
              visualDensity: VisualDensity(vertical: 2),
              dense: false,
              title: Text(e.content,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16),), //TODO: Support Dynamic Font
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    e.author,
                    style: TextStyle(color: Theme.of(context).accentColor, fontSize: 12),
                  ),
                  Text(
                    e.createdAt,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              onTap: () {
                Navigator.of(context).pushNamed("/bbs/postDetail",
                    arguments: {"post": e, "user": _loginUser});
              }),
        ));
  }

  @override
  bool get wantKeepAlive => true;
}
