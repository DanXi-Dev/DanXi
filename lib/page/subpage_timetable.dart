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

import 'dart:io';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/common/feature_registers.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/bbs/post_repository.dart';
import 'package:dan_xi/repository/table_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/retryer.dart';
import 'package:dan_xi/util/scroller_fix/primary_scroll_page.dart';
import 'package:dan_xi/util/stream_listener.dart';
import 'package:dan_xi/util/timetable_converter_impl.dart';
import 'package:dan_xi/util/viewport_utils.dart';
import 'package:dan_xi/widget/future_widget.dart';
import 'package:dan_xi/widget/time_table/day_events.dart';
import 'package:dan_xi/widget/time_table/schedule_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

const kCompatibleUserGroup = [UserGroup.FUDAN_STUDENT];

class TimetableSubPage extends PlatformSubpage
    with PageWithPrimaryScrollController {
  @override
  bool get needPadding => false;

  @override
  _TimetableSubPageState createState() => _TimetableSubPageState();

  @override
  String get debugTag => "TimetablePage";
}

class ShareTimetableEvent {}

class _TimetableSubPageState extends State<TimetableSubPage>
    with AutomaticKeepAliveClientMixin {
  final StateStreamListener _shareSubscription = StateStreamListener();
  final ScrollController _dummyScrollController = ScrollController();

  /// A map of all converters.
  ///
  /// A converter is to export the time table as a single file, e.g. .ics.
  Map<String, TimetableConverter> converters;

  /// The time table it fetched.
  TimeTable _table;

  ///The week it's showing on the time table.
  TimeNow _showingTime;

  Future _content;

  bool _loadFromRemote = false;

  void _setContent() {
    if (checkGroup(kCompatibleUserGroup))
      _content = Retrier.runAsyncWithRetry(() =>
          TimeTableRepository.getInstance().loadTimeTableLocally(
              StateProvider.personInfo.value,
              forceLoadFromRemote: _loadFromRemote));
    else
      _content = Future<TimeTable>.error(
          NotLoginError("Haven't logged in as FDU student."));
  }

  void _startShare(TimetableConverter converter) async {
    // Close the dialog
    Navigator.of(context).pop();

    String converted = converter.convertTo(_table);
    Directory documentDir = await getApplicationDocumentsDirectory();
    File outputFile = PlatformX.createPlatformFile(
        "${documentDir.absolute.path}/output_timetable/${converter.fileName}");
    outputFile.createSync(recursive: true);
    await outputFile.writeAsString(converted, flush: true);
    if (PlatformX.isIOS)
      OpenFile.open(outputFile.absolute.path, type: converter.mimeType);
    else if (PlatformX.isAndroid)
      Share.shareFiles([outputFile.absolute.path],
          mimeTypes: [converter.mimeType]);
    else {
      Noticing.showNotice(context, outputFile.absolute.path);
    }
  }

  List<Widget> _buildShareList() {
    return converters.entries
        .map<Widget>((MapEntry<String, TimetableConverter> e) {
      return PlatformWidget(
        cupertino: (_, __) => CupertinoActionSheetAction(
          onPressed: () => _startShare(e.value),
          child: Text(e.key),
        ),
        material: (_, __) => ListTile(
          title: Text(e.key),
          subtitle: Text(e.value.fileName),
          onTap: () => _startShare(e.value),
        ),
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    converters = {S.current.share_as_ics: ICSConverter()};
    _shareSubscription.bindOnlyInvalid(
        Constant.eventBus.on<ShareTimetableEvent>().listen((_) {
          if (_table == null) return;
          showPlatformModalSheet(
              context: context,
              builder: (_) => PlatformWidget(
                    cupertino: (_, __) => CupertinoActionSheet(
                      actions: _buildShareList(),
                      cancelButton: CupertinoActionSheetAction(
                        child: Text(S.of(context).cancel),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    material: (_, __) => Container(
                      height: 200,
                      child: Column(children: _buildShareList()),
                    ),
                  ));
        }),
        hashCode);
  }

  void refreshSelf() {
    setState(() {
      _setContent();
    });
  }

  @override
  void didChangeDependencies() {
    _setContent();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant TimetableSubPage oldWidget) {
    _setContent();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
    if (_shareSubscription != null) _shareSubscription.cancel();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureWidget(
      successBuilder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return _buildPage(snapshot.data);
      },
      future: _content,
      errorBuilder: (_, snapShot) => GestureDetector(
        onTap: () {
          _loadFromRemote = true;
          refreshSelf();
        },
        child: Center(
          child: Text(S.of(context).failed),
        ),
      ),
      loadingBuilder: Center(
        child: PlatformCircularProgressIndicator(),
      ),
    );
  }

  goToPrev() {
    setState(() {
      _showingTime.week--;
    });
  }

  goToNext() {
    setState(() {
      _showingTime.week++;
    });
  }

  Widget _buildPage(TimeTable table) {
    TimetableStyle style = TimetableStyle(
        startHour: TimeTable.kCourseSlotStartTime[0].hour,
        laneHeight: 16,
        laneWidth: (ViewportUtils.getMainNavigatorWidth(context) - 50) / 5,
        timeItemWidth: 16,
        timeItemHeight: 140);
    _table = table;
    if (_showingTime == null) _showingTime = _table.now();
    List<DayEvents> scheduleData = _table.toDayEvents(_showingTime.week,
        compact: TableDisplayType.STANDARD);
    return RefreshIndicator(
      color: Theme.of(context).accentColor,
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        refreshSelf();
      },
      child: ListView(
        // This ListView is a workaround, so that we can apply a custom scroll physics to it.
        controller: _dummyScrollController,
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PlatformIconButton(
                icon: Icon(Icons.chevron_left),
                onPressed: _showingTime.week > 0 ? goToPrev : null,
              ),
              Text(S.of(context).week(_showingTime.week)),
              PlatformIconButton(
                icon: Icon(Icons.chevron_right),
                onPressed:
                _showingTime.week < TimeTable.MAX_WEEK ? goToNext : null,
              )
            ],
          ),
          ScheduleView(scheduleData, style, _table.now(), _showingTime.week,
              widget.primaryScrollController(context)),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
