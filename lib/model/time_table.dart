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
import 'package:dan_xi/widget/time_table/day_events.dart';
import 'package:dan_xi/widget/time_table/schedule_view.dart';
import 'package:flutter_timetable_view/flutter_timetable_view.dart';
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

part 'time_table.g.dart';

extension TableEventTimeEx on TableEventTime {
  TableEventTime addMin(int minutes) {
    DateTime time = add(Duration(minutes: minutes));
    return TableEventTime(hour: time.hour, minute: time.minute);
  }
}

abstract class TimetableConverter {
  String get fileName;

  String get mimeType;

  String convertTo(TimeTable table);
}

class Event {
  Course course;
  CourseTime time;

  Event(this.course, this.time);
}

@JsonSerializable()
class TimeTable {
  static final DateTime kMonday = DateTime.utc(2021, 3, 22);
  static const int MINUTES_OF_COURSE = 45;
  static const int MAX_WEEK = 18;
  static final List<TableEventTime> kCourseSlotStartTime = [
    TableEventTime(hour: 8, minute: 0),
    TableEventTime(hour: 8, minute: 55),
    TableEventTime(hour: 9, minute: 55),
    TableEventTime(hour: 10, minute: 50),
    TableEventTime(hour: 11, minute: 45),
    TableEventTime(hour: 13, minute: 30),
    TableEventTime(hour: 14, minute: 25),
    TableEventTime(hour: 15, minute: 25),
    TableEventTime(hour: 16, minute: 20),
    TableEventTime(hour: 17, minute: 15),
    TableEventTime(hour: 18, minute: 30),
    TableEventTime(hour: 19, minute: 25),
    TableEventTime(hour: 20, minute: 20),
    TableEventTime(hour: 21, minute: 15),
    TableEventTime(hour: 22, minute: 10),
  ];
  List<Course> courses = [];

  //First day of the term
  DateTime startTime;

  TimeTable();

  factory TimeTable.fromHtml(DateTime startTime, String tablePageSource) {
    TimeTable newTable = new TimeTable()..startTime = startTime;
    RegExp courseMatcher =
        RegExp(r'\t*activity = new.*\n(\t*index =.*\n\t*table0.*\n)*');
    for (Match matchedCourse in courseMatcher.allMatches(tablePageSource)) {
      newTable.courses.add(Course.fromHtmlPart(matchedCourse.group(0)));
    }
    return newTable;
  }

  factory TimeTable.fromJson(Map<String, dynamic> json) =>
      _$TimeTableFromJson(json);

  Map<String, dynamic> toJson() => _$TimeTableToJson(this);

  TimeNow now() {
    var diff = DateTime.now().difference(startTime);
    return TimeNow(diff.inDays ~/ 7 + 1, diff.inDays % 7);
  }

  Map<int, List<Event>> toWeekCourses(int week) {
    Map<int, List<Event>> table = Map();
    for (int i = 0; i < 7; i++) table[i] = [];

    courses.forEach((course) {
      if (course.availableWeeks.contains(week)) {
        course.times.forEach((courseTime) =>
            table[courseTime.weekDay].add(Event(course, courseTime)));
      }
    });
    return table;
  }

  /// Convert the specific [week]'s timetable to [DayEvents], usually for a [ScheduleView].
  ///
  /// If [compact], it will not add the days to [result] when no course is taken.
  List<DayEvents> toDayEvents(int week, {bool compact = true}) {
    Map<int, List<Event>> table = Map();
    List<DayEvents> result = [];
    for (int i = 0; i < 7; i++) {
      table[i] = [];
    }
    courses.forEach((course) {
      if (course.availableWeeks.contains(week)) {
        course.times.forEach((courseTime) =>
            table[courseTime.weekDay].add(Event(course, courseTime)));
      }
    });
    for (int i = 0; i < 7; i++) {
      if (!compact || table[i].isNotEmpty)
        result.add(DayEvents(
            day: DateFormat.E().format(kMonday.add(Duration(days: i))),
            events: table[i]));
    }
    return result;
  }
}

@JsonSerializable()
class Course {
  List<String> teacherIds;
  List<String> teacherNames;
  String courseId;
  String courseName;
  String roomId;
  String roomName;
  List<int> availableWeeks;
  List<CourseTime> times;

  Course();

  static List<int> _parseWeeksFromString(String weekStr) {
    List<int> availableWeeks = [];
    for (int i = 0; i < weekStr.length; i++) {
      if (weekStr[i] == '1') {
        availableWeeks.add(i);
      }
    }
    return availableWeeks;
  }

  static List<CourseTime> _parseSlotFromStrings(Iterable<RegExpMatch> times) {
    List<CourseTime> courseTimes = [];
    courseTimes.addAll(times.map((RegExpMatch e) {
      List<String> daySlot = e.group(0).trim().split("*unitCount+");
      return CourseTime(int.parse(daySlot[0]), int.parse(daySlot[1]));
    }));
    return courseTimes;
  }

  static _trimCourseName(String name) {
    name = name.trim();
    int idPos = name.lastIndexOf(RegExp(r'\(\w{4}\d{6}.?\.\d{2}\)'));
    return idPos >= 0 ? name.replaceRange(idPos, name.length, "") : name;
  }

  factory Course.fromHtmlPart(String htmlPart) {
    Course newCourse = new Course();
    RegExp infoMatcher = RegExp(r'(?<=TaskActivity\(").*(?="\))');
    RegExp timeMatcher = RegExp(r'[0-9]+\*unitCount\+[0-9]+');
    String info = infoMatcher.firstMatch(htmlPart).group(0);

    List<String> infoVarList = info.split('","');
    return newCourse
      ..teacherIds = infoVarList[0].split(",")
      ..teacherNames = infoVarList[1].split(",")
      ..courseId = infoVarList[2]
      ..courseName = _trimCourseName(infoVarList[3])
      ..roomId = infoVarList[4]
      ..roomName = infoVarList[5]
      ..availableWeeks = _parseWeeksFromString(infoVarList[6])
      ..times = _parseSlotFromStrings(timeMatcher.allMatches(htmlPart));
  }

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);

  Map<String, dynamic> toJson() => _$CourseToJson(this);
}

@JsonSerializable()
class CourseTime {
  //Monday is 0, Morning lesson is 0
  int weekDay, slot;

  CourseTime(this.weekDay, this.slot);

  factory CourseTime.fromJson(Map<String, dynamic> json) =>
      _$CourseTimeFromJson(json);

  Map<String, dynamic> toJson() => _$CourseTimeToJson(this);
}

class TimeNow {
  //First week is 1, Monday is 0
  int week, weekday;

  TimeNow(this.week, this.weekday);
}
