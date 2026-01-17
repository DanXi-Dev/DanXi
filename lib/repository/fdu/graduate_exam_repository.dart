/*
 *     Copyright (C) 2025  DanXi-Dev
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

import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/edu_service_repository.dart';
import 'package:dio/dio.dart';

import 'neo_login_tool.dart';

/// Repository for graduate student exam/score data.
///
/// This repository fetches data from the graduate student system.
///
/// ## API Details
///
/// ### Get Semesters
/// URL: https://zlapp.fudan.edu.cn/fudanyjskb/wap/default/get-index
///
/// Response:
/// ```json
/// {
///     "e": 0,
///     "m": "",
///     "d": {
///         "params": {
///             "year": "2023-2024",
///             "term": "2",
///             "startday": "2024-02-26",
///             "countweek": 18,
///             "week": 4
///         },
///         "termInfo": [
///             {
///                 "year": "2024-2025",
///                 "term": "2",
///                 "startday": "2025-03-01",
///                 "countweek": 18
///             }
///         ]
///     }
/// }
/// ```
///
/// ### Get Scores
/// URL: https://yzsfwapp.fudan.edu.cn/gsapp/sys/wdcjapp/modules/xscjcx/jdjscjcx.do
/// Login URL: https://yzsfwapp.fudan.edu.cn/gsapp/sys/wdcjapp/*default/index.do
///
/// Response:
/// ```json
/// {
///     "code": "0",
///     "datas": {
///         "jdjscjcx": {
///             "totalSize": 8,
///             "pageSize": 999,
///             "rows": [
///                 {
///                     "KCMC": "Course Name",
///                     "KCDM": "Course Code",
///                     "XF": 2.0,
///                     "CZRXM": "Teacher",
///                     "KCLBMC": "Course Type",
///                     "CJ": "A",
///                     "JDZ": 4.0
///                 }
///             ]
///         }
///     }
/// }
/// ```
class GraduateExamRepository extends BaseRepositoryWithDio {
  static const String _SEMESTER_URL =
      'https://zlapp.fudan.edu.cn/fudanyjskb/wap/default/get-index';

  static const String _SCORE_URL =
      'https://yzsfwapp.fudan.edu.cn/gsapp/sys/wdcjapp/modules/xscjcx/jdjscjcx.do';

  static const String _SCORE_LOGIN_URL =
      'https://yzsfwapp.fudan.edu.cn/gsapp/sys/wdcjapp/*default/index.do';

  @override
  String get linkHost => "fudan.edu.cn";

  GraduateExamRepository._();

  static final _instance = GraduateExamRepository._();

  factory GraduateExamRepository.getInstance() => _instance;

  /// Load all semesters for graduate students.
  ///
  /// Returns a list of [SemesterInfo] objects.
  ///
  /// Note: The `startday` property may be incorrect in previous semesters.
  Future<List<SemesterInfo>> loadSemesters() {
    final options = RequestOptions(
      method: "GET",
      path: _SEMESTER_URL,
    );
    return FudanSession.request(options, (response) {
      final Map<String, dynamic> data = response.data;

      final int errorCode = data['e'];
      if (errorCode != 0) {
        throw GraduateExamException('Failed to load semesters: ${data['m']}');
      }

      final Map<String, dynamic> d = data['d'];
      final List<dynamic> termInfo = d['termInfo'];

      final semesters = <SemesterInfo>[];
      for (final term in termInfo) {
        final Map<String, dynamic> termMap = term;
        final String yearString = termMap['year']; // e.g., "2024-2025"
        final String termString = termMap['term']; // "1" or "2"

        // Parse year from "2024-2025" format
        final yearMatch = RegExp(r'(\d{4})-\d{4}').firstMatch(yearString);
        if (yearMatch == null) continue;

        final schoolYear = yearString;
        final name = termString; // "1" for first semester, "2" for second

        // Generate a unique semester ID from year and term
        // Format: startYear * 10 + term (e.g., 20241 for 2024-2025 first semester)
        final startYear = int.parse(yearMatch.group(1)!);
        final semesterId = '${startYear}0$termString';

        semesters.add(SemesterInfo(semesterId, schoolYear, name));
      }

      return semesters;
    });
  }

  /// Load all exam scores for graduate students.
  ///
  /// Returns all scores across all semesters.
  Future<List<ExamScore>> loadExamScore() {
    final options = RequestOptions(
      method: "GET",
      path: _SCORE_URL,
    );
    return FudanSession.request(
      options,
      (response) {
        final Map<String, dynamic> data = response.data;

        final String? code = data['code'];
        if (code != '0') {
          throw GraduateExamException('Failed to load scores: code=$code');
        }

        final Map<String, dynamic> datas = data['datas'];
        final Map<String, dynamic> jdjscjcx = datas['jdjscjcx'];
        final List<dynamic> rows = jdjscjcx['rows'];

        final scores = <ExamScore>[];
        for (final row in rows) {
          final Map<String, dynamic> scoreMap = row;
          scores.add(ExamScore.fromGraduateJson(scoreMap));
        }

        return scores;
      },
      manualLoginUrl: Uri.parse(_SCORE_LOGIN_URL),
    );
  }
}

/// Exception for graduate exam/score related errors.
class GraduateExamException implements Exception {
  final String message;

  GraduateExamException(this.message);

  @override
  String toString() => 'GraduateExamException: $message';
}
