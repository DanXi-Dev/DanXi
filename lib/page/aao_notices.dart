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
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/fudan_aao_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/material_x.dart';
import 'package:dan_xi/widget/paged_listview.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/top_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A list page showing AAO notices.
///
/// Arguments:
/// [List<Notice>] initialData: the initial data to be shown as soon as the page's displayed.
class AAONoticesList extends StatefulWidget {
  final Map<String, dynamic> arguments;

  @override
  _AAONoticesListState createState() => _AAONoticesListState();

  AAONoticesList({Key key, this.arguments});
}

class _AAONoticesListState extends State<AAONoticesList> {
  List<Notice> _data;
  ScrollController _controller;
  PersonInfo _info;

  @override
  void initState() {
    super.initState();
    _data = widget.arguments['initialData'];
    _info = StateProvider.personInfo.value;
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentBottomPadding: false,
      iosContentPadding: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
          title: TopController(
        child: Text(S.of(context).fudan_aao_notices),
        controller: _controller,
      )),
      body: Column(
        children: [
          Expanded(
              child: PagedListView<Notice>(
            withScrollbar: true,
            scrollController: PrimaryScrollController.of(context),
            builder: (_, __, ___, Notice value) {
              return ThemedMaterial(
                  child: ListTile(
                leading: PlatformX.isMaterial(context)
                    ? Icon(Icons.info)
                    : Icon(CupertinoIcons.info_circle_fill),
                title: Text(value.title),
                subtitle: Text(value.time),
                onTap: () async => BrowserUtil.openUrl(
                    value.url,
                    context,
                    PlatformX.isIOS
                        ? null
                        : await FudanAAORepository.getInstance()
                            .thisCookies), // TODO: fix this for iOS
              ));
            },
            loadingBuilder: (_) => Center(
              child: PlatformCircularProgressIndicator(),
            ),
            endBuilder: (_) => Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(S.of(context).end_reached),
                const SizedBox(
                  height: 16,
                )
              ],
            ),
            initialData: _data,
            dataReceiver: (index) => FudanAAORepository.getInstance()
                .getNotices(FudanAAORepository.TYPE_NOTICE_ANNOUNCEMENT,
                    index + 1, _info),
          ))
        ],
      ),
    );
  }
}
