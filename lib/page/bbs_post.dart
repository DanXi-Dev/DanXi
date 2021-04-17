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
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/top_controller.dart';
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
  ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return PlatformProvider(
        builder: (BuildContext context) => PlatformScaffold(
              iosContentPadding: true,
              iosContentBottomPadding: true,
          appBar: PlatformAppBarX(
                title: TopController(
                  controller: _controller,
                  child: Text(S.of(context).forum),
                ),
                trailingActions: [
                  PlatformIconButton(
                    padding: EdgeInsets.zero,
                    icon: PlatformX.isAndroid
                        ? const Icon(Icons.reply)
                        : const Icon(SFSymbols.arrowshape_turn_up_left),
                    onPressed: () {
                      Navigator.of(context)
                          .pushNamed("/bbs/newPost", arguments: {
                        "post": BBSPost.newReply(_user.objectId, _post.objectId)
                      });
                    },
                  )
                ],
              ),
              body: RefreshIndicator(
                  color: Theme.of(context).accentColor,
                  onRefresh: () async {
                    refreshSelf();
                  },
                  child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: FutureBuilder(
                          builder: (_, AsyncSnapshot<List<BBSPost>> snapshot) {
                            switch (snapshot.connectionState) {
                              case ConnectionState.none:
                              case ConnectionState.waiting:
                              case ConnectionState.active:
                                return GestureDetector(
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                                break;
                              case ConnectionState.done:
                                if (snapshot.hasError) {
                                  return _buildErrorWidget();
                                } else {
                                  var l = snapshot.data;
                                  return ListView.builder(
                                      controller: _controller,
                                      itemBuilder: (context, index) =>
                                          _getListItem(l[index], index),
                                      //separatorBuilder: (_, __) => Divider(color: Colors.grey,),
                                      itemCount: l.length);
                                }
                                break;
                            }
                            return null;
                          },
                          future: PostRepository.getInstance()
                              .loadReplies(_post)))),
            ));
  }

  Widget _buildErrorWidget() => GestureDetector(
        child: Center(
          child: Text(S.of(context).failed),
        ),
        onTap: () {
          refreshSelf();
        },
      );

  Widget _getListItem(BBSPost e, int index) => Material(
      color: isCupertino(context) ? Colors.white : null,
      child: Card(
          child: ListTile(
        leading: Icon(SFSymbols.quote_bubble_fill),
        //visualDensity: VisualDensity(vertical: 2),
        dense: false,
        title: Column(
          children: [
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.topLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  e.replyTo == "0"
                      ? Column()
                      : Text(
                          S
                              .of(context)
                              .reply_to(int.parse(e.replyTo, radix: 36)),
                          style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).accentColor)),
                  Text("No. ${int.parse(e.objectId, radix: 36)}",
                      style: TextStyle(
                          fontSize: 10, color: Theme.of(context).hintColor)),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                e.content,
                style: TextStyle(fontSize: 16),
              ),
            )
          ],
        ),
        subtitle: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 2),
                  Text("# ${index + 1}", style: TextStyle(fontSize: 12)),
                  Text(
                    e.author,
                    style: TextStyle(
                        color: Theme.of(context).accentColor, fontSize: 12),
                  ),
                  Text(
                    e.createdAt,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).pushNamed("/bbs/newPost", arguments: {
            "post": BBSPost.newReply(_user.objectId, _post.objectId,
                replyTo: index > 0 ? e.objectId : "0"),
            "replyTo": e.author
          });
        },
      )));

  @override
  void initState() {
    super.initState();
    _post = widget.arguments['post'];
    _user = widget.arguments['user'];
  }
}
