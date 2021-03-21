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

import 'dart:convert';

import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/uis_login_tool.dart';
import 'package:dan_xi/util/cache.dart';
import 'package:dan_xi/util/dio_utils.dart';
import 'package:dio/dio.dart';

class TimeTableRepository extends BaseRepositoryWithDio {
  static const String LOGIN_URL =
      'https://uis.fudan.edu.cn/authserver/login?service=http%3A%2F%2Fjwfw.fudan.edu.cn%2Feams%2Flogin.action';
  static const String ID_URL =
      'https://jwfw.fudan.edu.cn/eams/courseTableForStd.action';
  static const String TABLE_URL =
      'https://jwfw.fudan.edu.cn/eams/courseTableForStd!courseTable.action';
  static const String HOST = "https://jwfw.fudan.edu.cn/eams/";
  static const String KEY_TIMETABLE_CACHE = "timetable";

  TimeTableRepository._() {
    initRepository();
  }

  static final _instance = TimeTableRepository._();

  factory TimeTableRepository.getInstance() => _instance;

  String _getIds(String html) {
    RegExp idMatcher = RegExp(r'(?<=ids",").+(?="\);)');
    return idMatcher.firstMatch(html).group(0);
  }

  Future<TimeTable> loadTimeTableRemotely(PersonInfo info,
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

  Future<TimeTable> loadTimeTableLocally(PersonInfo info,
          {DateTime startTime}) =>
      Cache.get(
          KEY_TIMETABLE_CACHE,
          () => loadTimeTableRemotely(info, startTime: startTime),
          (cachedValue) => TimeTable.fromJson(jsonDecode(cachedValue)),
          (object) => jsonEncode(object.toJson()));
}
