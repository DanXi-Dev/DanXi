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

import 'package:dan_xi/model/extra.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/uis_login_tool.dart';
import 'package:dan_xi/repository/fdu/edu_service_repository.dart';
import 'package:dan_xi/util/io/cache.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dan_xi/util/retrier.dart';
import 'package:dan_xi/util/shared_preferences.dart';
import 'package:dio/dio.dart';

class TimeTableRepository extends BaseRepositoryWithDio {
  static const String TIMETABLE_REQUEST_URL =
      'https://id.fudan.edu.cn/idp/authCenter/authenticate?service=https%3A%2F%2Ffdjwgl.fudan.edu.cn%2Fstudent%2Fsso%2Flogin%3FtargetUrl%3D%2Fstudent%2Ffor-std%2Fcourse-table';
  static const String TIMETABLE_UIS_LOGIN_URL =
      'https://uis.fudan.edu.cn/authserver/login?service=https://id.fudan.edu.cn/idp/thirdAuth/cas';
  static const String TIMETABLE_SESSION_URL =
      'https://fdjwgl.fudan.edu.cn/student/sso/login?targetUrl=/student/for-std/course-table&ticket=';
  static const String TIMETABLE_DATA_URL =
      'https://fdjwgl.fudan.edu.cn/student/for-std/course-table/semester/{sem_id}/print-data';
  static const String TIMETABLE_URL =
      'https://fdjwgl.fudan.edu.cn/student/for-std/course-table';
  static const String KEY_TIMETABLE_CACHE = "timetable";

  static Future<void>? loginSession;

  TimeTableRepository._();

  static final _instance = TimeTableRepository._();

  factory TimeTableRepository.getInstance() => _instance;

  Future<void> _authenticateJWGL(PersonInfo info) async {
    final ticket = await UISLoginTool.getAuthenticateTicket(
        dio, cookieJar!, info, TIMETABLE_REQUEST_URL, TIMETABLE_UIS_LOGIN_URL);
    Response<dynamic>? res = await dio.get(TIMETABLE_SESSION_URL + ticket!,
        options: DioUtils.NON_REDIRECT_OPTION_WITH_FORM_TYPE);
    await DioUtils.processRedirect(dio, res);
  }

  Future<void> loginJWGL(PersonInfo info) async {
    if (loginSession != null) {
      try {
        await loginSession;
      } on DioException {
        loginSession = _authenticateJWGL(info);
        await loginSession!;
      }
    } else {
      loginSession = _authenticateJWGL(info);
      await loginSession!;
      loginSession = null;
    }
  }

  Future<TimeTableSemesterInfo> loadSemestersForTimeTable(
          PersonInfo info) async =>
      Retrier.tryAsyncWithFix(
        () async => await _loadSemestersForTimeTable(info),
        (_) async => await loginJWGL(info),
        retryTimes: 5,
        // If there is an explicit reason for UIS login failure, we should not retry anymore.
        isFatalRetryError: (e) =>
            e is CredentialsInvalidException ||
            e is CaptchaNeededException ||
            e is NetworkMaintenanceException ||
            e is WeakPasswordException,
      );

  // Load current semester id, start date from JWGL, and store start date in settings.
  Future<CurrentSemesterInfo> _loadCurrentSemesterInfo(PersonInfo? info,
      {String? semesterHtml}) async {
    if (semesterHtml == null || semesterHtml.isEmpty) {
      Response<dynamic>? res = await dio.get(TIMETABLE_URL,
          options: DioUtils.NON_REDIRECT_OPTION_WITH_FORM_TYPE);
      semesterHtml = res.data!;
    }
    final currentSemesterRegex = RegExp(r'var currentSemester = ([\s\S]*?);');
    final currentSemesterMatch = currentSemesterRegex.firstMatch(semesterHtml!);
    if (currentSemesterMatch == null || currentSemesterMatch.groupCount < 1) {
      throw "Retrieval failed";
    }
    final String currentSemesterJsonText =
        currentSemesterMatch.group(1)!.replaceAll('\'', '"');
    final currentSemesterJson = jsonDecode(currentSemesterJsonText);
    String defaultSemesterId = currentSemesterJson['id'].toString();
    DateTime startDate = DateTime(
        currentSemesterJson['startDate']["values"][0],
        currentSemesterJson['startDate']["values"][1],
        currentSemesterJson['startDate']["values"][2]);
    // Start date at JWGL is Sunday, we need to add one day to make it Monday.
    startDate = startDate.add(Duration(days: 1));
    SettingsProvider.getInstance().thisSemesterStartDate =
        startDate.toIso8601String();
    return CurrentSemesterInfo(defaultSemesterId, startDate);
  }

