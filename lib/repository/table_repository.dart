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

import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/uis_login_tool.dart';
import 'package:dan_xi/util/cache.dart';
import 'package:dan_xi/util/dio_utils.dart';
import 'package:dan_xi/util/retryer.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart' as DOM;

class TimeTableRepository extends BaseRepositoryWithDio {
  static const String LOGIN_URL =
      'https://uis.fudan.edu.cn/authserver/login?service=http%3A%2F%2Fjwfw.fudan.edu.cn%2Feams%2Flogin.action';
  static const String EXAM_TABLE_LOGIN_URL =
      'https://uis.fudan.edu.cn/authserver/login?service=http%3A%2F%2Fjwfw.fudan.edu.cn%2Feams%2FstdExamTable%21examTable.action';
  static const String ID_URL =
      'https://jwfw.fudan.edu.cn/eams/courseTableForStd.action';
  static const String TIME_TABLE_URL =
      'https://jwfw.fudan.edu.cn/eams/courseTableForStd!courseTable.action';
  static const String EXAM_TABLE_URL =
      'https://jwfw.fudan.edu.cn/eams/stdExamTable!examTable.action';
  static const String HOST = "https://jwfw.fudan.edu.cn/eams/";
  static const String KEY_TIMETABLE_CACHE = "timetable";

  TimeTableRepository._();

  static final _instance = TimeTableRepository._();

  factory TimeTableRepository.getInstance() => _instance;

  String _getIds(String html) {
    RegExp idMatcher = RegExp(r'(?<=ids",").+(?="\);)');
    return idMatcher.firstMatch(html).group(0);
  }

  Future<TimeTable> loadTimeTableRemotely(PersonInfo info,
      {DateTime startTime}) {
    return Retrier.tryAsyncWithFix(
        () => _loadTimeTableRemotely(startTime: startTime),
        (exception) async =>
            await UISLoginTool.loginUIS(dio, LOGIN_URL, cookieJar, info, true));
  }

  Future<TimeTable> _loadTimeTableRemotely({DateTime startTime}) async {
    print("loading from remote");
    Response idPage = await dio.get(ID_URL);
    String termId = _getIds(idPage.data.toString());
    Response tablePage = await dio.post(TIME_TABLE_URL,
        data: {
          "ignoreHead": "1",
          "setting.kind": "std",
          "startWeek": "1",
          "ids": termId,
          "semester.id": (await cookieJar.loadForRequest(Uri.parse(HOST)))
              .firstWhere((element) => element.name == "semester.id")
              .value
        },
        options: DioUtils.NON_REDIRECT_OPTION_WITH_FORM_TYPE);
    return TimeTable.fromHtml(startTime, tablePage.data.toString());
  }

