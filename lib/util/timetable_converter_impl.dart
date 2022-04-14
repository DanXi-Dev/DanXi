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
          calendar.addElement(IEvent(
              status: IEventStatus.CONFIRMED,
              classification: IClass.PUBLIC,
              description: event.course.teacherNames!.join(","),
              location: event.course.roomName ?? "",
              summary: event.course.courseName ?? "",
              start: table.startDate!.add(Duration(
                  days: 7 * (weekNum - 1) + day,
                  hours: TimeTable.kCourseSlotStartTime[event.time.slot].hour!,
                  minutes:
                      TimeTable.kCourseSlotStartTime[event.time.slot].minute!)),
              end: table.startDate!
                  .add(Duration(
                      days: 7 * (weekNum - 1) + day,
                      hours:
                          TimeTable.kCourseSlotStartTime[event.time.slot].hour!,
                      minutes: TimeTable
                          .kCourseSlotStartTime[event.time.slot].minute!))
                  .add(const Duration(minutes: TimeTable.MINUTES_OF_COURSE))));
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
