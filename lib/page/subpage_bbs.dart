import 'dart:async';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/post.dart';
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:dan_xi/repository/card_repository.dart';
import 'package:data_plugin/bmob/response/bmob_registered.dart';
import 'package:data_plugin/bmob/table/bmob_user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BBSSubpage extends StatefulWidget {
  @override
  _BBSSubpageState createState() => _BBSSubpageState();

  BBSSubpage({Key key});
}

class NewPostEvent {}

class _BBSSubpageState extends State<BBSSubpage> {
  BmobUser _loginUser;
  StreamSubscription _postSubscription;

  @override
  void initState() {
    super.initState();
    _postSubscription = Constant.eventBus.on<NewPostEvent>().listen((event) {
      Navigator.of(context).pushNamed("/bbs/newPost",
          arguments: {"post": BBSPost.newPost(_loginUser.objectId)});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _postSubscription.cancel();
  }

  Future<BmobUser> register(PersonInfo info) async {
    var result = await showDialog<BmobRegistered>(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        title: Text(S.of(context).login_with_uis),
        content: ListTile(
          leading: Icon(Icons.account_circle),
          title: Text(info.name),
          subtitle: Text(info.id),
        ),
        actions: [
          TextButton(
              onPressed: () async {
                BmobRegistered registered =
                    await PostRepository.getInstance().register(info);
                Navigator.pop(context, registered);
              },
              child: Text(S.of(context).login)),
          TextButton(
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
    PersonInfo info = Provider.of<ValueNotifier<PersonInfo>>(context)?.value;
    return RefreshIndicator(
        color: Colors.deepPurple,
        onRefresh: () async {
          setState(() {});
        },
        child: FutureBuilder(
            builder: (_, AsyncSnapshot<List<BBSPost>> snapshot) => snapshot
                    .hasData
                ? ListView(
                    children: snapshot.data
                        .map((e) => ListTile(
                              dense: false,
                              title: Text(e.content,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis),
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
                                Navigator.of(context).pushNamed(
                                    "/bbs/postDetail",
                                    arguments: {"post": e, "user": _loginUser});
                              },
                            ))
                        .toList())
                : Container(),
            future: loginAndLoadPost(info)));
  }
}
