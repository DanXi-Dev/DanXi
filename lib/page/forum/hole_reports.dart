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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/forum/audit.dart';
import 'package:dan_xi/model/forum/floor.dart';
import 'package:dan_xi/model/forum/hole.dart';
import 'package:dan_xi/model/forum/report.dart';
import 'package:dan_xi/page/forum/hole_detail.dart';
import 'package:dan_xi/page/subpage_forum.dart';
import 'package:dan_xi/repository/forum/forum_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/forum/human_duration.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dan_xi/widget/libraries/platform_app_bar_ex.dart';
import 'package:dan_xi/widget/libraries/platform_context_menu.dart';
import 'package:dan_xi/widget/libraries/top_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:intl/intl.dart';
import 'package:lazy_load_indexed_stack/lazy_load_indexed_stack.dart';

/// A list page showing the reports for administrators.
class BBSReportDetail extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const BBSReportDetail({super.key, this.arguments});

  @override
  BBSReportDetailState createState() => BBSReportDetailState();
}

class BBSReportDetailState extends State<BBSReportDetail> {
  final PagedListViewController<OTReport> _reportListViewController =
      PagedListViewController();

  int _tabIndex = 1;

  /// Reload/load the (new) content and set the [_content] future.
  Future<List<OTReport>?> _loadReportContent(int page) =>
      ForumRepository.getInstance().adminGetReports(page * 10, 10);

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
          child: Text(S.of(context).reports),
        )),
        body: SafeArea(
            bottom: false,
            child: StatefulBuilder(
              // The builder widget updates context so that MediaQuery below can use the correct context (that is, Scaffold considered)
              builder: (context, setState) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: CupertinoSlidingSegmentedControl<int>(
                      onValueChanged: (int? value) {
                        setState(() {
                          _tabIndex = value!;
                        });
                      },
                      groupValue: _tabIndex,
                      children: ["Report", "Audit", "Audit (dealt)"]
                          .map((t) => Text(t))
                          .toList()
                          .asMap(),
                    ),
                  ),
                  Expanded(
                    child: LazyLoadIndexedStack(index: _tabIndex, children: [
                      _buildReportPage(),
                      const AuditList(true),
                      const AuditList(false)
                    ]),
                  ),
                ],
              ),
            )));
  }

  Widget _buildReportPage() => RefreshIndicator(
        edgeOffset: MediaQuery.of(context).padding.top,
        color: Theme.of(context).colorScheme.secondary,
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await _reportListViewController.notifyUpdate(
              useInitialData: false, queueDataClear: false);
        },
        child: PagedListView<OTReport>(
          startPage: 0,
          pagedController: _reportListViewController,
          withScrollbar: true,
          scrollController: PrimaryScrollController.of(context),
          dataReceiver: _loadReportContent,
          builder: _getReportListItems,
          loadingBuilder: (BuildContext context) => Container(
            padding: const EdgeInsets.all(8),
            child: Center(child: PlatformCircularProgressIndicator()),
          ),
          emptyBuilder: (context) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(S.of(context).no_data),
            ),
          ),
          endBuilder: (context) => Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(S.of(context).end_reached),
            ),
          ),
        ),
      );

  List<Widget> _buildReportContextMenu(
          BuildContext pageContext, BuildContext menuContext, OTReport e) =>
      [
        PlatformContextMenuItem(
          menuContext: menuContext,
          child: const Text("Mark as dealt"),
          onPressed: () async {
            int? result = await ForumRepository.getInstance()
                .adminSetReportDealt(e.report_id!);
            if (result != null && result < 300 && mounted) {
              Noticing.showModalNotice(pageContext,
                  message: S.of(pageContext).operation_successful);
              await _reportListViewController.notifyUpdate(
                  useInitialData: false, queueDataClear: false);
            }
          },
        )
      ];

  Widget _getReportListItems(BuildContext context,
      ListProvider<OTReport> dataProvider, int index, OTReport e) {
    void onLinkTap(String? url) {
      BrowserUtil.openUrl(url!, context);
    }

    void onImageTap(String? url, Object heroTag) {
      smartNavigatorPush(context, '/image/detail', arguments: {
        'preview_url': url,
        'hd_url':
            ForumRepository.getInstance().extractHighDefinitionImageUrl(url!),
        'hero_tag': heroTag
      });
    }

    return GestureDetector(
      onLongPress: () {
        showPlatformModalSheet(
            context: context,
            builder: (BuildContext cxt) => PlatformContextMenu(
                  actions: _buildReportContextMenu(context, cxt, e),
                  cancelButton: CupertinoActionSheetAction(
                    child: Text(S.of(cxt).cancel),
                    onPressed: () => Navigator.of(cxt).pop(),
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
                    child: smartRender(
                        context, e.reason!, onLinkTap, onImageTap, false)),
                const Divider(),
                Align(
                    alignment: Alignment.topLeft,
                    child: Text(e.floor?.content ?? "?", maxLines: 5)),
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
                GestureDetector(
                  child: Text("Mark as dealt",
                      style: TextStyle(
                          color: Theme.of(context).hintColor, fontSize: 12)),
                  onTap: () async {
                    int? result = await ForumRepository.getInstance()
                        .adminSetReportDealt(e.report_id!);
                    if (result != null && result < 300 && mounted) {
                      Noticing.showModalNotice(context,
                          message: S.of(context).operation_successful);
                      await _reportListViewController.notifyUpdate(
                          useInitialData: false, queueDataClear: false);
                    }
                  },
                ),
              ]),
            ]),
            onTap: () async {
              ProgressFuture progressDialog = showProgressDialog(
                  loadingText: S.of(context).loading, context: context);
              try {
                final OTHole? post = await ForumRepository.getInstance()
                    .loadHoleById(e.hole_id!);
                if (!mounted) return;
                smartNavigatorPush(context, "/bbs/postDetail",
                    arguments: {"post": post!, "locate": e.floor});
              } catch (error, st) {
                Noticing.showErrorDialog(context, error, trace: st);
              } finally {
                progressDialog.dismiss(showAnim: false);
              }
            }),
      ),
    );
  }
}

