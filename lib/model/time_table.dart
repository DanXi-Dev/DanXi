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

// ignore_for_file: non_constant_identifier_names

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/fdu/time_table_repository.dart';
import 'package:dan_xi/util/vague_time.dart';
import 'package:dan_xi/widget/time_table/day_events.dart';
import 'package:dan_xi/widget/time_table/schedule_view.dart';
import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

part 'time_table.g.dart';

/// A converter abstraction of converting a timetable to a file in [String] to be exported.
/// The parameters may be null if there aren't any files to export.
abstract class TimetableConverter {
  String? get fileName;

  String? get mimeType;

  String? convertTo(TimeTable table);
}

/// [Event] stands for a [course] with an exact [time].
///
/// It is used to represent the course taken *at* the [time], not the *whole* course.
///
/// For example, if you want to represent a Math lesson at the 1st slot of Monday,
/// then you should use [Event].
/// If you want to represent Math lessons of all weeks, use [Course] directly.
///
/// See Also:
/// * [Course]
/// * [DayEvents]
/// * [TimeTable.toDayEvents]
class Event {
  Course course;
  CourseTime time;

  bool enabled = true;

  Event(this.course, this.time, {this.enabled = true});
}

@JsonSerializable()
class TimeTable {
  /// Start time of the term.
  ///
  /// We decide what the start date is in this priority order:
  /// 1. StartDate passed in as a parameters
  /// 2. [TimeTable.defaultStartTime] (It should be same as [SettingsProvider.getInstance().thisSemesterStartDate])
  /// 3. [Constant.DEFAULT_SEMESTER_START_DATE].
  ///
  /// When user changes the semester, we should look for the semester id in [SettingsProvider.getInstance().semesterStartDates],
  /// which was obtained from Bmob Database.
  /// If found, we set [defaultStartTime] to that date.
  /// Otherwise we do nothing and notify the user to set [TimeTable.defaultStartTime] manually.
  ///
  /// If you need to listen to the change of [defaultStartTime], see codes in
  static DateTime get defaultStartTime {
    var startDateStr = SettingsProvider.getInstance().thisSemesterStartDate;
    DateTime? startDate;
    if (startDateStr != null) startDate = DateTime.tryParse(startDateStr);
    return startDate ?? Constant.DEFAULT_SEMESTER_START_DATE;
  }

  /// A Monday.
  ///
  /// It is randomly selected, without special meaning. You can use any Monday to replace it.
  static final DateTime kMonday = DateTime(2021, 3, 22);
  static const int MINUTES_OF_COURSE = 45;
  static const int MAX_WEEK = 18;

  /// The start time of each slot in a day.
  static final List<VagueTime> kCourseSlotStartTime = [
    const VagueTime(hour: 8, minute: 0),
    const VagueTime(hour: 8, minute: 55),
    const VagueTime(hour: 9, minute: 55),
    const VagueTime(hour: 10, minute: 50),
    const VagueTime(hour: 11, minute: 45),
    const VagueTime(hour: 13, minute: 30),
    const VagueTime(hour: 14, minute: 25),
    const VagueTime(hour: 15, minute: 25),
    const VagueTime(hour: 16, minute: 20),
    const VagueTime(hour: 17, minute: 15),
    const VagueTime(hour: 18, minute: 30),
    const VagueTime(hour: 19, minute: 25),
    const VagueTime(hour: 20, minute: 20),
    const VagueTime(hour: 21, minute: 15),
    const VagueTime(hour: 22, minute: 10),
  ];

  /// All courses in the timetable.
  List<Course>? courses = [];

  /// First day of the semester.
  ///
  /// Set the json key name to keep downward compatibility.
  @JsonKey(name: "startTime")
  DateTime? startDate;

  TimeTable();

  /// Parse timetable from the HTML source codes of Fudan Undergraduate Edu Service.
  ///
  /// See:
  /// * [TimeTableRepository]
  factory TimeTable.fromHtml(DateTime startTime, String tablePageSource) {
    TimeTable newTable = TimeTable()..startDate = startTime;
    RegExp courseMatcher =
        RegExp(r'\t*activity = new.*\n(\t*index =.*\n\t*table0.*\n)*');
    for (Match matchedCourse in courseMatcher.allMatches(tablePageSource)) {
      newTable.courses!.add(Course.fromHtmlPart(matchedCourse.group(0)!));
    }
    return newTable;
  }

  /// Parse timetable from the json of Fudan Postgraduate Course Selection system.
  factory TimeTable.fromPGJson(DateTime startTime, dynamic Coursejson) {
    TimeTable newTable = TimeTable()..startDate = startTime;
    for (dynamic course in Coursejson["results"]) {
      newTable.courses!.add(Course.fromPGPart(course));
    }
    return newTable;
  }

  factory TimeTable.fromJson(Map<String, dynamic> json) =>
      _$TimeTableFromJson(json);

  factory TimeTable.mergeManuallyAddedCourses(
      TimeTable? formerTimeTable, List<Course?> newCourses) {
    if (formerTimeTable == null) {
      return TimeTable();
    }
    if (newCourses.isEmpty) {
      return formerTimeTable;
    }
    for (var newCourse in newCourses) {
      formerTimeTable.courses!.add(newCourse!);
    }
    return formerTimeTable;
  }

  Map<String, dynamic> toJson() => _$TimeTableToJson(this);

