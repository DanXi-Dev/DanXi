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

import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/widget/time_table/day_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// A time table widget, usually used to show student's course schedule table.
class ScheduleView extends StatefulWidget {
  final List<DayEvents> laneEventsList;
  final TimetableStyle timetableStyle;
  final TimeNow today;
  final int showingWeek;
  final ScrollController controller;

  ScheduleView(this.laneEventsList, this.timetableStyle, this.today,
      this.showingWeek, this.controller);

  @override
  _ScheduleViewState createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  int _maxSlot = 0;

  @override
  Widget build(BuildContext context) {
    Widget table;
    table = GridView.count(
        crossAxisCount: widget.laneEventsList.length + 1,
        children: _buildTable(),
        controller: widget.controller,
        childAspectRatio: 0.8,
        shrinkWrap: true);
    return MediaQuery.removePadding(
        context: context, removeTop: true, child: table);
  }

  List<Widget> _buildTable() {
    widget.laneEventsList.forEach((element) {
      element.events.forEach((element) {
        _maxSlot = max(_maxSlot, element.time.slot);
      });
    });
    int cols = widget.laneEventsList.length + 1, rows = _maxSlot + 2;
    List<Widget> result = List.filled(
        cols * rows,
        SizedBox(
          width: widget.timetableStyle.laneWidth,
          height: widget.timetableStyle.timeItemHeight,
          child: Container(
            margin: EdgeInsets.all(2),
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(4)),
          ),
        ));

    // Build corner
    result[0] = SizedBox(
      width: widget.timetableStyle.timeItemWidth,
      height: widget.timetableStyle.laneHeight,
    );

    // Build time indicator
    for (int slot = 0; slot <= _maxSlot; slot++) {
      String startTime = DateFormat("HH:mm")
          .format(TimeTable.kCourseSlotStartTime[slot].toExactTime());
      String endTime = DateFormat("HH:mm").format(TimeTable
          .kCourseSlotStartTime[slot]
          .toExactTime()
          .add(Duration(minutes: TimeTable.MINUTES_OF_COURSE)));
      result[cols * (slot + 1)] = SizedBox(
        width: widget.timetableStyle.timeItemWidth,
        height: widget.timetableStyle.timeItemHeight,
        child: Center(
            child: Column(
          children: [
            Text((slot + 1).toString()),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Text(
                startTime,
                style:
                    TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
              ),
            ),
            Text(
              endTime,
              style:
                  TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
            )
          ],
        )),
      );
    }

    // Build day indicator & courses
    for (int day = 0; day < widget.laneEventsList.length; day++) {
      int deltaDay = widget.laneEventsList[day].weekday -
          widget.today.weekday +
          (widget.showingWeek - widget.today.week) * 7;
      DateTime date = DateTime.now().add(Duration(days: deltaDay));
      TextStyle highlightStyle =
          TextStyle(color: Theme.of(context).accentColor);
      result[1 + day] = SizedBox(
        width: widget.timetableStyle.laneWidth,
        height: widget.timetableStyle.laneHeight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              deltaDay == 0
                  ? Text(
                      widget.laneEventsList[day].day,
                      style: highlightStyle,
                    )
                  : Text(
                      widget.laneEventsList[day].day,
                    ),
              deltaDay == 0
                  ? Text(
                      DateFormat.Md().format(date),
                      style: highlightStyle,
                    )
                  : Text(DateFormat.Md().format(date))
            ],
          ),
        ),
      );

      widget.laneEventsList[day].events.forEach((Event event) {
        result[1 + day + cols * (event.time.slot + 1)] = SizedBox(
          width: widget.timetableStyle.laneWidth,
          height: widget.timetableStyle.timeItemHeight,
          child: Container(
            margin: EdgeInsets.all(2),
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
                color: Theme.of(context).accentColor,
                borderRadius: BorderRadius.circular(4)),
            child: AutoSizeText(
                event.course.courseName + '\n' + event.course.roomName,
                minFontSize: 8,
                style: Theme.of(context).textTheme.overline.copyWith(
                    color: Theme.of(context).accentColorBrightness ==
                        Brightness.light
                        ? Colors.black
                        : Colors.white)),
          ),
        );
      });
    }

    return result;
  }
}

class TimetableStyle {
  final int startHour;

  final int endHour;

  final Color laneColor;

  final Color cornerColor;

  final Color timeItemTextColor;

  final Color timelineColor;

  final Color timelineItemColor;

  final Color mainBackgroundColor;

  final Color timelineBorderColor;

  final Color decorationLineBorderColor;

  final double laneWidth;

  final double laneHeight;

  final double timeItemHeight;

  final double timeItemWidth;

  final double decorationLineHeight;

  final double decorationLineDashWidth;

  final double decorationLineDashSpaceWidth;

  final bool visibleTimeBorder;

  final bool visibleDecorationBorder;

  const TimetableStyle({
    this.startHour: 0,
    this.endHour: 24,
    this.laneColor: Colors.white,
    this.cornerColor: Colors.white,
    this.timelineColor: Colors.white,
    this.timelineItemColor: Colors.white,
    this.mainBackgroundColor: Colors.white,
    this.decorationLineBorderColor: const Color(0x1A000000),
    this.timelineBorderColor: const Color(0x1A000000),
    this.timeItemTextColor: Colors.blue,
    this.laneWidth: 300,
    this.laneHeight: 70,
    this.timeItemHeight: 60,
    this.timeItemWidth: 70,
    this.decorationLineHeight: 20,
    this.decorationLineDashWidth: 9,
    this.decorationLineDashSpaceWidth: 4,
    this.visibleTimeBorder: true,
    this.visibleDecorationBorder: false,
  });
}