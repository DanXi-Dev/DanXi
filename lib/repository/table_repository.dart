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

import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/uis_login_tool.dart';
import 'package:dan_xi/util/dio_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

class TimeTableRepository extends BaseRepositoryWithDio {
  static const String LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=http%3A%2F%2Fjwfw.fudan.edu.cn%2Feams%2Flogin.action";
  static const String ID_URL =
      "https://jwfw.fudan.edu.cn/eams/courseTableForStd.action";
  static const String TABLE_URL =
      "https://jwfw.fudan.edu.cn/eams/courseTableForStd!courseTable.action";
  static const String HOST = "https://jwfw.fudan.edu.cn/eams/";

  TimeTableRepository._() {
    initRepository();
  }

  static final _instance = TimeTableRepository._();

  factory TimeTableRepository.getInstance() => _instance;

  String _getIds(String html) {
    RegExp idMatcher = RegExp(r'(?<=ids",").+(?="\);)');
    return idMatcher.firstMatch(html).group(0);
  }

  Future<TimeTable> loadTimeTableRemote(PersonInfo info,
      {DateTime startTime}) async {
    await UISLoginTool.loginUIS(dio, LOGIN_URL, cookieJar, info);
    Response idPage = await dio.get(ID_URL);
    String termId = _getIds(idPage.data.toString());
    Response tablePage = await dio.post(TABLE_URL,
        data: {
          "ignoreHead": "1",
          "setting.kind": "std",
          "startWeek": "1",
          "ids": termId,
          "semester.id": cookieJar
              .loadForRequest(Uri.parse(HOST))
              .firstWhere((element) => element.name == "semester.id")
              .value
        },
        options: DioUtils.NON_REDIRECT_OPTION_WITH_FORM_TYPE);
    return TimeTable.fromHtml(startTime, tablePage.data.toString());
  }
}

class TimeTable {
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
}

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

  static List<CourseTime> _parseTimeFromStrings(Iterable<RegExpMatch> times) {
    List<CourseTime> courseTimes = [];
    courseTimes.addAll(times.map((RegExpMatch e) {
      List<String> daySlot = e.group(0).trim().split("*unitCount+");
      return CourseTime(int.parse(daySlot[0]), int.parse(daySlot[1]));
    }));
    return courseTimes;
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
      ..courseName = infoVarList[3]
      ..roomId = infoVarList[4]
      ..roomName = infoVarList[5]
      ..availableWeeks = _parseWeeksFromString(infoVarList[6])
      ..times = _parseTimeFromStrings(timeMatcher.allMatches(htmlPart));
  }
}

class CourseTime {
  //Monday is 0, Morning lesson is 0
  int weekDay, slot;

  CourseTime(this.weekDay, this.slot);
}