class AuditList extends StatefulWidget {
  final bool open;

  const AuditList(this.open, {super.key});

  @override
  AuditListState createState() => AuditListState();
}

class AuditListState extends State<AuditList> {
  final PagedListViewController<OTAudit> _auditListViewController =
      PagedListViewController();
  final ScrollController _auditScrollController = ScrollController();
  final TimeBasedLoadAdaptLayer<OTAudit> auditAdaptLayer =
      TimeBasedLoadAdaptLayer(Constant.POST_COUNT_PER_PAGE, 0);
  DateTime _startDateTime = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDateTime) {
      setState(() {
        _startDateTime = picked.copyWith(hour: 23, minute: 59, second: 59);
      });
      await _auditListViewController.notifyUpdate(
          useInitialData: false, queueDataClear: false);
    }
  }

  Future<List<OTAudit>?> _loadAuditContent(
      int page, bool open, DateTime startDate) async {
    List<OTAudit>? loadedAuditFloors = await auditAdaptLayer
        .generateReceiver(_auditListViewController, (lastElement) async {
      DateTime time = startDate;
      if (lastElement != null) {
        time = DateTime.parse(lastElement.time_created!);
      }
      return ForumRepository.getInstance()
          .adminGetAuditFloors(time, open, Constant.POST_COUNT_PER_PAGE);
    }).call(page);
    // If not more posts, notify ListView that we reached the end.
    if (loadedAuditFloors?.isEmpty ?? false) return [];
    return loadedAuditFloors;
  }

  List<Widget> _buildAuditContextMenu(
          BuildContext pageContext, BuildContext menuContext, OTAudit e) =>
      [
        PlatformContextMenuItem(
          menuContext: menuContext,
          child: const Text("标记为敏感"),
          onPressed: () async {
            int? result = await ForumRepository.getInstance()
                .adminSetAuditFloor(e.id, true);
            if (result != null && result < 300 && mounted) {
              Noticing.showModalNotice(pageContext,
                  message: S.of(pageContext).operation_successful);
              _auditListViewController.replaceDatumWith(e, e.processed());
            }
          },
        ),
        PlatformContextMenuItem(
          menuContext: menuContext,
          child: const Text("标记为不敏感"),
          onPressed: () async {
            int? result = await ForumRepository.getInstance()
                .adminSetAuditFloor(e.id, false);
            if (result != null && result < 300 && mounted) {
              Noticing.showModalNotice(pageContext,
                  message: S.of(pageContext).operation_successful);
              _auditListViewController.replaceDatumWith(e, e.processed());
            }
          },
        )
      ];

  String processStringForAudit(String content, String? detail) {
    if (detail == null) {
      return content;
    }
    // Workaround for flutter_markdown not supporting \n\n inside tags
    while (content.contains('\n\n')) {
      content = content.replaceAll('\n\n', '\n');
    }
    while (detail!.contains('\n\n')) {
      detail = detail.replaceAll('\n\n', '\n');
    }
    // New audit data with labels
    if (detail[0] == '{' && detail.contains('\n')) {
      final int sepLabelIndex = detail.indexOf('\n');
      final String detailContent = detail.substring(sepLabelIndex + 1);
      final int matchIndex = content.indexOf(detailContent);
      if (matchIndex != -1) {
        final String sensitiveLabel = detail.substring(0, sepLabelIndex);
        final String prefix = content.substring(0, matchIndex);
        final String suffix =
            content.substring(matchIndex + detailContent.length);
        return '<audit>$sensitiveLabel</audit>\n$prefix<audit>$detailContent</audit>$suffix';
      }
      // Old data without labels
    } else {
      final int matchIndex = content.indexOf(detail);
      if (matchIndex != -1) {
        final String prefix = content.substring(0, matchIndex);
        final String suffix = content.substring(matchIndex + detail.length);
        return '$prefix<audit>$detail</audit>$suffix';
      }
    }
    return '<audit>$detail</audit>\n$content';
  }

  Widget _getAuditFloorsListItems(BuildContext context,
      ListProvider<OTAudit> dataProvider, int index, OTAudit e) {
    void onLinkTap(String? url) {
      BrowserUtil.openUrl(url!, context);
    }

    void onImageTap(String? url, Object heroTag) {
      smartNavigatorPush(context, '/image/detail', arguments: {
        'preview_url': url,
        'hd_url':
            ForumRepository.getInstance().extractHighDefinitionImageUrl(url!),
        'hero_tag': heroTag
      });
    }

    return GestureDetector(
      onLongPress: () {
        showPlatformModalSheet(
            context: context,
            builder: (BuildContext cxt) => PlatformContextMenu(
                  actions: _buildAuditContextMenu(context, cxt, e),
                  cancelButton: CupertinoActionSheetAction(
                    child: Text(S.of(cxt).cancel),
                    onPressed: () => Navigator.of(cxt).pop(),
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
                      child: smartRender(
                          context,
                          processStringForAudit(e.content, e.sensitive_detail),
                          onLinkTap,
                          onImageTap,
                          false)),
                  const Divider(),
                ],
              ),
              subtitle: Column(children: [
                const SizedBox(
                  height: 8,
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "#${e.hole_id} (##${e.id})",
                        style: TextStyle(
                            color: Theme.of(context).hintColor, fontSize: 12),
                      ),
                      Text(
                        HumanDuration.tryFormat(
                            context, DateTime.parse(e.time_created!)),
                        style: TextStyle(
                            color: Theme.of(context).hintColor, fontSize: 12),
                      ),
                      if (e.is_actual_sensitive != null)
                        Text(
                          e.is_actual_sensitive!
                              ? "Sensitive"
                              : "Not Sensitive",
                          style: TextStyle(
                              color: Theme.of(context).hintColor, fontSize: 12),
                        )
                    ]),
              ]),
              onTap: () async {
                ProgressFuture progressDialog = showProgressDialog(
                    loadingText: S.of(context).loading, context: context);
                try {
                  final OTHole? post = await ForumRepository.getInstance()
                      .loadHoleById(e.hole_id);
                  final OTFloor? floor = await ForumRepository.getInstance()
                      .loadFloorById(e.id);
                  if (!mounted) return;
                  smartNavigatorPush(context, "/bbs/postDetail",
                      arguments: {"post": post!, "locate": floor!});
                } catch (error, st) {
                  Noticing.showErrorDialog(context, error, trace: st);
                } finally {
                  progressDialog.dismiss(showAnim: false);
                }
              })),
    );
  }

  Widget _getDatePicker(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      PlatformElevatedButton(
          onPressed: () => _selectDate(context),
          child: const Text("Select Date")),
      Text(DateFormat('yyyy-MM-dd').format(_startDateTime))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      edgeOffset: MediaQuery.of(context).padding.top,
      color: Theme.of(context).colorScheme.secondary,
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await _auditListViewController.notifyUpdate(
            useInitialData: false, queueDataClear: false);
      },
      child: PagedListView<OTAudit>(
        startPage: 0,
        pagedController: _auditListViewController,
        withScrollbar: true,
        scrollController: _auditScrollController,
        dataReceiver: (page) =>
            _loadAuditContent(page, widget.open, _startDateTime),
        builder: _getAuditFloorsListItems,
        headBuilder: _getDatePicker,
        loadingBuilder: (BuildContext context) => Container(
          padding: const EdgeInsets.all(8),
          child: Center(child: PlatformCircularProgressIndicator()),
        ),
        emptyBuilder: (context) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(S.of(context).no_data),
          ),
        ),
        endBuilder: (context) => Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(S.of(context).end_reached),
          ),
        ),
      ),
    );
  }
}
