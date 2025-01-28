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
import 'package:dan_xi/repository/app/announcement_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/lazy_future.dart';
import 'package:dan_xi/util/forum/human_duration.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/linkify_x.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/with_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A list page showing announcement from developers.
class AnnouncementList extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  @override
  AnnouncementListState createState() => AnnouncementListState();

  const AnnouncementList({super.key, this.arguments});
}

class AnnouncementListState extends State<AnnouncementList> {
  List<Announcement> _data = [];
  bool _showingLatest = true;
  late Future<bool?> _future;

  @override
  void initState() {
    super.initState();
    _future = LazyFuture.pack(
        AnnouncementRepository.getInstance().loadAnnouncements());
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      iosContentBottomPadding: false,
      iosContentPadding: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
        title: Text(S.of(context).developer_announcement('')),
        trailingActions: [
          PlatformIconButton(
            padding: EdgeInsets.zero,
            icon: Text(
              _showingLatest
                  ? S.of(context).older_announcement
                  : S.of(context).latest_announcement,
              softWrap: true,
              textScaler: MediaQuery.textScalerOf(context),
            ),
            onPressed: () => setState(() => _showingLatest = !_showingLatest),
          )
        ],
      ),
      body: FutureWidget<bool?>(
        future: _future,
        successBuilder: (_, snapShot) {
          _data = _showingLatest
              ? AnnouncementRepository.getInstance().getAnnouncements() ?? []
              : AnnouncementRepository.getInstance().getAllAnnouncements() ??
                  [];
          return Column(
            children: [
              Expanded(
                  child: WithScrollbar(
                      controller: PrimaryScrollController.of(context),
                      child: ListView(
                        children: _getListWidgets(),
                      )))
            ],
          );
        },
        loadingBuilder: Center(child: PlatformCircularProgressIndicator()),
        errorBuilder: (BuildContext context, AsyncSnapshot<bool?> snapShot) =>
            ErrorPageWidget.buildWidget(context, snapShot.error,
                stackTrace: snapShot.stackTrace, onTap: () => refreshSelf()),
      ),
    );
  }

  List<Widget> _getListWidgets() {
    List<Widget> widgets = [];
    for (var value in _data) {
      widgets.add(ListTile(
        leading: PlatformX.isMaterial(context)
            ? const Icon(Icons.info)
            : const Icon(CupertinoIcons.info_circle_fill),
        title: Text(
          value.content!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(HumanDuration.tryFormat(
            context, DateTime.tryParse(value.updatedAt!)!)),
        onTap: () => showPlatformDialog(
            context: context,
            builder: (BuildContext context) => PlatformAlertDialog(
                  title: Text(S
                      .of(context)
                      .developer_announcement(value.createdAt ?? "")),
                  content: SingleChildScrollView(
                    child: LinkifyX(
                      text: value.content!,
                      onOpen: (element) =>
                          BrowserUtil.openUrl(element.url, context),
                    ),
                  ),
                  actions: <Widget>[
                    PlatformDialogAction(
                        child: PlatformText(S.of(context).i_see),
                        onPressed: () => Navigator.pop(context)),
                  ],
                )),
      ));
    }

    return widgets;
  }
}
