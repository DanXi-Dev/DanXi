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

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/time_table_repository.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart' as dom;

import 'neo_login_tool.dart';

class EduServiceRepository extends BaseRepositoryWithDio {
  static const String COURSE_TABLE_URL =
      'https://fdjwgl.fudan.edu.cn/student/for-std/course-table';
  static String getSemesterCourseTableUrl(String semesterId) =>
      'https://fdjwgl.fudan.edu.cn/student/for-std/course-table/semester/$semesterId/print-data';
  static String getExamArrangeUrl(String studentId) =>
      'https://fdjwgl.fudan.edu.cn/student/for-std/exam-arrange/info/$studentId';
  static String getGradeSheetUrl(String studentId, String semester) =>
      'https://fdjwgl.fudan.edu.cn/student/for-std/grade/sheet/info/$studentId?semester=$semester';
  static String getMyGpaSearchIndexUrl(String studentId) =>
      'https://fdjwgl.fudan.edu.cn/student/for-std/grade/my-gpa/search-index/$studentId';
  static String getMyGpaSearchUrl(
      String studentId,
      String grade,
      String dept,
  ) =>
      'https://fdjwgl.fudan.edu.cn/student/for-std/grade/my-gpa/search?studentAssoc=$studentId&grade=$grade&departmentAssoc=$dept&majorAssoc=';

  @override
  String get linkHost => "fudan.edu.cn";

  EduServiceRepository._();

  static final _instance = EduServiceRepository._();

  factory EduServiceRepository.getInstance() => _instance;

  /// Load all semesters and their start dates
  Future<SemesterBundle> _loadSemesters() async {
    final options = RequestOptions(
      method: "GET",
      path: COURSE_TABLE_URL,
    );
    return FudanSession.request(options, (res) {
      return TimeTableRepository.getInstance()
          .parseSemesters(res.data!);
    });
  }

  /// Get student ID from course table API
  Future<String> _loadStudentId() async {
    final semesterBundle = await _loadSemesters();
    final options = RequestOptions(
      method: "GET",
      path: getSemesterCourseTableUrl(semesterBundle.defaultSemesterId),
    );
    return FudanSession.request(options, (res) {
      final Map<String, dynamic> data = res.data!;
      final List<dynamic> vms = data["studentTableVms"];
      final Map<String, dynamic> vm = vms[0];
      final int id = vm["id"];
      return id.toString();
    });
  }

  /// Get user's exam list
  ///
  /// ## API Detail
  ///
  /// This API uses the neo authentication to fetch exam information from the new endpoint.
  /// The new endpoint returns HTML with an exam table.
  ///
  /// - Returns: A list of ``Exam``, including both finished and upcoming exams
  ///
  /// Exam status:
  /// - Exams with class "finished hide" are completed exams
  /// - Exams with class "unfinished" are upcoming/pending exams
  ///
  /// ## Example HTML Response:
  /// ```html
  /// <tr data-finished="false" class="unfinished">
  ///     <td>
  ///         <div class="time">2026-01-04 08:30~10:30</div>
  ///         <div>
  ///             <span>邯郸校区</span>
  ///             <span>H邯郸校区第六教学楼</span>
  ///             <span>H6506</span>
  ///         </div>
  ///     </td>
  ///     <td>
  ///         <div>
  ///             <span>数字集成电路设计原理(H) </span>
  ///             <span>ICSE30021h.01 </span>
  ///             <span>（闭卷） </span>
  ///         </div>
  ///         <div>
  ///             <span class="tag-span type2">期末</span>
  ///         </div>
  ///     </td>
  ///     <td>请携带学生证或一卡通，待考试时核查。</td>
  ///     <td>未结束</td>
  /// </tr>
  /// <tr data-finished="true" class="finished hide">
  ///     <td>
  ///         <div class="time ">2025-11-11 13:00~15:00</div>
  ///         <div>
  ///             <span>邯郸校区</span>
  ///             <span>H邯郸校区第二教学楼</span>
  ///             <span>H2115</span>
  ///         </div>
  ///     </td>
  ///     <td>
  ///         <div>
  ///             <span>半导体器件原理(H) </span>
  ///             <span>ICSE30020h.01 </span>
  ///             <span>（半开卷） </span>
  ///         </div>
  ///         <div>
  ///             <span class="tag-span type1">期中</span>
  ///         </div>
  ///     </td>
  ///     <td>请携带学生证或一卡通，待考试时核查。</td>
  ///     <td>已结束</td>
  /// </tr>
  /// ```
  Future<List<Exam>> _loadExamList() async {
    final studentId = await _loadStudentId();
    final options = RequestOptions(
      method: "GET",
      path: getExamArrangeUrl(studentId),
    );
    return FudanSession.request(options, (res) {
      final exams = <Exam>[];

      BeautifulSoup soup = BeautifulSoup(res.data!);
      final elements = soup.findAll(
        "table.exam-table tbody tr:not(.tr-empty):not([data-finished=\"true\"])",
      );
      for (final element in elements) {
        final cells = element.findAll("td");
        if (cells.length < 4) {
          continue;
        }

        var courseId = "";
        var course = "";
        var type = "";
        var method = "";
        var date = "";
        var time = "";
        var location = "";
        var note = "";

        final firstCell = cells[0];
        final timeDiv = firstCell.find("div.time");
        final timeText = timeDiv?.text.trimAndNormalizeWhitespace();
        if (timeText != null) {
          final timeComponents = timeText.split(" ");
          if (timeComponents.length >= 2) {
            date = timeComponents[0];
            time = timeComponents[1];
          }

          final spans = firstCell.findAll("span");
          if (spans.length > 2) {
            location = spans[2].text.trimAndNormalizeWhitespace();
          }
        }

        // Course information
        final secondCell = cells[1];
        final firstDiv = secondCell.find("div");
        final spans = firstDiv?.findAll("span");
        if (spans != null && spans.length >= 3) {
          course = spans[0].text.trimAndNormalizeWhitespace();
          courseId = spans[1].text.trimAndNormalizeWhitespace();

          final methodText = spans[2].text.trimAndNormalizeWhitespace();
          if (methodText.startsWith("（") && methodText.endsWith("）")) {
            method = methodText.substring(1, methodText.length - 1).trim();
          }
        }

        // Exam type
        final divs = secondCell.findAll("div");
        if (divs.length >= 2) {
          final typeSpan = divs[1].find("span");
          final typeText = typeSpan?.text.trimAndNormalizeWhitespace();
          if (typeText != null) {
            type = typeText.trim();
          }
        }

        note = cells[2].text.trimAndNormalizeWhitespace();

        final exam = Exam(
          courseId,
          course,
          type,
          date,
          time,
          location,
          method,
          note,
        );
        exams.add(exam);
      }

      return exams;
    });
  }

