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
  final ScrollController? controller;

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
        _maxSlot = max(_maxSlot, element.time.slot!);
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
      // Build weekday indicators
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
        // Build course blocks
        bool notFirstCourse = widget.laneEventsList[day].events.any((element) =>
            element.time.slot == event.time.slot! - 1 &&
            element.course.courseName == event.course.courseName);
        bool notLastCourse = widget.laneEventsList[day].events.any((element) =>
            element.time.slot == event.time.slot! + 1 &&
            element.course.courseName == event.course.courseName);
        result[1 + day + cols * (event.time.slot! + 1)] =
            _buildCourse(event.course, !notFirstCourse, !notLastCourse);
      });
    }

    return result;
  }

  /// Build a course block according to its position. To be specific, [isFirst] means if [course] is
  /// the start of a continuous course block, and [isLast] means whether [course] is the last one or not.
  /// They controls the margin and border of layout returned, in order to show a continuous style block all together.
  ///
  /// Note: It is likely to meet with
  /// layout overflow (A RenderFlex overflowed by ** pixels on the bottom.).
  /// But we have not found a better way to solve so. After all, it won't break the layout on most
  /// devices with a properly large screen.
  Widget _buildCourse(Course course, bool isFirst, bool isLast) {
    bool noBottomSpace = (isFirst && !isLast) || (!isFirst && !isLast);
    bool noTopSpace = (!isFirst && isLast) || (!isFirst && !isLast);
    final TextStyle textStyle = Theme.of(context).textTheme.overline!.copyWith(
        color: Theme.of(context).accentColorBrightness == Brightness.light
            ? Colors.black
            : Colors.white);
    return SizedBox(
      width: widget.timetableStyle.laneWidth,
      height: widget.timetableStyle.timeItemHeight,
      child: Container(
        margin: EdgeInsets.fromLTRB(
            2, noTopSpace ? 0 : 2, 2, noBottomSpace ? 0 : 2),
        padding: EdgeInsets.all(2),
        decoration: BoxDecoration(
            color: Theme.of(context).accentColor,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(noTopSpace ? 0 : 2),
                bottom: Radius.circular(noBottomSpace ? 0 : 2))),
        child: isFirst
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(course.courseName!,
                      minFontSize: 6,
                      style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 4,
                  ),
                  AutoSizeText(course.roomName!,
                      minFontSize: 6, style: textStyle),
                ],
              )
            : Container(),
      ),
    );
  }
}

class TimetableStyle {
  final int? startHour;

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