  Future<TimeTableSemesterInfo> _loadSemestersForTimeTable(
      PersonInfo? info) async {
    Response<dynamic>? res = await dio.get(TIMETABLE_URL,
        options: DioUtils.NON_REDIRECT_OPTION_WITH_FORM_TYPE);
    final String semesterHtml = res.data!;
    final semestersRegex =
        RegExp(r'var semesters = JSON\.parse\(([\s\S]*?)\);');
    final semestersMatch = semestersRegex.firstMatch(semesterHtml);
    if (semestersMatch == null || semestersMatch.groupCount < 1) {
      throw "Retrieval failed";
    }
    final String semestersJsonText =
        semestersMatch.group(1)!.replaceAll('\'', '').replaceAll(r'\"', '"');
    final semestersJson = jsonDecode(semestersJsonText);
    List<SemesterInfo> sems = [];
    List<TimeTableStartTimeItem> startDates = [];
    for (var element in semestersJson) {
      if (element is Map<String, dynamic> && element.isNotEmpty) {
        var annualSemesters = SemesterInfo.fromCourseTableJson(element);
        sems.add(annualSemesters);
        DateTime? startDate = DateTime.tryParse(
          element['startDate'] ?? '',
        );
        if (startDate != null) {
          // Start date at JWGL is Sunday, we need to add one day to make it Monday.
          startDate = startDate.add(Duration(days: 1));
        }
        startDates.add(TimeTableStartTimeItem(
          element['id'].toString(),
          startDate?.toIso8601String(),
        ));
      }
    }
    if (sems.isEmpty) throw "Retrieval failed";

    String defaultSemesterId =
        (await _loadCurrentSemesterInfo(info, semesterHtml: semesterHtml))
            .semesterId!;

    return TimeTableSemesterInfo(
      sems,
      defaultSemesterId,
      TimeTableExtra(startDates),
    );
  }

  Future<TimeTable?> loadTimeTableRemotely(PersonInfo? info,
          {DateTime? startTime}) =>
      Retrier.tryAsyncWithFix(
        () async => await _loadTimeTableRemotely(info, startTime: startTime),
        (_) async => await loginJWGL(info!),
        retryTimes: 3,
        // If there is an explicit reason for UIS login failure, we should not retry anymore.
        isFatalRetryError: (e) =>
            e is CredentialsInvalidException ||
            e is CaptchaNeededException ||
            e is NetworkMaintenanceException ||
            e is WeakPasswordException,
      );

  Future<TimeTable?> _loadTimeTableRemotely(PersonInfo? info,
      {DateTime? startTime}) async {
    Future<CurrentSemesterInfo> getAppropriateSemesterInfo(
        PersonInfo? info) async {
      String? semesterId = SettingsProvider.getInstance().timetableSemester;
      String? startDate = SettingsProvider.getInstance().thisSemesterStartDate;
      if (semesterId == null ||
          semesterId.isEmpty ||
          startDate == null ||
          startDate.isEmpty) {
        return await _loadCurrentSemesterInfo(info);
      } else {
        return CurrentSemesterInfo(semesterId, DateTime.tryParse(startDate));
      }
    }

    CurrentSemesterInfo semesterInfo = await getAppropriateSemesterInfo(info);
    Response<dynamic>? res = await dio.get(
        TIMETABLE_DATA_URL.replaceAll("{sem_id}", semesterInfo.semesterId!),
        options: DioUtils.NON_REDIRECT_OPTION_WITH_FORM_TYPE);
    TimeTable timetable = TimeTable.fromJWGLJson(
        startTime ?? semesterInfo.startDate ?? TimeTable.defaultStartTime,
        res.data!);
    // TODO: do we still need this?
    // for (var course in timetable.courses!) {
    //   for (var weekday in course.times!) {
    //     if (weekday.weekDay == 6) {
    //       for (int i = 0; i < course.availableWeeks!.length; i++) {
    //         course.availableWeeks![i] = course.availableWeeks![i] - 1;
    //       }
    //       break;
    //     }
    //   }
    // }
    return timetable;
  }

  Future<TimeTable?> loadTimeTable(PersonInfo? info,
      {DateTime? startTime, bool forceLoadFromRemote = false}) async {
    if (forceLoadFromRemote) {
      TimeTable? result = await Cache.getRemotely<TimeTable>(
          KEY_TIMETABLE_CACHE,
          () async =>
              (await loadTimeTableRemotely(info, startTime: startTime))!,
          (cachedValue) => TimeTable.fromJson(jsonDecode(cachedValue!)),
          (object) => jsonEncode(object.toJson()));
      SettingsProvider.getInstance().timetableLastUpdated = DateTime.now();
      return result;
    } else {
      return Cache.get<TimeTable>(
          KEY_TIMETABLE_CACHE,
          () async =>
              (await loadTimeTableRemotely(info, startTime: startTime))!,
          (cachedValue) => TimeTable.fromJson(jsonDecode(cachedValue!)),
          (object) => jsonEncode(object.toJson()));
    }
  }

  // Check if the timetable has been fetched before.
  bool hasCache() {
    XSharedPreferences preferences =
        SettingsProvider.getInstance().preferences!;
    return preferences.containsKey(KEY_TIMETABLE_CACHE) &&
        SettingsProvider.getInstance().timetableLastUpdated != null;
  }

  @override
  String get linkHost => "fdjwgl.fudan.edu.cn";
}

class CurrentSemesterInfo {
  String? semesterId;
  DateTime? startDate;

  CurrentSemesterInfo(this.semesterId, this.startDate);
}

class TimeTableSemesterInfo {
  List<SemesterInfo> semesters;
  TimeTableExtra startDates;
  String? defaultSemesterId;

  TimeTableSemesterInfo(
      this.semesters, this.defaultSemesterId, this.startDates);
}
