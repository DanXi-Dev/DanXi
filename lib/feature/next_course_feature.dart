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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/feature/base_feature.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/table_repository.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/retryer.dart';
import 'package:dan_xi/widget/time_table/day_events.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:flutter_timetable_view/src/models/table_event_time.dart';

class NextCourseFeature extends Feature {
  LiveCourseModel _data;
  ConnectionStatus _status = ConnectionStatus.NONE;
  PersonInfo _info;

  Future<void> _loadCourse() async {
    _status = ConnectionStatus.CONNECTING;
    TimeTable timetable = await Retrier.runAsyncWithRetry(() async {
      // TODO: Sometimes the server returns a 500 error.
      // Put a delay before retrying.
      await Future.delayed(Duration(milliseconds: 100));
      return await TimeTableRepository.getInstance()
          .loadTimeTableLocally(context.personInfo);
    });
    _data = getNextCourse(timetable);
    _status = ConnectionStatus.DONE;
    notifyUpdate();
  }

  LiveCourseModel getNextCourse(TimeTable table) {
    Event thisCourse;
    Event nextCourse;
    int courseLeft = 0;
    TimeNow now = table.now();
    DayEvents dayEvents = table.toDayEvents(now.week,
        compact: TableDisplayType.FULL)[now.weekday];
    dayEvents.events.sort((a, b) => a.time.slot.compareTo(b.time.slot));
    for (var element in dayEvents.events) {
      TableEventTime startTime =
          TimeTable.kCourseSlotStartTime[element.time.slot];
      // In case that app started on the first day but the date at the moment
      // has been the second day.

      // Rebuild the TableEventTime to get the date again.
      DateTime exactStartTime =
          TableEventTime(hour: startTime.hour, minute: startTime.minute);
      if (exactStartTime.isBefore(DateTime.now()) &&
          exactStartTime
              .add(Duration(minutes: TimeTable.MINUTES_OF_COURSE))
              .isAfter(DateTime.now())) {
        thisCourse = element;
      }
      if (exactStartTime.isAfter(DateTime.now())) {
        // Only get the next course once.
        if (nextCourse == null) nextCourse = element;
        courseLeft++;
      }
    }
    return LiveCourseModel(thisCourse, nextCourse, courseLeft);
  }

  @override
  void buildFeature([Map<String, dynamic> arguments]) {
    _info = context.personInfo;
    // Only load data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_status == ConnectionStatus.NONE) {
      _loadCourse().catchError((e) {
        _status = ConnectionStatus.FAILED;
        notifyUpdate();
      });
    }
  }

  @override
  String get mainTitle => S.of(context).today_course;

  @override
  Widget get customSubtitle {
    switch (_status) {
      case ConnectionStatus.NONE:
      case ConnectionStatus.CONNECTING:
        return Text(S.of(context).loading);
      case ConnectionStatus.DONE:
        if (_data != null) {
          if (_data.nextCourse?.course?.courseName != null) {
            // TODO make it more readable (like adding a [SmallTag], etc.)
            return Text(S.of(context).next_course_is(
                _data.nextCourse?.course?.courseName, _data.courseLeft));
          } else {
            return Text(S.of(context).next_course_none);
          }
        } else {
          return null;
        }
        break;
      case ConnectionStatus.FAILED:
      case ConnectionStatus.FATAL_ERROR:
        return Text(S.of(context).failed);
    }
    return null;
  }

  void refreshData() {
    _status = ConnectionStatus.NONE;
    notifyUpdate();
  }

  @override
  Widget get icon =>
      PlatformX.isAndroid ? Icon(Icons.today) : Icon(SFSymbols.today);

  @override
  void onTap() {
    if (_data != null) {
      // Navigator.of(context)
      //     .pushNamed("/notice/aao/list", arguments: {"initialData": _data});
    } else {
      refreshData();
    }
  }

  //TODO: Show this trailing only when exams are available.
  @override
  Widget get trailing => InkWell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.text_format),
            const SizedBox(
              height: 2,
            ),
            Text(
              S.of(context).exam_schedule,
              textScaleFactor: 0.8,
            ),
          ],
        ),
        onTap: () => Navigator.of(context)
            .pushNamed('/exam/detail', arguments: {'personInfo': _info}),
      );

  @override
  bool get clickable => false;
}

class LiveCourseModel {
  Event nowCourse;
  Event nextCourse;
  int courseLeft;

  LiveCourseModel(this.nowCourse, this.nextCourse, this.courseLeft);
}
