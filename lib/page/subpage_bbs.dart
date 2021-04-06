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
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:provider/provider.dart';

class BBSSubpage extends PlatformSubpage {
  @override
  bool get needPadding => false;

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
    var result = await showPlatformDialog<BmobRegistered>(
      barrierDismissible: false,
      context: context,
      builder: (_) => PlatformAlertDialog(
        title: Text(S.of(context).login_with_uis),
        content: Material(
            color: isCupertino(context) ? Colors.white : null,
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
      return BmobUser()
        ..username = info.name
        ..email = info.id
        ..password = info.password
        ..sessionToken = result.sessionToken
        ..objectId = result.objectId
        ..createdAt = result.createdAt;
    }
  }

  Future<List<BBSPost>> loginAndLoadPost(PersonInfo info) async {
    if (_loginUser == null || _loginUser.email != info.id) {
      _loginUser = await PostRepository.getInstance()
          .login(info)
          .catchError((e, _) => register(info));
    }
    return await PostRepository.getInstance().loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    PersonInfo info = Provider.of<ValueNotifier<PersonInfo>>(context)?.value;
    return RefreshIndicator(
        color: Colors.deepPurple,
        onRefresh: () async {
          refreshSelf();
        },
        child: FutureBuilder(
            builder: (_, AsyncSnapshot<List<BBSPost>> snapshot) =>
                snapshot.hasData
                    ? PlatformWidget(
                        material: (_, __) => Scrollbar(
                            controller: _controller,
                            interactive: PlatformX.isDesktop,
                            child: ListView(
                                controller: _controller,
                                children: snapshot.data
                                    .map((e) => _getListItem(e))
                                    .toList())),
                        cupertino: (_, __) => CupertinoScrollbar(
                            controller: _controller,
                            child: ListView(
                                controller: _controller,
                                children: snapshot.data
                                    .map((e) => _getListItem(e))
                                    .toList())))
                    : Container(),
            future: loginAndLoadPost(info)));
  }

  Widget _getListItem(BBSPost e) {
    return Material(
        color: PlatformX.isCupertino(context) ? Colors.white : null,
        child: ListTile(
          dense: false,
          title: Text(e.content,
              maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.author,
                style: TextStyle(color: Colors.deepPurple),
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
          },
        ));
  }

  @override
  bool get wantKeepAlive => true;
}
