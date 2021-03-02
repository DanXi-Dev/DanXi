import 'dart:async';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/post.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:dan_xi/repository/card_repository.dart';
import 'package:data_plugin/bmob/response/bmob_registered.dart';
import 'package:data_plugin/bmob/table/bmob_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';

class BBSSubpage extends StatefulWidget {
  @override
  _BBSSubpageState createState() => _BBSSubpageState();

  BBSSubpage({Key key});
}

class NewPostEvent {}

class RetrieveNewPostEvent {}

class _BBSSubpageState extends State<BBSSubpage>
    with AutomaticKeepAliveClientMixin {
  BmobUser _loginUser;
  static StreamSubscription _postSubscription;
  static StreamSubscription _refreshSubscription;

  @override
  void initState() {
    super.initState();
    if (_postSubscription == null) {
      _postSubscription = Constant.eventBus.on<NewPostEvent>().listen((_) {
        Navigator.of(context).pushNamed("/bbs/newPost",
            arguments: {"post": BBSPost.newPost(_loginUser.objectId)});
      });
    }
    _refreshSubscription = Constant.eventBus
        .on<RetrieveNewPostEvent>()
        .listen((_) => refreshSelf());
  }

  @override
  void dispose() {
    super.dispose();
    _postSubscription.cancel();
    _refreshSubscription.cancel();
    _postSubscription = null;
    _refreshSubscription = null;
  }

  Future<BmobUser> register(PersonInfo info) async {
    var result = await showPlatformDialog<BmobRegistered>(
      barrierDismissible: false,
      context: context,
      builder: (_) => PlatformAlertDialog(
        title: Text(S.of(context).login_with_uis),
        content: Material(
            child: ListTile(
          leading: Icon(Icons.account_circle),
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
    if (_loginUser == null) {
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
          setState(() {});
        },
        child: FutureBuilder(
            builder: (_, AsyncSnapshot<List<BBSPost>> snapshot) =>
                snapshot.hasData
                    ? ListView(
                        children:
                snapshot.data.map((e) => _getListItem(e)).toList())
                : Container(),
            future: loginAndLoadPost(info)));
  }

  Widget _getListItem(BBSPost e) {
    return Material(
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