  /// Get the date representation in [TimeNow]
  /// (i.e. the W-th lesson on the X-th day of week in the Y-th weeks of this semester) of the present time,
  /// depending on [startDate].
  ///
  /// If the present time is out of the semester, it could return negative or big result.
  TimeNow now() {
    DateTime now = DateTime.now();
    Duration diff = now.difference(startDate!);
    int slot = -1;
    for (int i = 0; i < kCourseSlotStartTime.length; i++) {
      if (now.isAfter(kCourseSlotStartTime[i].toExactTime())) {
        slot = i;
      }
    }
    if (diff.isNegative) {
      var days = diff.inDays;
      // If the day of duration is not exactly an integer, we need to go back one more day.
      // e.g. [startTime] is 02-12 00:00:00, and the time now is 02-11 18:00:00. Then [diff.inDays] == 0, but
      //      in fact we suppose the [days] to be `-1`.
      if (diff != Duration(days: days)) days--;

      // Similarly, special rounding method should be used here to get the correct result.
      return TimeNow(days % 7 == 0 ? days ~/ 7 + 1 : days ~/ 7, days % 7, slot);
    } else {
      return TimeNow(diff.inDays ~/ 7 + 1, diff.inDays % 7, slot);
    }
  }

  /// See [now] for details.
  static TimeNow defaultNow() {
    DateTime now = DateTime.now();
    Duration diff = now.difference(defaultStartTime);
    int slot = -1;
    for (int i = 0; i < kCourseSlotStartTime.length; i++) {
      if (now.isAfter(kCourseSlotStartTime[i].toExactTime())) {
        slot = i;
      }
    }
    if (diff.isNegative) {
      var days = diff.inDays;
      if (diff != Duration(days: days)) days--;
      return TimeNow(days % 7 == 0 ? days ~/ 7 + 1 : days ~/ 7, days % 7, slot);
    } else {
      return TimeNow(diff.inDays ~/ 7 + 1, diff.inDays % 7, slot);
    }
  }

  /// Return the specific [week]'s course list.
  ///
  /// The key of map is the day of the week.
  Map<int, List<Event>> toWeekCourses(int week) {
    Map<int, List<Event>> table = {};
    for (int i = 0; i < 7; i++) {
      table[i] = [];
    }

    for (var course in courses!) {
      if (course.availableWeeks!.contains(week)) {
        for (var courseTime in course.times!) {
          table[courseTime.weekDay]!.add(Event(course, courseTime));
        }
      }
    }
    return table;
  }

  /// Convert the specific [week]'s timetable to [DayEvents], usually for a [ScheduleView].
  /// If the course is available in this week, it will be added to the [DayEvents] of the day of the course.
  /// Else if the course is available in the next week and the course is on Sunday, it will be added to the [DayEvents] of the day of the course.
  List<DayEvents> toDayEvents(int week,
      {TableDisplayType compact = TableDisplayType.COMPAT}) {
    Map<int, List<Event>> table = {};
    List<DayEvents> result = [];
    for (int i = 0; i < DateTime.daysPerWeek; i++) {
      table[i] = [];
    }
    for (var course in courses!) {
      for (var courseTime in course.times!) {
        if (course.availableWeeks!.contains(week)) {
          table[courseTime.weekDay]!.add(Event(course, courseTime));
        }
      }
    }
    for (int i = 0; i < DateTime.daysPerWeek; i++) {
      if ((compact == TableDisplayType.FULL) ||
          (compact == TableDisplayType.STANDARD && i <= DateTime.friday - 1) ||
          table[i]!.isNotEmpty) {
        result.add(DayEvents(
            day: DateFormat.E().format(kMonday.add(Duration(days: i))),
            events: table[i]!,
            weekday: i));
      }
    }
    return result;
  }
}

/// The result flavor of [TimeTable.toDayEvents].
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
  List<String>? teacherIds;
  List<String>? teacherNames;
  String? courseId;
  String? courseName;
  String? roomId;
  String? roomName;
  List<int>? availableWeeks;
  List<CourseTime>? times;

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
      List<String> daySlot = e.group(0)!.trim().split("*unitCount+");
      return CourseTime(int.parse(daySlot[0]), int.parse(daySlot[1]));
    }));
    return courseTimes;
  }

  static _trimCourseName(String name) {
    name = name.trim();
    int idPos = name.lastIndexOf(RegExp(r'\(\w{3,4}\d{6}.?\.\d{2}h?\)'));
    return idPos >= 0 ? name.replaceRange(idPos, name.length, "") : name;
  }

  factory Course.fromHtmlPart(String htmlPart) {
    Course newCourse = Course();
    RegExp infoMatcher = RegExp(r'(?<=TaskActivity\(").*(?="\))');
    RegExp timeMatcher = RegExp(r'[0-9]+\*unitCount\+[0-9]+');
    String info = infoMatcher.firstMatch(htmlPart)!.group(0)!;

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

  factory Course.fromPGPart(dynamic PGPart) {
    Course newCourse = Course();
    return newCourse
      ..courseName = PGPart["KCMC"]
      ..roomName = PGPart["JASMC"]
      ..roomName ??= ' '
      // The 0th digit of Postgraduates ZCBH mean the 1st week. Add a prefix zero to work with [_parseWeeksFromString].
      ..availableWeeks = _parseWeeksFromString("0" + PGPart["ZCBH"])
      ..times = [CourseTime(PGPart["XQ"] - 1, PGPart["KSJCDM"] - 1)]
      ..teacherNames = [PGPart["JSXM"]];
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

/// Representation of the [slot]-th lesson on the [weekday]-th day of week in the [week]-th weeks of this semester.
class TimeNow {
  //First week is 1, Monday is 0
  int week, weekday, slot;

  TimeNow(this.week, this.weekday, this.slot);
}