  Future<TimeTable> loadTimeTableLocally(PersonInfo info,
      {DateTime startTime, bool forceLoadFromRemote = false}) async {
    if (startTime == null) startTime = TimeTable.START_TIME;
    return TimeTable.fromJson(jsonDecode(
        r'{"courses":[{"teacherIds":["172167","172168","145100","146876","157100"],"teacherNames":["苏卫锋","高渊","白翠琴","童培雄","陈骏逸"],"courseId":"42450(PHYS120015.05)","courseName":"基础物理实验","roomId":"3083","roomName":"H物理楼二楼西侧实验室","availableWeeks":[3,4,5,6,7,8,9,10,11,12,13,14,15,16],"times":[{"weekDay":1,"slot":10},{"weekDay":1,"slot":11},{"weekDay":1,"slot":12}]},{"teacherIds":["172167","172168","145100","146876","157100"],"teacherNames":["苏卫锋","高渊","白翠琴","童培雄","陈骏逸"],"courseId":"42450(PHYS120015.05)","courseName":"基础物理实验","roomId":"495","roomName":"H3106","availableWeeks":[1,2],"times":[{"weekDay":1,"slot":10},{"weekDay":1,"slot":11},{"weekDay":1,"slot":12}]},{"teacherIds":["140926"],"teacherNames":["顾晓东"],"courseId":"505665(MICR120001.01)","courseName":"电路基础","roomId":"551","roomName":"HGX310","availableWeeks":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16],"times":[{"weekDay":3,"slot":2},{"weekDay":3,"slot":3},{"weekDay":3,"slot":4}]},{"teacherIds":["155164"],"teacherNames":["王勇"],"courseId":"42996(MATH120017.05)","courseName":"数学分析BII","roomId":"274","roomName":"H4104","availableWeeks":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16],"times":[{"weekDay":0,"slot":5},{"weekDay":0,"slot":6}]},{"teacherIds":["155164"],"teacherNames":["王勇"],"courseId":"42996(MATH120017.05)","courseName":"数学分析BII","roomId":"274","roomName":"H4104","availableWeeks":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16],"times":[{"weekDay":2,"slot":2},{"weekDay":2,"slot":3}]},{"teacherIds":["155164"],"teacherNames":["王勇"],"courseId":"42996(MATH120017.05)","courseName":"数学分析BII","roomId":"274","roomName":"H4104","availableWeeks":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16],"times":[{"weekDay":4,"slot":0},{"weekDay":4,"slot":1}]},{"teacherIds":["161862"],"teacherNames":["赵海斌"],"courseId":"42432(PHYS120014.07)","courseName":"大学物理B(下)","roomId":"359","roomName":"HGX307","availableWeeks":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16],"times":[{"weekDay":1,"slot":2},{"weekDay":1,"slot":3}]},{"teacherIds":["161862"],"teacherNames":["赵海斌"],"courseId":"42432(PHYS120014.07)","courseName":"大学物理B(下)","roomId":"134,359","roomName":"HGX207,HGX307","availableWeeks":[2,4,6,8,10,12,14,16],"times":[{"weekDay":3,"slot":7},{"weekDay":3,"slot":8}]},{"teacherIds":["161862"],"teacherNames":["赵海斌"],"courseId":"42432(PHYS120014.07)","courseName":"大学物理B(下)","roomId":"359","roomName":"HGX307","availableWeeks":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16],"times":[{"weekDay":3,"slot":0},{"weekDay":3,"slot":1}]},{"teacherIds":["170810"],"teacherNames":["杨霞"],"courseId":"38289(ENGL110012.26)","courseName":"英语视听","roomId":"368","roomName":"H6505","availableWeeks":[11],"times":[{"weekDay":2,"slot":5},{"weekDay":2,"slot":6}]},{"teacherIds":["170810"],"teacherNames":["杨霞"],"courseId":"38289(ENGL110012.26)","courseName":"英语视听","roomId":"2518","roomName":"H4401A（听力）","availableWeeks":[1,2,3,4,5,6,7,8,9,10,12,13,14,15,16],"times":[{"weekDay":2,"slot":5},{"weekDay":2,"slot":6}]},{"teacherIds":["166477"],"teacherNames":["叶如兰"],"courseId":"38312(ENGL110035.16)","courseName":"实用交际英语口语","roomId":"556","roomName":"HGX301","availableWeeks":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16],"times":[{"weekDay":1,"slot":0},{"weekDay":1,"slot":1}]},{"teacherIds":["146672"],"teacherNames":["任义"],"courseId":"40689(PEDU110102.26)","courseName":"足球","roomId":"498","roomName":"H南区足球场","availableWeeks":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16],"times":[{"weekDay":0,"slot":0},{"weekDay":0,"slot":1}]},{"teacherIds":["723607"],"teacherNames":["曹金龙"],"courseId":"505704(PTSS110079.08)","courseName":"习近平新时代中国特色社会主义思想概论","roomId":"301","roomName":"H3409","availableWeeks":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15],"times":[{"weekDay":2,"slot":10},{"weekDay":2,"slot":11}]},{"teacherIds":["712043"],"teacherNames":["薛小荣"],"courseId":"41459(PTSS110008.07)","courseName":"中国近现代史纲要","roomId":"408","roomName":"H3308","availableWeeks":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15],"times":[{"weekDay":0,"slot":10},{"weekDay":0,"slot":11}]},{"teacherIds":["166103"],"teacherNames":["李洁"],"courseId":"42921(PTSS110059.02)","courseName":"形势与政策II","roomId":"104","roomName":"H3209","availableWeeks":[2,3,4,5,6,7,8,9,10,11,12,13,14,15,16],"times":[{"weekDay":1,"slot":5},{"weekDay":1,"slot":6}]},{"teacherIds":["139576"],"teacherNames":["张向东"],"courseId":"488801(COMP110042.12)","courseName":"Python程序设计","roomId":"389","roomName":"H4501","availableWeeks":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16],"times":[{"weekDay":4,"slot":5},{"weekDay":4,"slot":6},{"weekDay":4,"slot":7},{"weekDay":4,"slot":8}]}],"startTime":"2021-03-01T00:00:00.000"}'));
  }

  @override
  String get linkHost => "jwfw.fudan.edu.cn";
}

class Test {
  final String id;
  final String name;
  final String type;
  final String date;
  final String time;
  final String location;
  final String testCategory;
  final String note;

  Test(this.id, this.name, this.type, this.date, this.time, this.location,
      this.testCategory, this.note);

  factory Test.fromHtml(DOM.Element html) {
    List<DOM.Element> elements = html.getElementsByTagName("td");
    return Test(
        elements[0].text.trim(),
        elements[2].text.trim(),
        elements[3].text.trim(),
        elements[4].text.trim(),
        elements[5].text.trim(),
        elements[6].text.trim(),
        elements[7].text.trim(),
        elements[8].text.trim());
  }
}
