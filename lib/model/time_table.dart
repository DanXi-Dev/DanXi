// @dart=2.9

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
import 'package:dan_xi/util/vague_time.dart';
import 'package:dan_xi/widget/time_table/day_events.dart';
import 'package:dan_xi/widget/time_table/schedule_view.dart';
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

part 'time_table.g.dart';

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
  /// Start time of the term.
  static DateTime defaultStartTime = DateTime(2021, 3, 1);

  static final DateTime kMonday = DateTime(2021, 3, 22);
  static const int MINUTES_OF_COURSE = 45;
  static const int MAX_WEEK = 18;
  static final List<VagueTime> kCourseSlotStartTime = [
    VagueTime(hour: 8, minute: 0),
    VagueTime(hour: 8, minute: 55),
    VagueTime(hour: 9, minute: 55),
    VagueTime(hour: 10, minute: 50),
    VagueTime(hour: 11, minute: 45),
    VagueTime(hour: 13, minute: 30),
    VagueTime(hour: 14, minute: 25),
    VagueTime(hour: 15, minute: 25),
    VagueTime(hour: 16, minute: 20),
    VagueTime(hour: 17, minute: 15),
    VagueTime(hour: 18, minute: 30),
    VagueTime(hour: 19, minute: 25),
    VagueTime(hour: 20, minute: 20),
    VagueTime(hour: 21, minute: 15),
    VagueTime(hour: 22, minute: 10),
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
    DateTime now = DateTime.now();
    Duration diff = now.difference(startTime);
    int slot = -1;
    for (int i = 0; i < kCourseSlotStartTime.length; i++) {
      if (now.isAfter(kCourseSlotStartTime[i].toExactTime())) {
        slot = i;
      }
    }
    return TimeNow(diff.inDays ~/ 7 + 1, diff.inDays % 7, slot);
  }

  static TimeNow defaultNow() {
    DateTime now = DateTime.now();
    Duration diff = now.difference(defaultStartTime);
    int slot = -1;
    for (int i = 0; i < kCourseSlotStartTime.length; i++) {
      if (now.isAfter(kCourseSlotStartTime[i].toExactTime())) {
        slot = i;
      }
    }
    return TimeNow(diff.inDays ~/ 7 + 1, diff.inDays % 7, slot);
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
  List<DayEvents> toDayEvents(int week,
      {TableDisplayType compact = TableDisplayType.COMPAT}) {
    Map<int, List<Event>> table = Map();
    List<DayEvents> result = [];
    for (int i = 0; i < DateTime.daysPerWeek; i++) {
      table[i] = [];
    }
    courses.forEach((course) {
      if (course.availableWeeks.contains(week)) {
        course.times.forEach((courseTime) =>
            table[courseTime.weekDay].add(Event(course, courseTime)));
      }
    });
    for (int i = 0; i < DateTime.daysPerWeek; i++) {
      if ((compact == TableDisplayType.FULL) ||
          (compact == TableDisplayType.STANDARD && i <= DateTime.friday - 1) ||
          table[i].isNotEmpty)
        result.add(DayEvents(
            day: DateFormat.E().format(kMonday.add(Duration(days: i))),
            events: table[i],
            weekday: i));
    }
    return result;
  }
}

/// Control the result of [TimeTable.toDayEvents()].
enum TableDisplayType {
  /// Add everyday in the result
  FULL,

  /// Even no class, Mon. - Fri. will be added
  STANDARD,

  /// The days on which no course takes place will not be added
  COMPAT
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
  int week, weekday, slot;

  TimeNow(this.week, this.weekday, this.slot);
}
