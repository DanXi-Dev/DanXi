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

import 'dart:async';
import 'dart:io';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/table_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/retryer.dart';
import 'package:dan_xi/util/timetable_converter_impl.dart';
import 'package:dan_xi/widget/time_table/schedule_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_timetable_view/flutter_timetable_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

class TimetableSubPage extends PlatformSubpage {
  @override
  _TimetableSubPageState createState() => _TimetableSubPageState();
}

class ShareTimetableEvent {}

class _TimetableSubPageState extends State<TimetableSubPage>
    with AutomaticKeepAliveClientMixin {
  static StreamSubscription _shareSubscription;
  Map<String, TimetableConverter> converters;
  TimeTable _table;
  TimeNow _showingTime;
  static final START_TIME = DateTime(2021, 3, 1); //TODO: Make this dynamic
  ConnectionStatus _status = ConnectionStatus.NONE;

  void _startShare(TimetableConverter converter) async {
    // Close the dialog
    Navigator.of(context).pop();

    String converted = converter.convertTo(_table);
    Directory documentDir = await getApplicationDocumentsDirectory();
    File outputFile = File(
        "${documentDir.absolute.path}/output_timetable/${converter.fileName}");
    outputFile.createSync(recursive: true);
    await outputFile.writeAsString(converted, flush: true);
    if (PlatformX.isMobile)
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
          onTap: () => _startShare(e.value),
        ),
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    converters = {S.current.share_as_ics: ICSConverter()};
    if (_shareSubscription == null) {
      _shareSubscription =
          Constant.eventBus.on<ShareTimetableEvent>().listen((_) {
        if (_table == null) return;
        showPlatformModalSheet(
            context: context,
            builder: (_) => PlatformWidget(
                  cupertino: (_, __) => CupertinoActionSheet(
                    actions: _buildShareList(),
                  ),
                  material: (_, __) => Container(
                    height: 200,
                    child: Column(children: _buildShareList()),
                  ),
                ));
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _shareSubscription.cancel();
    _shareSubscription = null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder(
        builder: (_, AsyncSnapshot<TimeTable> snapshot) {
          if (snapshot.hasData) {
            return _buildPage(snapshot.data);
          } else if (snapshot.hasError &&
              _status == ConnectionStatus.CONNECTING) {
            _status = ConnectionStatus.FAILED;
            return GestureDetector(
              onTap: () {
                _status = ConnectionStatus.NONE;
                refreshSelf();
              },
              child: Center(
                child: Text(S.of(context).failed),
              ),
            );
          } else {
            _status = ConnectionStatus.CONNECTING;
            return Container(
              child: Center(
                child: Text(S.of(context).loading),
              ),
            );
          }
        },
        future: Retrier.runAsyncWithRetry(() =>
            TimeTableRepository.getInstance().loadTimeTableLocally(
                context.personInfo,
                startTime: START_TIME)));
  }

  Widget _buildPage(TimeTable table) {
    TimetableStyle style = TimetableStyle(
        startHour: TimeTable.COURSE_SLOT_START_TIME[0].hour,
        laneHeight: 16,
        laneWidth: (MediaQuery.of(context).size.width - 50) / 5,
        timeItemWidth: 16,
        timeItemHeight: 140);
    _table = table;
    _showingTime = _table.now();
    _status = ConnectionStatus.DONE;
    return ScheduleView(
        _table.toDayEvents(_showingTime.week), style, _showingTime);
  }

  @override
  bool get wantKeepAlive => true;
}
