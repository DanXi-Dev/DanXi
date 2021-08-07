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
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/master_detail/master_detail_view.dart';
import 'package:dan_xi/model/post_tag.dart';
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:dan_xi/widget/future_widget.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/round_chip.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class BBSTagsPage extends StatefulWidget {
  final Map<String, dynamic> arguments;

  @override
  _BBSTagsPageState createState() => _BBSTagsPageState();

  BBSTagsPage({Key key, this.arguments});
}

class _BBSTagsPageState extends State<BBSTagsPage> {
  Future<List<PostTag>> _content;

  List<PostTag> tags;
  List<PostTag> filteredTags;

  FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _content = PostRepository.getInstance().loadTags();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentBottomPadding: false,
      iosContentPadding: true,
      //backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
        title: Text(S.of(context).all_tags),
      ),
      body: MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          controller: PrimaryScrollController.of(context),
          child: FutureWidget<List<PostTag>>(
            future: _content,
            successBuilder: (context, snapshot) {
              tags = snapshot.data;
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (_) {
                  if (_searchFocus.hasFocus) _searchFocus.unfocus();
                },
                child: Column(
                  children: [
                    CupertinoSearchTextField(
                      focusNode: _searchFocus,
                      onChanged: (filter) {
                        setState(() {
                          filteredTags = tags
                              .where((value) => value.name
                                  .toLowerCase()
                                  .contains(filter.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                    Wrap(
                        children: (filteredTags ?? tags)
                            .map(
                              (e) => Padding(
                                  padding: EdgeInsets.only(top: 16, right: 12),
                                  child: RoundChip(
                                    label: e.name,
                                    color: Constant.getColorFromString(e.color),
                                    onTap: () => smartNavigatorPush(
                                        context, '/bbs/discussions',
                                        arguments: {
                                          "tagFilter": e.name,
                                        }),
                                  )),
                            )
                            .toList())
                  ],
                ),
              );
            },
            errorBuilder: GestureDetector(
              child: Center(
                child: Text(S.of(context).failed),
              ),
              onTap: () {
                setState(() {
                  _content = PostRepository.getInstance().loadTags();
                });
              },
            ),
            loadingBuilder: Center(
              child: PlatformCircularProgressIndicator(),
            ),
          ),
        ),
      ),
    );
  }
}