  Future<List<ExamScore>> _loadExamScore(String semesterId) async {
    final studentId = await _loadStudentId();
    final options = RequestOptions(
      method: "GET",
      path: getGradeSheetUrl(studentId, semesterId),
    );
    return FudanSession.request(options, (res) {
      final Map<String, dynamic> data = res.data!;
      final Map<String, dynamic> semesterId2StudentGrades =
      data["semesterId2studentGrades"];
      final List<dynamic> grades =
          semesterId2StudentGrades[semesterId] ?? [];

      final scores = <ExamScore>[];
      for (final gradeJson in grades) {
        final Map<String, dynamic> grade = gradeJson;
        final score = ExamScore(
          grade["lessonCode"],
          grade["courseName"],
          grade["courseModuleTypeName"] ?? grade["courseType"] ?? "",
          "",
          grade["gaGrade"],
          grade["gp"].toString(),
        );
        scores.add(score);
      }

      return scores;
    });
  }

  Future<List<GPAListItem>> _loadGPA() async {
    final studentId = await _loadStudentId();
    final options = RequestOptions(
      method: "GET",
      path: getMyGpaSearchIndexUrl(studentId),
    );
    return FudanSession.request(options, (res) {
      final html = res.data!;
      final gradeRegex = RegExp("name=\"grade\"\\s+value=\"(\\d+)\"");
      final gradeMatch = gradeRegex.firstMatch(html)!;
      final deptRegex = RegExp("name=\"departmentAssoc\"\\s+value=\"(\\d+)\"");
      final deptMatch = deptRegex.firstMatch(html)!;

      // get department GPA ranks
      final options = RequestOptions(
        method: "GET",
        path: getMyGpaSearchUrl(
          studentId,
          gradeMatch.group(1)!,
          deptMatch.group(1)!,
        ),
      );
      return FudanSession.request(options, (res) {
        final Map<String, dynamic> data = res.data;
        final List<dynamic> ranks = data["data"] ?? [];

        final List<GPAListItem> items = [];
        for (final rankJson in ranks) {
          /// Example:
          /// {
          //    id: null,
          //    code: ****, // The 11-digit student ID
          //    name: ****,
          //    grade: 2022,
          //    major: 计算机科学与技术,
          //    department: 计算与智能创新学院,
          //    gpa: 3.96,
          //    credit: 130,
          //    ranking: 1
          //  }
          final Map<String, dynamic> rank = rankJson;
          final item = GPAListItem(
            rank["name"],
            rank["code"],
            rank["gpa"].toString(),
            rank["credit"].toString(),
            rank["ranking"].toString(),
            rank["grade"],
            rank["major"],
            rank["department"],
          );
          items.add(item);
        }

        return items;
      });
    });
  }

  /// Load the semesters id & name, etc.
  ///
  /// Returns an unpacked list of [SemesterInfo].
  Future<List<SemesterInfo>> loadSemestersRemotely() =>
      _loadSemesters().then((semesterBundle) => semesterBundle.semesters);

