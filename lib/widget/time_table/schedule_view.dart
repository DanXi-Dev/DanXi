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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget table;
    widget.laneEventsList.forEach((element) {
      element.events.forEach((element) {
        _maxSlot = max(_maxSlot, element.time.slot);
      });
    });
    int cols = widget.laneEventsList.length + 1, rows = _maxSlot + 2;
    table = LayoutGrid(
      columnSizes: List.filled(cols, 1.fr),
      rowSizes: List.filled(rows, auto),
      children: _buildTable(cols, rows),
    );
    return MediaQuery.removePadding(
        context: context, removeTop: true, child: table);
  }

  List<Widget> _buildTable(int cols, int rows) {
    List<Widget?> result = List.generate(
        cols * rows,
        (index) => Container(
              margin: EdgeInsets.all(2),
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                  color: Theme.of(context).hintColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(4)),
            ).withRatio(0.8).withGridPlacement(
                rowStart: index ~/ cols, columnStart: index % cols));

    // Build corner
    result[0] = Container()
        .withRatio(0.8)
        .withGridPlacement(columnStart: 0, rowStart: 0);

    // Build time indicator
    for (int slot = 0; slot <= _maxSlot; slot++) {
      String startTime = DateFormat("HH:mm")
          .format(TimeTable.kCourseSlotStartTime[slot].toExactTime());
      String endTime = DateFormat("HH:mm").format(TimeTable
          .kCourseSlotStartTime[slot]
          .toExactTime()
          .add(Duration(minutes: TimeTable.MINUTES_OF_COURSE)));
      result[cols * (slot + 1)] = Center(
          child: Column(
        children: [
          Text((slot + 1).toString()),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Text(
              startTime,
              style:
                  TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
            ),
          ),
          Text(
            endTime,
            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
          )
        ],
      )).withRatio(0.8).withGridPlacement(columnStart: 0, rowStart: slot + 1);
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
      result[1 + day] = Center(
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
      ).withRatio(0.8).withGridPlacement(columnStart: day + 1, rowStart: 0);
      convertToBlock(widget.laneEventsList[day].events).forEach((element) {
        result[1 + day + cols * (element.firstSlot + 1)] =
            _buildCourse(element.event.course)
                .withRatio(0.8 / element.slotSpan)
                .withGridPlacement(
                    columnStart: 1 + day,
                    rowStart: element.firstSlot + 1,
                    rowSpan: element.slotSpan);
        for (int j = 1; j < element.slotSpan; j++) {
          result[1 + day + cols * (element.firstSlot + 1 + j)] = null;
        }
      });
    }
    result.removeWhere((element) => element == null);
    return result.map((e) => e!).toList();
  }

  List<_ScheduleBlock> convertToBlock(List<Event> list) {
    List<_ScheduleBlock> result = list.map((e) => _ScheduleBlock(e)).toList();
    bool flag = true;
    while (flag) {
      flag = false;
      for (int i = 0; i < result.length;) {
        try {
          _ScheduleBlock neighboringBlock = result.firstWhere((element) {
            int startSlot = element.firstSlot;
            int endSlot = startSlot + element.slotSpan;

            return element.event.course.courseName ==
                    result[i].event.course.courseName &&
                ((result[i].firstSlot + result[i].slotSpan == startSlot) ||
                    (result[i].firstSlot == endSlot));
          });
          flag = true;
          _ScheduleBlock thisBlock = result.removeAt(i);
          neighboringBlock.firstSlot =
              min(thisBlock.firstSlot, neighboringBlock.firstSlot);
          neighboringBlock.slotSpan += thisBlock.slotSpan;
        } catch (e) {
          ++i;
        }
      }
    }
    return result;
  }

  Widget _buildCourse(Course course) {
    final TextStyle? textStyle = Theme.of(context).textTheme.overline?.copyWith(
        color: Theme.of(context).accentColorBrightness == Brightness.light
            ? Colors.black
            : Colors.white);
    return Container(
      margin: EdgeInsets.all(2),
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
          color: Theme.of(context).accentColor,
          borderRadius: BorderRadius.circular(2)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 2,
          ),
          AutoSizeText(course.courseName!,
              minFontSize: 10,
              style: textStyle?.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(
            height: 4,
          ),
          AutoSizeText(course.roomName!, minFontSize: 8, style: textStyle),
        ],
      ),
    );
  }
}

extension WidgetEx on Widget {
  Widget withRatio(double aspectRatio) => AspectRatio(
        aspectRatio: aspectRatio,
        child: this,
      );
}

class _ScheduleBlock {
  int slotSpan = 1;
  late int firstSlot;
  late Event event;

  _ScheduleBlock(Event event) {
    this.event = event;
    firstSlot = event.time.slot;
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
