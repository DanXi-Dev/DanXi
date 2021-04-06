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
import 'package:dan_xi/repository/fudan_aao_repository.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:url_launcher/url_launcher.dart';

class AAONoticesList extends StatefulWidget {
  final Map<String, dynamic> arguments;

  @override
  _AAONoticesListState createState() => _AAONoticesListState();

  AAONoticesList({Key key, this.arguments});
}

class _AAONoticesListState extends State<AAONoticesList> {
  List<Notice> _data;
  int _page = 1;
  ScrollController _controller = ScrollController();
  ConnectionStatus _status = ConnectionStatus.NONE;

  @override
  void initState() {
    super.initState();
    _data = widget.arguments['initialData'];
    _controller.addListener(() {
      if (_controller.position.pixels == _controller.position.maxScrollExtent) {
        if (_status != ConnectionStatus.CONNECTING) _loadNextPage();
      }
    });
  }

  Future<void> _loadNextPage() async {
    _status = ConnectionStatus.CONNECTING;
    List<Notice> newPage = await FudanAAORepository.getInstance()
        .getNotices(FudanAAORepository.TYPE_NOTICE_ANNOUNCEMENT, _page + 1);
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
      iosContentBottomPadding: true,
      iosContentPadding: true,
      appBar: PlatformAppBar(title: Text(S.of(context).fudan_aao_notices)),
      body: Column(
        children: [
          Expanded(
              child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: Scrollbar(
                      interactive: PlatformX.isDesktop,
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
      widgets.add(Material(
          color: isCupertino(context) ? Colors.white : null,
          child: ListTile(
            leading: PlatformX.isAndroid ? Icon(Icons.info) : Icon(SFSymbols.info_circle_fill),
            title: Text(value.title),
            subtitle: Text(value.time),
            onTap: () => launch(value.url),
          )));
    });

    return widgets;
  }
}
