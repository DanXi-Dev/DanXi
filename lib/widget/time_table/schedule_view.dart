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

import 'dart:math';

import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/time_table/day_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_timetable_view/flutter_timetable_view.dart';
import 'package:intl/intl.dart';

class ScheduleView extends StatefulWidget {
  final List<DayEvents> laneEventsList;
  final TimetableStyle timetableStyle;
  final TimeNow today;

  ScheduleView(this.laneEventsList, this.timetableStyle, this.today);

  @override
  _ScheduleViewState createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  int _maxSlot = 0;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: widget.laneEventsList.length + 1,
      children: _buildTable(),
    );
  }

  List<Widget> _buildTable() {
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
                //color: PlatformX.isDarkMode(context) ? Colors.black12 : Colors.white,
                color: Theme.of(context).hoverColor,
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
      result[cols * (slot + 1)] = SizedBox(
        width: widget.timetableStyle.timeItemWidth,
        height: widget.timetableStyle.timeItemHeight,
        child: Center(
          child: Text((slot + 1).toString()),
        ),
      );
    }

    // Build day indicator & courses
    for (int day = 0; day < widget.laneEventsList.length; day++) {
      int deltaDay = day - widget.today.weekday;
      DateTime date = DateTime.now().add(Duration(days: deltaDay));
      TextStyle highlightStyle = TextStyle(color: Theme.of(context).accentColor);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.course.courseName, style: Theme.of(context).textTheme.overline.copyWith(fontSize: 11, color: Theme.of(context).accentColorBrightness == Brightness.light ? Colors.black : Colors.white)),
                Text(event.course.roomName, style: Theme.of(context).textTheme.overline.copyWith(fontSize: 10, color: Theme.of(context).accentColorBrightness == Brightness.light ? Colors.black : Colors.white)),
                //Text(event.course.roomId, style: Theme.of(context).textTheme.overline.copyWith(fontSize: 10, color: Theme.of(context).accentColorBrightness == Brightness.light ? Colors.black : Colors.white)),
            ]),
          ),
        );
      });
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    widget.laneEventsList.forEach((element) {
      element.events.forEach((element) {
        _maxSlot = max(_maxSlot, element.time.slot);
      });
    });
  }
}
