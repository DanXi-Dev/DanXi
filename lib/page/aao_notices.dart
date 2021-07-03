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
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/fudan_aao_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/material_x.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/top_controller.dart';
import 'package:dan_xi/widget/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';

class AAONoticesList extends StatefulWidget {
  final Map<String, dynamic> arguments;

  @override
  _AAONoticesListState createState() => _AAONoticesListState();

  AAONoticesList({Key key, this.arguments});
}

class _AAONoticesListState extends State<AAONoticesList> {
  List<Notice> _data;
  int _page = 1;
  ScrollController _controller;
  ConnectionStatus _status = ConnectionStatus.NONE;
  PersonInfo _info;

  @override
  void initState() {
    super.initState();
    _data = widget.arguments['initialData'];
    _info = widget.arguments['personInfo'];
  }

  @override
  void didChangeDependencies() {
    _controller = PrimaryScrollController.of(context);
    if (_controller != null) {
      _controller.addListener(() {
        if (_controller.position.pixels ==
            _controller.position.maxScrollExtent) {
          if (_status != ConnectionStatus.CONNECTING) _loadNextPage();
        }
      });
    }
    super.didChangeDependencies();
  }

  Future<void> _loadNextPage() async {
    _status = ConnectionStatus.CONNECTING;
    List<Notice> newPage = await FudanAAORepository.getInstance().getNotices(
        FudanAAORepository.TYPE_NOTICE_ANNOUNCEMENT, _page + 1, _info);
    if (newPage != null) {
      setState(() {
        _page++;
        _data.addAll(newPage);
        _status = ConnectionStatus.DONE;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentBottomPadding: false,
      iosContentPadding: true,
      appBar: PlatformAppBarX(
          title: TopController(
        child: Text(S.of(context).fudan_aao_notices),
        controller: _controller,
      )),
      body: Column(
        children: [
          Expanded(
              child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: WithScrollbar(
                      controller: _controller,
                      child: ListView(
                        controller: _controller,
                        children: _getListWidgets(),
                      ))))
        ],
      ),
    );
  }

  List<Widget> _getListWidgets() {
    List<Widget> widgets = [];
    if (_data == null) return widgets;
    _data.forEach((Notice value) {
      widgets.add(ThemedMaterial(
          child: ListTile(
        leading: PlatformX.isAndroid
            ? Icon(Icons.info)
            : Icon(SFSymbols.info_circle_fill),
        title: Text(value.title),
        subtitle: Text(value.time),
        onTap: () => BrowserUtil.openUrl(
            value.url,
            PlatformX.isAndroid
                ? FudanAAORepository.getInstance().cookieJar
                : null), // TODO: fix this for iOS
      )));
    });

    return widgets;
  }
}
