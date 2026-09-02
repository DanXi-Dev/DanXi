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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/neo_login_tool.dart';
import 'package:dan_xi/repository/fdu/time_table_repository.dart';
import 'package:dan_xi/util/io/cache.dart';
import 'package:dan_xi/util/shared_preferences.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dio/dio.dart';

class PostgraduateTimetableRepository extends BaseRepositoryWithDio {
  static const String TIME_TABLE_URL_PRIMARY =
      'http://yjsxk.fudan.edu.cn/yjsxkapp/sys/xsxkappfudan/xsxkCourse/loadKbxx.do?_=';
  static const String TIME_TABLE_URL_SECONDARY =
      'http://yjsxktest.fudan.sh.cn/yjsxkapp/sys/xsxkappfudan/xsxkCourse/loadKbxx.do?_=';

  PostgraduateTimetableRepository._();

  static final _instance = PostgraduateTimetableRepository._();

  factory PostgraduateTimetableRepository.getInstance() => _instance;

  Future<TimeTable?> loadTimeTableRemotely(PersonInfo info,
      {DateTime? startTime}) async {
    try {
      return await _loadTimeTableFrom(TIME_TABLE_URL_PRIMARY, info, startTime);
    } catch (primaryError, primaryStackTrace) {
      // The two endpoints are available during different periods of time, so we try the secondary one if the primary one fails.
      try {
        return await _loadTimeTableFrom(
            TIME_TABLE_URL_SECONDARY, info, startTime);
      } catch (fallbackError, fallbackStackTrace) {
        throw FallbackException(
          primaryError: primaryError,
          primaryStackTrace: primaryStackTrace,
          fallbackError: fallbackError,
          fallbackStackTrace: fallbackStackTrace,
        );
      }
    }
  }

  Future<TimeTable?> _loadTimeTableFrom(
      String url, PersonInfo info, DateTime? startTime) {
    final options = RequestOptions(
      method: "GET",
      path: url + DateTime.now().millisecondsSinceEpoch.toString(),
    );
    return FudanSession.request(options, (coursePage) {
      return TimeTable.fromPGJson(
          startTime ??
              DateTime.tryParse(
                  SettingsProvider.getInstance().thisSemesterStartDate ?? "") ??
              Constant.DEFAULT_SEMESTER_START_DATE,
          coursePage.data is Map
              ? coursePage.data
              : jsonDecode(coursePage.data.toString()));
    }, info: info);
  }

  Future<TimeTable?> loadTimeTable(PersonInfo info,
      {DateTime? startTime, bool forceLoadFromRemote = false}) async {
    startTime ??= TimeTable.defaultStartDate;
    if (forceLoadFromRemote) {
      TimeTable? result = (await Cache.getRemotely<TimeTable>(
          TimeTableRepository.KEY_TIMETABLE_CACHE,
          () async => (await loadTimeTableRemotely(info,
              startTime: startTime))!,
          (cachedValue) => TimeTable.fromJson(jsonDecode(cachedValue!)),
          (object) => jsonEncode(object.toJson())));
      SettingsProvider.getInstance().timetableLastUpdated = DateTime.now();
      return result;
    } else {
      return Cache.get<TimeTable>(
          TimeTableRepository.KEY_TIMETABLE_CACHE,
          () async => (await loadTimeTableRemotely(info,
              startTime: startTime))!,
          (cachedValue) => TimeTable.fromJson(jsonDecode(cachedValue!)),
          (object) => jsonEncode(object.toJson()));
    }
  }

  TimeTable loadTimeTableLocally() {
    // FIXME: Do not read this should-be-private field everywhere!
    XSharedPreferences preferences =
        SettingsProvider.getInstance().preferences!;
    if (preferences.containsKey(TimeTableRepository.KEY_TIMETABLE_CACHE)) {
      return TimeTable.fromJson(jsonDecode(
          preferences.getString(TimeTableRepository.KEY_TIMETABLE_CACHE)!));
    } else {
      throw StateError("No local timetable now");
    }
  }

  @override
  String get linkHost => "fudan.edu.cn";
}
