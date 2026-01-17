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

  /// Load all semesters and their start dates, etc.
  ///
  /// Returns a [SemesterBundle].
  Future<SemesterBundle> loadSemesterBundle() =>
      TimeTableRepository.getInstance().loadSemestersForTimeTable();

  /// Get student ID from course table API
  Future<String> loadStudentId(String defaultSemesterId) async {
    final options = RequestOptions(
      method: "GET",
      path: getSemesterCourseTableUrl(defaultSemesterId),
    );
    return FudanSession.request(options, (res) {
      final Map<String, dynamic> data = res.data!;
      final List<dynamic> vms = data["studentTableVms"];
      final Map<String, dynamic> vm = vms[0];
      // Intentionally typed as int to fail fast if backend changes the schema.
      // If it was `final int = vm["id"].toString;`, it would be hard to catch
      // the bug.
      final int idInt = vm["id"];
      final id = idInt.toString();
      return id;
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
  Future<List<Exam>> loadExamList(String studentId) async {
    final options = RequestOptions(
      method: "GET",
      path: getExamArrangeUrl(studentId),
    );
    return await FudanSession.request(options, (res) {
      final soup = BeautifulSoup(res.data!);
      // Use this selector to filter out finished exams.
      final elements = soup.findAll(
        "table.exam-table tbody tr:not(.tr-empty):not([data-finished=\"true\"])",
      );

      final exams = <Exam>[];
      for (final element in elements) {
        final cells = element.findAll("td");
        if (cells.length < 4) {
          continue;
        }

        String? courseId;
        String? courseName;
        String? type;
        String? category;
        String? date;
        String? time;
        String? location;
        String note;

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
          courseName = spans[0].text.trimAndNormalizeWhitespace();
          courseId = spans[1].text.trimAndNormalizeWhitespace();

          final categoryText = spans[2].text.trimAndNormalizeWhitespace();
          if (categoryText.startsWith("（") && categoryText.endsWith("）")) {
            category =
                categoryText.substring(1, categoryText.length - 1).trim();
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
          courseId.toString(),
          courseName.toString(),
          type.toString(),
          date.toString(),
          time.toString(),
          location.toString(),
          category.toString(),
          note,
        );
        exams.add(exam);
      }

      return exams;
    });
  }

  Future<List<ExamScore>> loadExamScoreList(String studentId,
      String semesterId) async {
    final options = RequestOptions(
      method: "GET",
      path: getGradeSheetUrl(studentId, semesterId),
    );
    return FudanSession.request(options, (res) {
      final Map<String, dynamic> data = res.data!;
      final Map<String, dynamic> semesterId2StudentGrades =
          data["semesterId2studentGrades"];
      final List<dynamic> grades =
          semesterId2StudentGrades[semesterId] ?? const [];

      final scores = <ExamScore>[];
      for (final gradeJson in grades) {
        final Map<String, dynamic> grade = gradeJson;
        // It can be null too.
        final String? lessonCode = grade["lessonCode"];
        final String? courseCode = grade["courseCode"];
        // We are not sure whether these fields can be null, so we try as more
        // fields as we could get.
        final String? courseName = grade["courseName"];
        final String? courseNameEn = grade["courseNameEn"];
        final String? courseModuleTypeName = grade["courseModuleTypeName"];
        final String? courseType = grade["courseType"];
        final String? gaGrade = grade["gaGrade"];
        // PNP courses have no GP.
        final num? gp = grade["gp"];
        final score = ExamScore(
          (lessonCode ?? courseCode).toString(),
          (courseName ?? courseNameEn).toString(),
          (courseModuleTypeName ?? courseType).toString(),
          null.toString(),
          gaGrade.toString(),
          gp?.toString(),
        );
        scores.add(score);
      }

      return scores;
    });
  }

  Future<List<GpaListItem>> loadGpaList(String studentId) async {
    final searchIndexOptions = RequestOptions(
      method: "GET",
      path: getMyGpaSearchIndexUrl(studentId),
    );
    final (gradeYear, deptAssoc) =
        await FudanSession.request(searchIndexOptions, (res) {
      final soup = BeautifulSoup(res.data!);
      final gradeYearElement = soup.find("input[name=\"grade\"]")!;
      final gradeYear = gradeYearElement.attributes["value"]!;
      final deptAssocElement = soup.find("input[name=\"departmentAssoc\"]")!;
      final deptAssoc = deptAssocElement.attributes["value"]!;

      return (gradeYear, deptAssoc);
    });

    // get department GPA ranks
    final searchOptions = RequestOptions(
      method: "GET",
      path: getMyGpaSearchUrl(studentId, gradeYear, deptAssoc),
    );
    return FudanSession.request(searchOptions, (res) {
      final Map<String, dynamic> data = res.data;
      final List<dynamic> ranks = data["data"] ?? [];

      final List<GpaListItem> gpaListItems = [];
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
        final String? name = rank["name"];
        final String? code = rank["code"];
        final num? gpa = rank["gpa"];
        // Some courses have credit of 0.5.
        final num? credit = rank["credit"];
        final int? ranking = rank["ranking"];
        final String? grade = rank["grade"];
        final String? major = rank["major"];
        final String? department = rank["department"];
        final item = GpaListItem(
          name.toString(),
          code.toString(),
          gpa.toString(),
          credit.toString(),
          ranking.toString(),
          grade.toString(),
          major.toString(),
          department.toString(),
        );
        gpaListItems.add(item);
      }

      return gpaListItems;
    });
  }

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
    final (schoolYear, season) = parseYearAndSeason(name)!;
    return SemesterInfo(id, schoolYear, season);
  }

  static (String, String)? parseYearAndSeason(String name) {
    final nameRegex = RegExp("\\D*(\\d{4}-\\d{4})\\D+(\\d+)\\D*");
    final nameMatch = nameRegex.firstMatch(name);
    if (nameMatch == null) {
      return null;
    }
    final schoolYear = nameMatch.group(1);
    final season = nameMatch.group(2);
    if (schoolYear == null || season == null) {
      return null;
    }
    return (schoolYear, season);
  }

  bool matchName(String name) {
    final yearAndSeason = parseYearAndSeason(name);
    if (yearAndSeason == null) {
      return false;
    }
    final (schoolYear, season) = yearAndSeason;
    return this.schoolYear == schoolYear && this.name == season;
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
}

class ExamScore {
  final String id;
  final String name;
  final String type;
  final String credit;
  final String level;
  final String? score;

  ExamScore(this.id, this.name, this.type, this.credit, this.level, this.score);

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

class GpaListItem {
  final String name;
  final String id;
  final String year;
  final String major;
  final String college;
  final String gpa;
  final String credits;
  final String rank;

  GpaListItem(this.name, this.id, this.gpa, this.credits, this.rank, this.year,
      this.major, this.college);
}

class SemesterNoExamException implements Exception {}

class ClickTooFastException implements Exception {}
