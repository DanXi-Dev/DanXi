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

import 'dart:convert';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/widget/time_table/day_events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:intl/intl.dart';

double kRatio = 0.8;

/// A time table widget, usually used to show student's course schedule table.
class ScheduleView extends StatefulWidget {
  final List<DayEvents> laneEventsList;

  /// It is unused for now, do not rely on this to customize the style.
  final TimetableStyle timetableStyle;
  final TimeNow today;
  final int showingWeek;
  final OnTapCourseCallback? tapCallback;

  const ScheduleView(
      this.laneEventsList, this.timetableStyle, this.today, this.showingWeek,
      {super.key, this.tapCallback});

  @override
  ScheduleViewState createState() => ScheduleViewState();
}

class ScheduleViewState extends State<ScheduleView> {
  int _maxSlot = 0;

  @override
  Widget build(BuildContext context) {
    Widget table;
    for (var laneEvent in widget.laneEventsList) {
      for (var event in laneEvent.events) {
        _maxSlot = max(_maxSlot, event.time.slot);
      }
    }
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
    double ratio = kRatio * (DateTime.daysPerWeek + 1) / cols;

    List<Widget?> result = List.generate(
        cols * rows,
        (index) => Container(
              margin: const EdgeInsets.all(2),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                  color: Theme.of(context).hintColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(4)),
            ).withRatio(ratio).withGridPlacement(
                rowStart: index ~/ cols, columnStart: index % cols));

    // Build corner
    result[0] = const SizedBox()
        .withRatio(ratio)
        .withGridPlacement(columnStart: 0, rowStart: 0);

