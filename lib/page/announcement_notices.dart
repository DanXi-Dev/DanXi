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
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/announcement_repository.dart';
import 'package:dan_xi/util/human_duration.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/future_widget.dart';
import 'package:dan_xi/widget/material_x.dart';
import 'package:dan_xi/widget/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';

/// A list page showing announcement from developers.
class AnnouncementList extends StatefulWidget {
  final Map<String, dynamic> arguments;

  @override
  _AnnouncementListState createState() => _AnnouncementListState();

  AnnouncementList({Key key, this.arguments});
}

class _AnnouncementListState extends State<AnnouncementList> {
  List<Announcement> _data = [];
  bool _showingLatest = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentBottomPadding: true,
      iosContentPadding: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
        title: Text(
          S.of(context).developer_announcement(''),
        ),
        trailingActions: [
          PlatformIconButton(
            padding: EdgeInsets.zero,
            icon: Text(
              _showingLatest
                  ? S.of(context).older_announcement
                  : S.of(context).latest_announcement,
              softWrap: true,
              textScaleFactor: 1.2,
            ),
            onPressed: () => setState(() => _showingLatest = !_showingLatest),
          )
        ],
      ),
      body: FutureWidget(
        future: _showingLatest
            ? AnnouncementRepository.getInstance().getAnnouncements()
            : AnnouncementRepository.getInstance().getAllAnnouncements(),
        successBuilder: (_, snapShot) {
          _data = snapShot.data;
          return Column(
            children: [
              Expanded(
                  child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: WithScrollbar(
                          controller: PrimaryScrollController.of(context),
                          child: ListView(
                            children: _getListWidgets(),
                          ))))
            ],
          );
        },
        loadingBuilder: Container(
          child: Center(child: PlatformCircularProgressIndicator()),
        ),
        errorBuilder: (_, snapShot) => GestureDetector(
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
