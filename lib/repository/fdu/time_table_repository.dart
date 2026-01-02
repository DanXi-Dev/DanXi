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

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:dan_xi/model/extra.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/edu_service_repository.dart';
import 'package:dan_xi/repository/fdu/neo_login_tool.dart';
import 'package:dan_xi/util/io/cache.dart';
import 'package:dan_xi/util/shared_preferences.dart';
import 'package:dio/dio.dart';

class TimeTableRepository extends BaseRepositoryWithDio {
  static const String TIMETABLE_DATA_URL =
      'https://fdjwgl.fudan.edu.cn/student/for-std/course-table/semester/{sem_id}/print-data';
  static const String TIMETABLE_URL =
      'https://fdjwgl.fudan.edu.cn/student/for-std/course-table';
  static const String KEY_TIMETABLE_CACHE = "timetable";

  TimeTableRepository._();

  static final _instance = TimeTableRepository._();

  factory TimeTableRepository.getInstance() => _instance;

  /// Load TimeTable. [SettingsProvider] determines which semester to load.
  Future<TimeTable?> loadTimeTable(String? semesterId, String? startDate,
      {bool forceLoadFromRemote = false}) async {
    if (forceLoadFromRemote) {
      TimeTable? result = await Cache.getRemotely<TimeTable>(
          KEY_TIMETABLE_CACHE,
          () async => (await _loadTimeTableRemotely(semesterId, startDate))!,
          (cachedValue) => TimeTable.fromJson(jsonDecode(cachedValue!)),
          (object) => jsonEncode(object.toJson()));
      return result;
    } else {
      return Cache.get<TimeTable>(
          KEY_TIMETABLE_CACHE,
          () async => (await _loadTimeTableRemotely(semesterId, startDate))!,
          (cachedValue) => TimeTable.fromJson(jsonDecode(cachedValue!)),
          (object) => jsonEncode(object.toJson()));
    }
  }

  /// Load TimeTable from FDU server.
  Future<TimeTable?> _loadTimeTableRemotely(
      String? semesterId, String? startDate) async {
    // Determine which semester we need to load.
    // If not stored in [SettingsProvider], we use default semester.
    Future<SemesterInfoWithStartDate> getAppropriateSemesterInfo(
        String? semesterId, String? startDate) async {
      if (semesterId == null ||
          semesterId.isEmpty ||
          startDate == null ||
          startDate.isEmpty) {
        return await _loadDefaultSemesterInfo();
      } else {
        return SemesterInfoWithStartDate(
            semesterId, DateTime.tryParse(startDate));
      }
    }

    SemesterInfoWithStartDate semesterInfo =
        await getAppropriateSemesterInfo(semesterId, startDate);
    final options = RequestOptions(
        method: "GET",
        path: TIMETABLE_DATA_URL
            .replaceAll("{sem_id}", semesterInfo.semesterId!),
    );
    return FudanSession.request(options, (res) {
      SettingsProvider.getInstance().timetableLastUpdated = DateTime.now();
      return TimeTable.fromJWGLJson(
          semesterInfo.startDate ?? TimeTable.defaultStartDate, res.data!);
    });
  }

  /// Load default semester id and start date from JWGL, then store start date in settings.
  Future<SemesterInfoWithStartDate> _loadDefaultSemesterInfo() async {
    final options = RequestOptions(
        method: "GET",
        path: TIMETABLE_URL,
    );
    return FudanSession.request(options, (res) {
      return _parseDefaultSemesterInfo(res.data!);
    });
  }

  /// Parse all semesters and their start dates
  SemesterBundle _parseSemesters(String semesterHtml) {
    final semestersRegex =
        RegExp(r'var semesters = JSON\.parse\(([\s\S]*?)\);');
    final semestersMatch = semestersRegex.firstMatch(semesterHtml);
    if (semestersMatch == null || semestersMatch.groupCount < 1) {
      throw "Retrieval failed";
    }
    final String semestersJsonText =
        semestersMatch.group(1)!.replaceAll('\'', '').replaceAll(r'\"', '"');
    final List<dynamic> semestersJson = jsonDecode(semestersJsonText);
    List<SemesterInfo> sems = [];
    List<TimeTableStartDateItem> startDates = [];
    for (var element in semestersJson.reversed) {
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
        startDates.add(TimeTableStartDateItem(
          element['id'].toString(),
          startDate?.toIso8601String(),
        ));
      }
    }
    if (sems.isEmpty) throw "Retrieval failed";

    String defaultSemesterId = _parseDefaultSemesterId(semesterHtml);

    return SemesterBundle(
      sems,
      defaultSemesterId,
      SemesterStartDates(startDates),
    );
  }

  String _parseDefaultSemesterId(String semesterHtml) {
    BeautifulSoup soup = BeautifulSoup(semesterHtml);
    final firstOption = soup.find('', selector: '#allSemesters option');
    return firstOption!['value']!;
  }

  SemesterInfoWithStartDate _parseDefaultSemesterInfo(String semesterHtml) {
    SemesterBundle semesters = _parseSemesters(semesterHtml);
    String defaultSemesterId = semesters.defaultSemesterId;
    String? startDate = semesters.startDates.parseStartDate(defaultSemesterId);
    return SemesterInfoWithStartDate(
        defaultSemesterId, DateTime.tryParse(startDate!));
  }

  SemesterBundle parseSemesters(String semesterHtml) =>
      _parseSemesters(semesterHtml);

  /// Check if the timetable has been fetched before.
  bool hasCache() {
    XSharedPreferences preferences =
        SettingsProvider.getInstance().preferences!;
    return preferences.containsKey(KEY_TIMETABLE_CACHE) &&
        SettingsProvider.getInstance().timetableLastUpdated != null;
  }

  @override
  String get linkHost => "fdjwgl.fudan.edu.cn";
}

class SemesterInfoWithStartDate {
  String? semesterId;
  DateTime? startDate;

  SemesterInfoWithStartDate(this.semesterId, this.startDate);
}

class SemesterBundle {
  List<SemesterInfo> semesters;
  SemesterStartDates startDates;
  String defaultSemesterId;

  SemesterBundle(this.semesters, this.defaultSemesterId, this.startDates);
}
