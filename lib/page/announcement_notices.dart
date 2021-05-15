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
import 'package:dan_xi/model/announcement.dart';
import 'package:dan_xi/repository/announcement_repository.dart';
import 'package:dan_xi/util/human_duration.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/future_widget.dart';
import 'package:dan_xi/widget/material_x.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/top_controller.dart';
import 'package:dan_xi/widget/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:dan_xi/public_extension_methods.dart';

class AnnouncementList extends StatefulWidget {
  final Map<String, dynamic> arguments;

  @override
  _AnnouncementListState createState() => _AnnouncementListState();

  AnnouncementList({Key key, this.arguments});
}

class _AnnouncementListState extends State<AnnouncementList> {
  List<Announcement> _data = [];
  ScrollController _controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _controller = PrimaryScrollController.of(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentBottomPadding: true,
      iosContentPadding: true,
      appBar: PlatformAppBarX(
          title: TopController(
        child: Text(S.of(context).developer_announcement('')),
        controller: _controller,
      )),
      body: FutureWidget(
        future: AnnouncementRepository.getInstance().getAnnouncements(),
        successBuilder: (_, snapShot) {
          _data = snapShot.data;
          return Column(
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
          );
        },
        loadingBuilder: Container(
            child: Center(
          child: Text(S.of(context).loading),
        )),
        errorBuilder: GestureDetector(
          onTap: () {
            refreshSelf();
          },
          child: Center(
            child: Text(S.of(context).failed),
          ),
        ),
      ),
    );
  }

  List<Widget> _getListWidgets() {
    List<Widget> widgets = [];
    if (_data == null) return widgets;
    _data.forEach((Announcement value) {
      widgets.add(ThemedMaterial(
          child: ListTile(
        leading: PlatformX.isAndroid
            ? Icon(Icons.info)
            : Icon(SFSymbols.info_circle_fill),
        title: Text(
          value.content,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
            HumanDuration.format(context, DateTime.tryParse(value.updatedAt))),
        onTap: () => showPlatformDialog(
            context: context,
            builder: (BuildContext context) => PlatformAlertDialog(
                  title: Text(
                      S.of(context).developer_announcement(value.createdAt)),
                  content: Text(value.content),
                  actions: <Widget>[
                    PlatformDialogAction(
                        child: PlatformText(S.of(context).i_see),
                        onPressed: () => Navigator.pop(context)),
                  ],
                )),
      )));
    });

    return widgets;
  }
}
