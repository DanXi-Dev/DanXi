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

import 'package:dan_xi/model/time_table.dart';
import 'package:ical/serializer.dart';

class ICSConverter extends TimetableConverter {
  /// Convert [table] to .ics format string
  @override
  String convertTo(TimeTable? table) {
    ICalendar calendar = ICalendar(company: 'DanXi', lang: "CN");
    for (int weekNum = 0; weekNum <= 24; weekNum++) {
      Map<int, List<Event>> weekTable = table!.toWeekCourses(weekNum);
      for (int day = 0; day < 7; day++) {
        for (var event in weekTable[day]!) {
          final startDate = table.startDate!.add(Duration(
              days: 7 * (weekNum - 1) + day,
              hours: TimeTable.kCourseSlotStartTime[event.time.slot].hour!,
              minutes:
                  TimeTable.kCourseSlotStartTime[event.time.slot].minute!));
          final endDate = startDate
              .add(const Duration(minutes: TimeTable.MINUTES_OF_COURSE));
          calendar.addElement(IEvent(
              status: IEventStatus.CONFIRMED,
              classification: IClass.PUBLIC,
              description: event.course.teacherNames!.join(","),
              location: event.course.roomName ?? "",
              summary: event.course.courseName ?? "",
              // toUtc: https://github.com/DanXi-Dev/DanXi/issues/522
              start: startDate.toUtc(),
              end: endDate.toUtc()));
        }
      }
    }
    return calendar.serialize();
  }

  @override
  String get fileName => "timetable.ics";

  @override
  String get mimeType => "text/calendar";
}

class CSVConverter extends TimetableConverter {
  void addCourse(int weekDay, int startSlot, int endSlot, Course course,
      StringBuffer csv) {
    String courseName = course.courseName ?? '无';
    String teacher = course.teacherNames?.join('、') ?? '无';
    String room = course.roomName ?? '无';
    String weeks = course.availableWeeks?.join('、') ?? '';
    weekDay += 1; // Change to 1-7
    startSlot += 1; // Change to 1-12
    endSlot += 1; // Change to 1-12
    csv.writeln(
        "$courseName,$weekDay,$startSlot,$endSlot,$teacher,$room,$weeks");
  }

  /// Convert [table] to .csv format string
  @override
  String convertTo(TimeTable? table) {
    StringBuffer csv = StringBuffer();
    csv.writeln("课程名称,星期,开始节数,结束节数,老师,地点,周数");
    for (Course course in table!.courses!) {
      // Sort by weekDay first, then by slot
      course.times!.sort((a, b) {
        if (a.weekDay != b.weekDay) {
          return a.weekDay.compareTo(b.weekDay);
        }
        return a.slot.compareTo(b.slot);
      });

      int? currentDay;
      int? startSlot;
      int? prevSlot;

      for (var t in course.times!) {
        if (currentDay == null) {
          // First entry initialization
          currentDay = t.weekDay;
          startSlot = t.slot;
          prevSlot = t.slot;
        } else if (t.weekDay != currentDay) {
          // Switched to a new day, close the previous day’s block
          addCourse(currentDay, startSlot!, prevSlot!, course, csv);
          currentDay = t.weekDay;
          startSlot = t.slot;
          prevSlot = t.slot;
        } else if (t.slot == prevSlot! + 1) {
          // Consecutive slot, extend the current block
          prevSlot = t.slot;
        } else {
          // Not consecutive, close the current block and start a new one
          addCourse(currentDay, startSlot!, prevSlot, course, csv);
          startSlot = t.slot;
          prevSlot = t.slot;
        }
      }

      // Close the last block if any
      if (currentDay != null) {
        addCourse(currentDay, startSlot!, prevSlot!, course, csv);
      }
    }
    return csv.toString();
  }

  @override
  String get fileName => "timetable.csv";

  @override
  String get mimeType => "text/csv";
}

/*
class CalendarImporter extends TimetableConverter {
  /// Import [table] directly into system calendar without exporting any files.
  @override
  String? convertTo(TimeTable? table) {
    for (int weekNum = 0; weekNum <= 24; weekNum++) {
      Map<int, List<Event>> weekTable = table!.toWeekCourses(weekNum);
      for (int day = 0; day < 7; day++) {
        for (var event in weekTable[day]!) {
          final Add2Calendar.Event e = Add2Calendar.Event(
              title: event.course.courseName ?? "",
              description: event.course.teacherNames!.join(","),
              location: event.course.roomName ?? "",
              startDate: table.startDate!.add(Duration(
                  days: 7 * (weekNum - 1) + day,
                  hours: TimeTable.kCourseSlotStartTime[event.time.slot].hour!,
                  minutes:
                      TimeTable.kCourseSlotStartTime[event.time.slot].minute!)),
              endDate: table.startDate!
                  .add(Duration(
                      days: 7 * (weekNum - 1) + day,
                      hours:
                          TimeTable.kCourseSlotStartTime[event.time.slot].hour!,
                      minutes: TimeTable
                          .kCourseSlotStartTime[event.time.slot].minute!))
                  .add(const Duration(minutes: TimeTable.MINUTES_OF_COURSE)));
          Add2Calendar.Add2Calendar.addEvent2Cal(e);
        }
      }
    }
    Add2Calendar.Add2Calendar.commit();
    return null;
  }

  @override
  String? get fileName => null;

  @override
  String? get mimeType => null;
}*/
