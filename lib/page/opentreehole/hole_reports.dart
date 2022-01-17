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

import 'dart:async';

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/opentreehole/hole.dart';
import 'package:dan_xi/model/opentreehole/report.dart';
import 'package:dan_xi/page/opentreehole/hole_detail.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/human_duration.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/top_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';

/// A list page showing the reports for administrators.
class BBSReportDetail extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const BBSReportDetail({Key? key, this.arguments}) : super(key: key);

  @override
  _BBSReportDetailState createState() => _BBSReportDetailState();
}

class _BBSReportDetailState extends State<BBSReportDetail> {
  final PagedListViewController<OTReport> _listViewController =
      PagedListViewController();

  /// Reload/load the (new) content and set the [_content] future.
  Future<List<OTReport>?> _loadContent(int page) async {
    return await OpenTreeHoleRepository.getInstance().adminGetReports();
  }

  @override
  void initState() {
    super.initState();
  }

  /// Rebuild everything and refresh itself.
  void refreshSelf({scrollToEnd = false}) {
    if (scrollToEnd) _listViewController.queueScrollToEnd();
    _listViewController.notifyUpdate(useInitialData: false);
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      material: (_, __) =>
          MaterialScaffoldData(resizeToAvoidBottomInset: false),
      cupertino: (_, __) =>
          CupertinoPageScaffoldData(resizeToAvoidBottomInset: false),
      iosContentPadding: false,
      iosContentBottomPadding: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PlatformAppBarX(
        title: TopController(
          controller: PrimaryScrollController.of(context),
          child: const Text("Reports"),
        ),
        trailingActions: const [],
      ),
      body: Builder(
        // The builder widget updates context so that MediaQuery below can use the correct context (that is, Scaffold considered)
        builder: (context) => RefreshIndicator(
          edgeOffset: MediaQuery.of(context).padding.top,
          color: Theme.of(context).colorScheme.secondary,
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            refreshSelf();
          },
          child: Material(
              child: PagedListView<OTReport>(
            startPage: 1,
            pagedController: _listViewController,
            withScrollbar: true,
            scrollController: PrimaryScrollController.of(context),
            dataReceiver: _loadContent,
            builder: _getListItems,
            loadingBuilder: (BuildContext context) => Container(
              padding: const EdgeInsets.all(8),
              child: Center(child: PlatformCircularProgressIndicator()),
            ),
            endBuilder: (context) => Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(S.of(context).end_reached),
              ),
            ),
          )),
        ),
      ),
    );
  }

  _buildContextMenu(BuildContext context, OTReport e) => [
        /*PlatformWidget(
          cupertino: (_, __) => CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              OpenTreeHoleRepository.getInstance()
                  .adminSetReportDealt(e.report_id);
            },
            child: Text("Mark as dealt"),
          ),
          material: (_, __) => ListTile(
            title: Text("Mark as dealt"),
            onTap: () {
              Navigator.of(context).pop();
              OpenTreeHoleRepository.getInstance()
                  .adminSetReportDealt(e.report_id);
            },
          ),
        ),*/
      ];

  Widget _getListItems(BuildContext context,
      ListProvider<OTReport> dataProvider, int index, OTReport e) {
    onLinkTap(url) {
      BrowserUtil.openUrl(url!, context);
    }

    onImageTap(url) {
      smartNavigatorPush(context, '/image/detail', arguments: {'url': url});
    }

    return GestureDetector(
      onLongPress: () {
        showPlatformModalSheet(
            context: context,
            builder: (BuildContext context) => PlatformWidget(
                  cupertino: (_, __) => CupertinoActionSheet(
                    actions: _buildContextMenu(context, e),
                    cancelButton: CupertinoActionSheetAction(
                      child: Text(S.of(context).cancel),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  material: (_, __) => SizedBox(
                    height: 300,
                    child: Column(
                      children: _buildContextMenu(context, e),
                    ),
                  ),
                ));
      },
      child: Card(
        child: ListTile(
            dense: true,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                    alignment: Alignment.topLeft,
                    child:
                        smartRender(context, e.reason!, onLinkTap, onImageTap)),
                const Divider(),
                Align(alignment: Alignment.topLeft, child: Text(e.content!)),
                //smartRender(e.content, onLinkTap, onImageTap)),
              ],
            ),
            subtitle: Column(children: [
              const SizedBox(
                height: 8,
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                  "#${e.hole_id} (##${e.floor?.floor_id})",
                  style: TextStyle(
                      color: Theme.of(context).hintColor, fontSize: 12),
                ),
                Text(
                  HumanDuration.tryFormat(
                      context, DateTime.parse(e.time_created!)),
                  style: TextStyle(
                      color: Theme.of(context).hintColor, fontSize: 12),
                ),
                /*GestureDetector(
                  child: Text("Mark as dealt",
                      style: TextStyle(
                          color: Theme.of(context).hintColor, fontSize: 12)),
                  onTap: () {
                    OpenTreeHoleRepository.getInstance()
                        .adminSetReportDealt(e.report_id);
                  },
                ),*/
              ]),
            ]),
            onTap: () async {
              ProgressFuture progressDialog = showProgressDialog(
                  loadingText: S.of(context).loading, context: context);
              try {
                final OTHole post = await OpenTreeHoleRepository.getInstance()
                    .loadSpecificHole(e.hole_id!);
                smartNavigatorPush(context, "/bbs/postDetail", arguments: {
                  "post": post,
                });
                progressDialog.dismiss();
              } catch (error) {
                progressDialog.dismiss();
                Noticing.showNotice(context, error.toString(),
                    title: S.of(context).fatal_error);
              }
            }),
      ),
    );
  }
}
