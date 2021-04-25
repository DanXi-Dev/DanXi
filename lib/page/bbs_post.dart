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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/post.dart';
import 'package:dan_xi/model/reply.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:dan_xi/util/human_duration.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/bbs_editor.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/top_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  ScrollController _controller = ScrollController();
  int _currentPage;
  List<Widget> _previousWidgets;
  bool _isRefreshing;
  bool _isEndReached;
  static const POST_COUNT_PER_PAGE = 10;

  @override
  void initState() {
    super.initState();
    _post = widget.arguments['post'];
    
    _currentPage = 1;
    _previousWidgets = [];
    _isRefreshing = true;
    _isEndReached = false;

    if (_controller != null) {
      // Over-scroll event
      _controller.addListener(() {
        if (_controller.offset >= _controller.position.maxScrollExtent &&
            !_isRefreshing && !_isEndReached) {
          _isRefreshing = true;
          setState(() {
            _currentPage++;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
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
              BBSEditor.createNewReply(context, _post.id, null);
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
              child: PrimaryScrollController(
                controller: _controller,
                child:
                    FutureBuilder(
                        builder: (_, AsyncSnapshot<List<Reply>> snapshot) {
                          switch (snapshot.connectionState) {
                            case ConnectionState.none:
                            case ConnectionState.waiting:
                            case ConnectionState.active:
                              _isRefreshing = true;
                              return ListView.builder(
                                  primary: true,
                                  itemBuilder: (context, index) =>
                                      _buildListItem(null, index),
                                  itemCount: _previousWidgets.length + 1,
                              );
                              break;
                            case ConnectionState.done:
                              _isRefreshing = false;
                              print(_previousWidgets.length);
                              if (snapshot.hasError) {
                                return _buildErrorWidget();
                              } else {
                                var l = snapshot.data;
                                return  ListView.builder(
                                        primary: true,
                                        itemBuilder: (context, index) =>
                                            _buildListItem(l, index),
                                        itemCount: l.length + (_currentPage - 1) * POST_COUNT_PER_PAGE);
                              }
                              break;
                          }
                          return null;
                        },
                        future: PostRepository.getInstance().loadReplies(_post, _currentPage)),
              )
          )),
    );
  }

  Widget _buildListItem(List<Reply> e, int index) {
    if (e != null) {
      //print("DEBUG: e.length ${e.length} , index is ${index}");
      if (e.length > index % POST_COUNT_PER_PAGE) {
        _previousWidgets.add(_getListItem(e[index % POST_COUNT_PER_PAGE], index % POST_COUNT_PER_PAGE));
      }
      else {
        // end reached
        _isEndReached = true;
        return Column(
          children: [
            Divider(),
            Text(S.of(context).end_reached),
          ],
        );
      }
    }
    if (index >= _previousWidgets.length) return GestureDetector(child: Center(child: CircularProgressIndicator()),);
    return _previousWidgets[index];
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
    return list;
  }

  Widget _getListItem(Reply e, int index) => Material(
          //color: PlatformX.backgroundColor(context),
          child: GestureDetector(
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
            //margin: EdgeInsets.fromLTRB(10,8,10,8),
            child: ListTile(
          dense: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 8,
              ),
              if (index == 0)
                Row(
                  children: _generateTagWidgets(_post),
                ),
              Align(
                alignment: Alignment.topLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    e.reply_to == null
                        ? Column()
                        : Text(S.of(context).reply_to(e.reply_to),
                            style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).accentColor)),
                    /*Text("#${e.id}",
                        style: TextStyle(
                            fontSize: 10, color: Theme.of(context).hintColor)),*/
                  ],
                ),
              ),
              Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    "[${e.username}]",
                  ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: HtmlWidget(
                  e.content,
                  textStyle: TextStyle(fontSize: 16),
                  onTapUrl: (url) => launch(url),
                ),
              ),
            ],
          ),
          subtitle: Column(children: [
            const SizedBox(
              height: 12,
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                "#${e.id}",
                style:
                    TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
              ),
              Text(
                HumanDuration.format(context, DateTime.parse(e.date_created)),
                style:
                    TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
              ),
              TextButton(
                  onPressed: () {
                    BBSEditor.reportPost(context, e.id);
                  },
                  child: Text(S.of(context).report, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12))
              ),
            ]),
          ]),
          onTap: () {
             BBSEditor.createNewReply(context, _post.id, e.id);
          },
        )),
      ));

  List<Widget> _generateTagWidgets(BBSPost e) {
    List<Widget> _tags = [
      const SizedBox(
        width: 2,
      ),
    ];
    e.tag.forEach((element) {
      _tags.add(Container(
        padding: EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: Constant.getColorFromString(element.color),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
          //color: Constant.getColorFromString(element.color).withAlpha(25),
        ),
        child: Text(
          element.name,
          style: TextStyle(
              fontSize: 14,
              color: Constant.getColorFromString(element
                  .color) //.computeLuminance() <= 0.5 ? Colors.black : Colors.white,
              ),
        ),
      ));
      _tags.add(const SizedBox(
        width: 6,
      ));
    });
    return _tags;
  }
}
