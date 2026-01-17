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

  /// Load all exam scores for graduate students.
  ///
  /// Returns all scores across all semesters.
  Future<List<ExamScore>> loadExamScore() {
    final options = RequestOptions(method: "GET", path: _SCORE_URL);
    return FudanSession.request(options, (response) {
      final Map<String, dynamic> data = response.data;

      final String? code = data['code'];
      if (code != '0') {
        throw GraduateExamException('Failed to load scores: code=$code');
      }

      final Map<String, dynamic> datas = data['datas'];
      final Map<String, dynamic> jdjscjcx = datas['jdjscjcx'];
      final List<dynamic> rows = jdjscjcx['rows'];

      return rows
          .map((row) => ExamScore.fromGraduateJson(row as Map<String, dynamic>))
          .toList();
    }, manualLoginUrl: Uri.parse(_SCORE_LOGIN_URL));
  }
}

/// Exception for graduate exam/score related errors.
class GraduateExamException implements Exception {
  final String message;

  GraduateExamException(this.message);

  @override
  String toString() => 'GraduateExamException: $message';
}
