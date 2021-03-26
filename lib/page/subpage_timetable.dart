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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/repository/table_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_timetable_view/flutter_timetable_view.dart';
import 'package:provider/provider.dart';

class TimetableSubPage extends PlatformSubpage {
  @override
  _TimetableSubPageState createState() => _TimetableSubPageState();
}

class ShareTimetableEvent {}

class _TimetableSubPageState extends State<TimetableSubPage>
    with AutomaticKeepAliveClientMixin {
  static StreamSubscription _shareSubscription;

  List<Widget> _buildShareList() {
    return [];
  }

  @override
  void initState() {
    super.initState();
    if (_shareSubscription == null) {
      _shareSubscription = Constant.eventBus
          .on<ShareTimetableEvent>()
          .listen((_) => showPlatformModalSheet(
              context: context,
              builder: (_) => Container(
                    height: 200,
                    child: Column(children: _buildShareList()),
                  )));
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
    return FutureBuilder(
        builder: (_, AsyncSnapshot<TimeTable> snapshot) => snapshot.hasData
            ? TimetableView(
                laneEventsList: snapshot.data.toLaneEvents(
                    1, TimetableStyle(laneHeight: 30, laneWidth: 80)),
                timetableStyle: TimetableStyle(
                    startHour: TimeTable.COURSE_SLOT_START_TIME[0].hour,
                    laneHeight: 30,
                    laneWidth: 80,
                    timeItemWidth: 50,
                    timeItemHeight: 160),
              )
            : Container(),
        future: TimeTableRepository.getInstance().loadTimeTableLocally(info));
  }

  @override
  bool get wantKeepAlive => true;
}
