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
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/repository/table_repository.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/timetable_converter_impl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_timetable_view/flutter_timetable_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
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
    else if (PlatformX.isMaterial(context)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(outputFile.absolute.path)));
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
    PersonInfo info = Provider.of<ValueNotifier<PersonInfo>>(context)?.value;
    TimetableStyle style = TimetableStyle(
        startHour: TimeTable.COURSE_SLOT_START_TIME[0].hour,
        laneHeight: 30,
        laneWidth: 80,
        timeItemWidth: 50,
        timeItemHeight: 160);
    return FutureBuilder(
        builder: (_, AsyncSnapshot<TimeTable> snapshot) {
          if (snapshot.hasData) {
            _table = snapshot.data;
            return TimetableView(
              laneEventsList: _table.toLaneEvents(1, style),
              timetableStyle: style,
            );
          } else {
            return Container();
          }
        },
        future: TimeTableRepository.getInstance()
            .loadTimeTableLocally(info, startTime: DateTime(2021, 3, 1)));
  }

  @override
  bool get wantKeepAlive => true;
}
