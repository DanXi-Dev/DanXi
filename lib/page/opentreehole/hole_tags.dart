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
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/opentreehole/tag.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/lazy_future.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:dan_xi/widget/opentreehole/bbs_tags_container.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A list page showing all tags in the forum.
class BBSTagsPage extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  @override
  _BBSTagsPageState createState() => _BBSTagsPageState();

  BBSTagsPage({Key? key, this.arguments});
}

class _BBSTagsPageState extends State<BBSTagsPage> {
  Future<List<OTTag>?>? _content;

  @override
  void initState() {
    super.initState();
    _content = LazyFuture.pack(OpenTreeHoleRepository.getInstance().loadTags());
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentBottomPadding: false,
      iosContentPadding: false,
      appBar: PlatformAppBarX(
        title: Text(S.of(context).all_tags),
      ),
      body: SafeArea(
        child: WithScrollbar(
          controller: PrimaryScrollController.of(context),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            primary: true,
            child: FutureWidget<List<OTTag>?>(
              future: _content,
              successBuilder: (context, snapshot) => BBSTagsContainer(
                tags: snapshot.data,
                onTap: (e) =>
                    smartNavigatorPush(context, '/bbs/discussions', arguments: {
                  "tagFilter": e.name,
                }),
              ),
              errorBuilder: GestureDetector(
                child: Center(
                  child: Text(S.of(context).failed),
                ),
                onTap: () {
                  setState(() => _content = LazyFuture.pack(
                      OpenTreeHoleRepository.getInstance().loadTags()));
                },
              ),
              loadingBuilder: Center(
                child: PlatformCircularProgressIndicator(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
