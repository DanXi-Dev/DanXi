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

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/post.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:data_plugin/bmob/table/bmob_user.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';

class BBSPostDetail extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const BBSPostDetail({Key key, this.arguments});

  @override
  _BBSPostDetailState createState() => _BBSPostDetailState();
}

class _BBSPostDetailState extends State<BBSPostDetail> {
  BBSPost _post;
  BmobUser _user;

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentBottomPadding: true,
      appBar: PlatformAppBar(
        title: Text(S.of(context).forum),
        trailingActions: [
          PlatformIconButton(
            padding: EdgeInsets.zero,
            icon: PlatformX.isAndroid
                ? const Icon(Icons.reply)
                : const Icon(SFSymbols.arrowshape_turn_up_left),
            onPressed: () {
              Navigator.of(context).pushNamed("/bbs/newPost", arguments: {
                "post": BBSPost.newReply(_user.objectId, _post.objectId)
              });
            },
          )
        ],
      ),
      body: RefreshIndicator(
          color: Colors.deepPurple,
          onRefresh: () async {
            refreshSelf();
          },
          child: FutureBuilder(
              builder: (_, AsyncSnapshot<List<BBSPost>> snapshot) {
                if (snapshot.hasData) {
                  var l = snapshot.data;
                  return ListView.separated(
                      itemBuilder: (context, index) =>
                          _getListItem(l[index], index),
                      separatorBuilder: (_, __) => Divider(
                            color: Colors.grey,
                          ),
                      itemCount: l.length);
                }
                return Container();
              },
              future: PostRepository.getInstance().loadReplies(_post))),
    );
  }

  Widget _getListItem(BBSPost e, int index) => Material(
      color: isCupertino(context) ? Colors.white : null,
      child: ListTile(
        dense: false,
        title: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Text("No. ${int.parse(e.objectId, radix: 36)}",
                  style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
            ),
            e.replyTo == "0"
                ? Column()
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                        S.of(context).reply_to(int.parse(e.replyTo, radix: 36)),
                        style: TextStyle(fontSize: 10, color: Colors.green)),
                  ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(e.content, style: TextStyle(fontSize: 15)),
            )
          ],
        ),
        subtitle: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.author,
                    style: TextStyle(color: Colors.deepPurple, fontSize: 12),
                  ),
                  Text(
                    e.createdAt,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Text("# ${index + 1}", style: TextStyle(fontSize: 12)),
            )
          ],
        ),
        onTap: () {
          Navigator.of(context).pushNamed("/bbs/newPost", arguments: {
            "post": BBSPost.newReply(_user.objectId, _post.objectId,
                replyTo: index > 0 ? e.objectId : "0"),
            "replyTo": e.author
          });
        },
      ));

  @override
  void initState() {
    super.initState();
    _post = widget.arguments['post'];
    _user = widget.arguments['user'];
  }
}