    // Build time indicator
    for (int slot = 0; slot <= _maxSlot; slot++) {
      String startTime = DateFormat("HH:mm")
          .format(TimeTable.kCourseSlotStartTime[slot].toExactTime());
      String endTime = DateFormat("HH:mm").format(TimeTable
          .kCourseSlotStartTime[slot]
          .toExactTime()
          .add(const Duration(minutes: TimeTable.MINUTES_OF_COURSE)));
      result[cols * (slot + 1)] = Center(
          child: Column(
        children: [
          Text((slot + 1).toString()),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              startTime,
              style:
                  TextStyle(fontSize: 10, color: Theme.of(context).hintColor),
            ),
          ),
          Text(
            endTime,
            style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor),
          )
        ],
      )).withRatio(ratio).withGridPlacement(columnStart: 0, rowStart: slot + 1);
    }

    // Build day indicator & courses
    for (int day = 0; day < widget.laneEventsList.length; day++) {
      int deltaDay = widget.laneEventsList[day].weekday -
          widget.today.weekday +
          (widget.showingWeek - widget.today.week) * 7;
      DateTime date = DateTime.now().add(Duration(days: deltaDay));
      TextStyle highlightStyle =
          TextStyle(color: Theme.of(context).colorScheme.secondary);
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
      ).withRatio(ratio).withGridPlacement(columnStart: day + 1, rowStart: 0);

      convertToBlock(widget.laneEventsList[day].events).forEach((element) {
        result[1 + day + cols * (element.firstSlot + 1)] =
            _buildScheduleBlock(element)
                .withRatio(ratio / element.slotSpan)
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

  List<ScheduleBlock> convertToBlock(List<Event> list) {
    List<ScheduleBlock> result = list.map((e) => ScheduleBlock(e)).toList();
    bool flag = true;

    bool isSameCourse(Course a, Course b) {
      if (a.courseName != b.courseName || a.roomName != b.roomName) {
        return false;
      }
      return listEquals(a.teacherNames, b.teacherNames);
    }

    while (flag) {
      flag = false;
      for (int i = 0; i < result.length;) {
        try {
          ScheduleBlock neighboringBlock = result.firstWhere((element) {
            int startSlot = element.firstSlot;
            int endSlot = startSlot + element.slotSpan;

            return isSameCourse(
                    element.event.first.course, result[i].event.first.course) &&
                ((result[i].firstSlot + result[i].slotSpan == startSlot) ||
                    (result[i].firstSlot == endSlot));
          });
          flag = true;
          ScheduleBlock thisBlock = result.removeAt(i);
          neighboringBlock.firstSlot =
              min(thisBlock.firstSlot, neighboringBlock.firstSlot);
          neighboringBlock.slotSpan += thisBlock.slotSpan;
        } catch (e) {
          ++i;
        }
      }
    }
    // Merge courses at the same time
    flag = true;
    while (flag) {
      flag = false;
      for (int i = 0; i < result.length;) {
        try {
          ScheduleBlock overlapBlock =
              result.sublist(i + 1).firstWhere((element) {
            return element.slotSpan == result[i].slotSpan &&
                element.firstSlot == result[i].firstSlot;
          });
          flag = true;
          ScheduleBlock thisBlock = result.removeAt(i);
          overlapBlock.event.addAll(thisBlock.event);
        } catch (e) {
          ++i;
        }
      }
    }

    // Change the order of courses at the same time to ensure that the first course should be
    // enabled if possible.
    for (ScheduleBlock block in result) {
      // Skip blocks that needn't be reordered
      if (block.event.first.enabled ||
          block.event.every((element) => !element.enabled)) {
        continue;
      }

      Event firstEnabledCourse =
          block.event.firstWhere((element) => element.enabled);
      block.event.remove(firstEnabledCourse);
      block.event.insert(0, firstEnabledCourse);
    }
    return result;
  }

  Widget _buildScheduleBlock(ScheduleBlock block) {
    Widget body;
    if (block.event.length > 1) {
      Course copiedCourse =
          Course.fromJson(jsonDecode(jsonEncode(block.event.first.course)));
      copiedCourse.courseName = copiedCourse.courseName! + S.current.and_more;
      body = _buildCourseBody(copiedCourse, enabled: block.event.first.enabled);
    } else {
      body = _buildCourseBody(block.event.first.course,
          enabled: block.event.first.enabled);
    }
    return InkWell(
      onTap: () => widget.tapCallback?.call(block),
      child: body,
    );
  }

  Widget _buildCourseBody(Course course, {bool enabled = true}) {
    final TextStyle? textStyle = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(
            color: Theme.of(context).colorScheme.secondary.computeLuminance() >=
                    0.5
                ? Colors.black
                : Colors.white);
    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
          color: enabled
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).hintColor,
          borderRadius: BorderRadius.circular(2)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(
            height: 2,
          ),
          AutoSizeText(course.courseName!,
              minFontSize: 12,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: textStyle?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(
            height: 4,
          ),
          AutoSizeText(course.roomName!, minFontSize: 10, style: textStyle),
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

class ScheduleBlock {
  int slotSpan = 1;
  late int firstSlot;
  late List<Event> event;

  ScheduleBlock(Event event) {
    this.event = [event];
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
    this.startHour = 0,
    this.endHour = 24,
    this.laneColor = Colors.white,
    this.cornerColor = Colors.white,
    this.timelineColor = Colors.white,
    this.timelineItemColor = Colors.white,
    this.mainBackgroundColor = Colors.white,
    this.decorationLineBorderColor = const Color(0x1A000000),
    this.timelineBorderColor = const Color(0x1A000000),
    this.timeItemTextColor = Colors.blue,
    this.laneWidth = 300,
    this.laneHeight = 70,
    this.timeItemHeight = 60,
    this.timeItemWidth = 70,
    this.decorationLineHeight = 20,
    this.decorationLineDashWidth = 9,
    this.decorationLineDashSpaceWidth = 4,
    this.visibleTimeBorder = true,
    this.visibleDecorationBorder = false,
  });
}

typedef OnTapCourseCallback = void Function(ScheduleBlock block);
