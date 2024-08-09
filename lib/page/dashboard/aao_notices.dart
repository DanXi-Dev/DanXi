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
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/fdu/aao_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/top_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A list page showing AAO notices.
///
/// Arguments:
/// [List<Notice>] initialData: the initial data to be shown as soon as the page's displayed.
class AAONoticesList extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  @override
  AAONoticesListState createState() => AAONoticesListState();

  const AAONoticesList({super.key, this.arguments});
}

class AAONoticesListState extends State<AAONoticesList> {
  List<Notice>? _data;
  ScrollController? _controller;

  @override
  void initState() {
    super.initState();
    _data = widget.arguments!['initialData'];
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentBottomPadding: false,
      iosContentPadding: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
          title: TopController(
        controller: _controller,
        child: Text(S.of(context).fudan_aao_notices),
      )),
      body: Column(
        children: [
          Expanded(
              child: PagedListView<Notice>(
            withScrollbar: true,
            scrollController: PrimaryScrollController.of(context),
            builder: (_, __, ___, Notice value) => ListTile(
              leading: PlatformX.isMaterial(context)
                  ? const Icon(Icons.info)
                  : const Icon(CupertinoIcons.info_circle_fill),
              title: Text(value.title),
              subtitle: Text(value.time),
              onTap: () => BrowserUtil.openUrl(value.url, context, null, true),
            ),
            loadingBuilder: (_) => Center(
              child: PlatformCircularProgressIndicator(),
            ),
            endBuilder: (_) => Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(S.of(context).end_reached),
                const SizedBox(height: 16)
              ],
            ),
            initialData: _data,
            startPage: 1,
            dataReceiver: (index) => FudanAAORepository.getInstance()
                .getNotices(FudanAAORepository.TYPE_NOTICE_ANNOUNCEMENT, index,
                    StateProvider.personInfo.value),
          ))
        ],
      ),
    );
  }
}