  Future<List<Exam>> loadExamListRemotely() =>
      _loadExamList();

  Future<List<ExamScore>> loadExamScoreRemotely(String semesterId) =>
      _loadExamScore(semesterId);

  Future<List<GPAListItem>> loadGPARemotely() =>
      _loadGPA();

  /// JSON-Like Text: {aaaa:"asdasd"}
  /// Real JSON Text: {"aaaa":"asdasd"}
  ///
  /// Add a pair of quote on the both sides of every key.
  /// This requires that no quote is included in the key or value. Or the result will be
  /// abnormal.
  String _normalizeJson(String jsonLikeText) {
    String result = "";
    bool inQuote = false;
    bool inKey = false;
    for (String char
        in jsonLikeText.runes.map((rune) => String.fromCharCode(rune))) {
      if (char == '"') {
        inQuote = !inQuote;
      } else if (char.isAlpha() || char.isNumber()) {
        if (!inQuote && !inKey) {
          result += '"';
          inKey = true;
        }
      } else {
        if (inKey) {
          result += '"';
          inKey = false;
        }
      }
      result += char;
    }
    return result;
  }
}

class SemesterInfo {
  final String? semesterId;
  final String? schoolYear;
  final String? name;

  SemesterInfo(this.semesterId, this.schoolYear, this.name);

  /// Example:
  /// "name":"1" means this is the first semester of the year.
  ///
  ///   {
  // 			"id": "163",
  // 			"schoolYear": "1994-1995",
  // 			"name": "1"
  // 		}
  factory SemesterInfo.fromJson(Map<String, dynamic> json) {
    return SemesterInfo(json['id'], json['schoolYear'], json['name']);
  }

  static String seasonToName(String name) {
    switch (name) {
      case "AUTUMN":
        return "1";
      case "SPRING":
        return "2";
      case "SUMMER":
        return "3";
      default:
        return "?";
    }
  }

  /// Example:
  ///
  /// {
  //    "startDate" : "2026-03-01",
  //    "endDate" : "2026-07-04",
  //    "name" : "2025-2026学年2学期",
  //    "id" : 505
  //  }
  factory SemesterInfo.fromCourseTableJson(Map<String, dynamic> json) {
    final id = json["id"].toString();
    final name = json["name"]!;
    final nameRegex = RegExp("\\D*(\\d{4}-\\d{4})\\D+(\\d+)\\D*");
    final nameMatch = nameRegex.firstMatch(name)!;
    final schoolYear = nameMatch.group(1)!;
    final season = nameMatch.group(2)!;
    return SemesterInfo(id, schoolYear, season);
  }
}

class Exam {
  final String id;
  final String name;
  final String type;
  final String date;
  final String time;
  final String location;
  final String testCategory;
  final String note;

  Exam(this.id, this.name, this.type, this.date, this.time, this.location,
      this.testCategory, this.note);

  factory Exam.fromHtml(dom.Element html) {
    List<dom.Element> elements = html.getElementsByTagName("td");
    return Exam(
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

class ExamScore {
  final String id;
  final String name;
  final String type;
  final String credit;
  final String level;
  final String? score;

  ExamScore(this.id, this.name, this.type, this.credit, this.level, this.score);

  factory ExamScore.fromEduServiceHtml(dom.Element html) {
    List<dom.Element> elements = html.getElementsByTagName("td");
    return ExamScore(
        elements[2].text.trim(),
        elements[3].text.trim(),
        elements[4].text.trim(),
        elements[5].text.trim(),
        elements[6].text.trim(),
        elements[7].text.trim());
  }

  /// NOTE: Result's [type] is year + semester(e.g. "2020-2021 2"),
  /// and [id] doesn't contain the last 2 digits.
  factory ExamScore.fromDataCenterHtml(dom.Element html) {
    List<dom.Element> elements = html.getElementsByTagName("td");
    return ExamScore(
        elements[0].text.trim(),
        elements[3].text.trim(),
        '${elements[1].text.trim()} ${elements[2].text.trim()}',
        elements[4].text.trim(),
        elements[5].text.trim(),
        null);
  }
}

class GPAListItem {
  final String name;
  final String id;
  final String year;
  final String major;
  final String college;
  final String gpa;
  final String credits;
  final String rank;

  GPAListItem(this.name, this.id, this.gpa, this.credits, this.rank, this.year,
      this.major, this.college);

  factory GPAListItem.fromHtml(dom.Element html) {
    List<dom.Element> elements = html.getElementsByTagName("td");
    return GPAListItem(
        elements[1].text,
        elements[0].text,
        elements[5].text,
        elements[6].text,
        elements[7].text,
        elements[2].text,
        elements[3].text,
        elements[4].text);
  }
}

class SemesterNoExamException implements Exception {}

class ClickTooFastException implements Exception {}
