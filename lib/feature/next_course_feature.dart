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
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/fdu/time_table_repository.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/retrier.dart';
import 'package:dan_xi/util/vague_time.dart';
import 'package:dan_xi/widget/time_table/day_events.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NextCourseFeature extends Feature {
  @override
  bool get loadOnTap => false;

  LiveCourseModel? _data;
  ConnectionStatus _status = ConnectionStatus.NONE;

  Future<void> _loadCourse() async {
    _status = ConnectionStatus.CONNECTING;
    TimeTable? timetable = await Retrier.runAsyncWithRetry(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      return await TimeTableRepository.getInstance()
          .loadTimeTable(StateProvider.personInfo.value);
    });
    _data = getNextCourse(timetable!);
    _status = ConnectionStatus.DONE;
    notifyUpdate();
  }

  LiveCourseModel getNextCourse(TimeTable table) {
    Event? thisCourse;
    Event? nextCourse;
    int courseLeft = 0;
    TimeNow now = table.now();
    DayEvents dayEvents = table.toDayEvents(now.week,
        compact: TableDisplayType.FULL)[now.weekday];
    dayEvents.events.sort((a, b) => a.time.slot.compareTo(b.time.slot));
    for (var element in dayEvents.events) {
      VagueTime startTime = TimeTable.kCourseSlotStartTime[element.time.slot];
      DateTime exactStartTime = startTime.toExactTime();
      if (exactStartTime.isBefore(DateTime.now()) &&
          exactStartTime
              .add(const Duration(minutes: TimeTable.MINUTES_OF_COURSE))
              .isAfter(DateTime.now())) {
        thisCourse = element;
      }
      if (exactStartTime.isAfter(DateTime.now())) {
        // Only get the next course once.
        nextCourse ??= element;
        courseLeft++;
      }
    }
    return LiveCourseModel(thisCourse, nextCourse, courseLeft);
  }

  @override
  void buildFeature([Map<String, dynamic>? arguments]) {
    // Only load data once.
    // If user needs to refresh the data, [refreshSelf()] will be called on the whole page,
    // not just FeatureContainer. So the feature will be recreated then.
    if (_status == ConnectionStatus.NONE) {
      _loadCourse().catchError((error) {
        _status = ConnectionStatus.FAILED;
        notifyUpdate();
      });
    }
  }

  @override
  String get mainTitle => S.of(context!).today_course;

  @override
  Widget? get customSubtitle {
    switch (_status) {
      case ConnectionStatus.NONE:
      case ConnectionStatus.CONNECTING:
        return Text(S.of(context!).loading);
      case ConnectionStatus.DONE:
        if (_data != null) {
          if (_data!.nextCourse?.course.courseName != null) {
            return Text(S.of(context!).next_course_is(
                _data!.nextCourse?.course.courseName ?? "", _data!.courseLeft));
          } else {
            return Text(S.of(context!).next_course_none);
          }
        } else {
          return null;
        }
      case ConnectionStatus.FAILED:
      case ConnectionStatus.FATAL_ERROR:
        return Text(S.of(context!).failed);
    }
  }

  void refreshData() {
    _status = ConnectionStatus.NONE;
    notifyUpdate();
  }

  @override
  Widget get icon => PlatformX.isMaterial(context!)
      ? const Icon(Icons.today)
      : const Icon(CupertinoIcons.today);

  @override
  void onTap() {
    refreshData();
  }

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
              S.of(context!).exam_schedule,
              textScaler: TextScaler.linear(0.8),
            ),
          ],
        ),
        onTap: () => smartNavigatorPush(context!, '/exam/detail'),
      );

  @override
  bool get clickable => false;
}

class LiveCourseModel {
  Event? nowCourse;
  Event? nextCourse;
  int courseLeft;

  LiveCourseModel(this.nowCourse, this.nextCourse, this.courseLeft);
}
