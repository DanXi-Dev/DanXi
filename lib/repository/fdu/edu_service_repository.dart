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
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/time_table_repository.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/type_requires.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
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
      final contextGetter = () => (options, res);

      final Map<String, dynamic> data = require(res.data, contextGetter);
      final List<dynamic> vms = require(data["studentTableVms"], contextGetter);
      final Map<String, dynamic> vm = require(vms[0], contextGetter);
      // Intentionally typed as int to fail fast if backend changes the schema.
      // If it was `final int = vm["id"].toString;`, it would be hard to catch
      // the bug.
      final int idInt = require(vm["id"], contextGetter);
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
      final contextGetter = () => (options, res);

      final String data = require(res.data, contextGetter);
      final soup = BeautifulSoup(data);
      // Use this selector to filter out finished exams.
      final elements = soup.findAll(
        "table.exam-table tbody tr:not(.tr-empty):not([data-finished=\"true\"])",
      );

      final exams = elements
          .map((element) => element.findAll("td"))
          .where((cells) => cells.length >= 4)
          .map((cells) => Exam.fromJwglHtml(cells))
          .toList(growable: false);

      return exams;
    });
  }

  Future<List<ExamScore>> loadExamScoreList(
    String studentId,
    String semesterId,
  ) async {
    final options = RequestOptions(
      method: "GET",
      path: getGradeSheetUrl(studentId, semesterId),
    );
    return FudanSession.request(options, (res) {
      final contextGetter = () => (options, res);

      final Map<String, dynamic> data = require(res.data, contextGetter);
      final Map<String, dynamic> semesterId2StudentGrades = require(
        data["semesterId2studentGrades"],
        contextGetter,
      );
      final List<dynamic> grades = require(
        semesterId2StudentGrades[semesterId],
        contextGetter,
      );

      final scores = grades
          .whereType<Map<String, dynamic>>()
          .map((grade) => ExamScore.fromJwglJson(grade))
          .toList(growable: false);

      return scores;
    });
  }

  Future<List<GpaListItem>> loadGpaList(String studentId) async {
    final searchIndexOptions = RequestOptions(
      method: "GET",
      path: getMyGpaSearchIndexUrl(studentId),
    );
    final (gradeYear, deptAssoc) = await FudanSession.request(
      searchIndexOptions,
      (res) {
        final contextGetter = () => (searchIndexOptions, res);
        final String data = require(res.data, contextGetter);
        final soup = BeautifulSoup(data);
        final gradeYearElement = requireNotNull(
          soup.find("input[name=\"grade\"]"),
          contextGetter,
        );
        final gradeYear = requireNotNull(
          gradeYearElement.attributes["value"],
          contextGetter,
        );
        final deptAssocElement = requireNotNull(
          soup.find("input[name=\"departmentAssoc\"]"),
          contextGetter,
        );
        final deptAssoc = requireNotNull(
          deptAssocElement.attributes["value"],
          contextGetter,
        );

        return (gradeYear, deptAssoc);
      },
    );

    // get department GPA ranks
    final searchOptions = RequestOptions(
      method: "GET",
      path: getMyGpaSearchUrl(studentId, gradeYear, deptAssoc),
    );
    return FudanSession.request(searchOptions, (res) {
      final contextGetter = () => (searchOptions, res);

      final Map<String, dynamic> data = require(res.data, contextGetter);
      final List<dynamic> ranks = require(data["data"], contextGetter);

      final gpaListItems = ranks
          .whereType<Map<String, dynamic>>()
          .map((rank) => GpaListItem.fromJwglJson(rank))
          .toList(growable: false);

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
    for (String char in jsonLikeText.runes.map(
      (rune) => String.fromCharCode(rune),
    )) {
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

enum SemesterSeason {
  AUTUMN,
  SPRING,
  SUMMER,
  WINTER;

  int get code => index + 1;

  String getDisplayedName(BuildContext context) {
    return switch (this) {
      AUTUMN => S.of(context).season_autumn,
      SPRING => S.of(context).season_spring,
      SUMMER => S.of(context).season_summer,
      WINTER => S.of(context).season_winter,
    };
  }
}

class SemesterInfo {
  final String semesterId;
  final String schoolYear;
  final SemesterSeason season;

  SemesterInfo(this.semesterId, this.schoolYear, this.season);

  /// Example:
  ///
  /// {
  //    "startDate" : "2026-03-01",
  //    "endDate" : "2026-07-04",
  //    "name" : "2025-2026学年2学期",
  //    "id" : 505
  //  }
  factory SemesterInfo.fromCourseTableJson(Map<String, dynamic> json) {
    final contextGetter = () => json;

    final int idInt = require(json["id"], contextGetter);
    final id = idInt.toString();
    final String name = require(json["name"], contextGetter);
    final (schoolYearNullable, seasonNullable) = _parseYearAndSeason(name);
    final schoolYear = requireNotNull(schoolYearNullable, contextGetter);
    final season = requireNotNull(seasonNullable, contextGetter);
    return SemesterInfo(id, schoolYear, season);
  }

  static final _nameRegex = RegExp(
    "\\D*(\\d{4}-\\d{4})\\D+(\\d+|autumn|fall|秋|一|上|spring|春|二|下|summer|夏|暑|三|winter|冬|寒|四)\\D*",
    caseSensitive: false,
  );

  static SemesterSeason? _normalizeSeason(String seasonRaw) {
    final seasonInt = int.tryParse(seasonRaw);
    if (seasonInt != null) {
      return SemesterSeason.values.elementAtOrNull(seasonInt - 1);
    }
    return switch (seasonRaw.toLowerCase()) {
      "autumn" || "fall" || "秋" || "一" || "上" => SemesterSeason.AUTUMN,
      "spring" || "春" || "二" || "下" => SemesterSeason.SPRING,
      "summer" || "夏" || "暑" || "三" => SemesterSeason.SUMMER,
      "winter" || "冬" || "寒" || "四" => SemesterSeason.WINTER,
      _ => null,
    };
  }

  static (String?, SemesterSeason?) _parseYearAndSeason(String name) {
    final nameMatch = _nameRegex.firstMatch(name);
    if (nameMatch == null) {
      return (null, null);
    }
    final schoolYear = nameMatch.group(1);
    final seasonRaw = nameMatch.group(2);
    if (seasonRaw == null) {
      return (schoolYear, null);
    }
    final season = _normalizeSeason(seasonRaw);
    return (schoolYear, season);
  }

  bool matchName(String name) {
    final yearAndSeason = _parseYearAndSeason(name);
    final (schoolYear, season) = yearAndSeason;
    return this.schoolYear == schoolYear && this.season == season;
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

  Exam(
    this.id,
    this.name,
    this.type,
    this.date,
    this.time,
    this.location,
    this.testCategory,
    this.note,
  );

  factory Exam.fromJwglHtml(List<Bs4Element> cells) {
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
        category = categoryText.substring(1, categoryText.length - 1).trim();
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
    return exam;
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

  factory ExamScore.fromJwglJson(Map<String, dynamic> json) {
    // It can be null too.
    final String? lessonCode = json["lessonCode"];
    final String? courseCode = json["courseCode"];
    // We are not sure whether these fields can be null, so we try as more
    // fields as we could get.
    final String? courseName = json["courseName"];
    final String? courseNameEn = json["courseNameEn"];
    final String? courseModuleTypeName = json["courseModuleTypeName"];
    final String? courseType = json["courseType"];
    final String? gaGrade = json["gaGrade"];
    // PNP courses have no GP.
    final num? gp = json["gp"];
    final score = ExamScore(
      (lessonCode ?? courseCode).toString(),
      (courseName ?? courseNameEn).toString(),
      (courseModuleTypeName ?? courseType).toString(),
      null.toString(),
      gaGrade.toString(),
      gp?.toString(),
    );
    return score;
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
      null,
    );
  }

  /// Parse from graduate student score JSON.
  ///
  /// Expected JSON format:
  /// ```json
  /// {
  ///     "KCMC": "Course Name",
  ///     "KCDM": "Course Code",
  ///     "XF": 2.0,
  ///     "KCLBMC": "Course Type",
  ///     "CJ": "A",
  ///     "JDZ": 4.0
  /// }
  /// ```
  factory ExamScore.fromGraduateJson(Map<String, dynamic> json) {
    final String id = json['KCDM']?.toString() ?? '';
    final String name = json['KCMC']?.toString() ?? '';
    final String type = json['KCLBMC']?.toString() ?? '';
    final num? credit = json['XF'];
    final String level = json['CJ']?.toString() ?? '';
    final num? gpa = json['JDZ'];

    return ExamScore(
      id,
      name,
      type,
      credit?.toString() ?? '',
      level,
      gpa?.toString(),
    );
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

  GpaListItem(
    this.name,
    this.id,
    this.gpa,
    this.credits,
    this.rank,
    this.year,
    this.major,
    this.college,
  );

  factory GpaListItem.fromJwglJson(Map<String, dynamic> json) {
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
    final String? name = json["name"];
    final String? code = json["code"];
    final num? gpa = json["gpa"];
    // Some courses have credit of 0.5.
    final num? credit = json["credit"];
    final int? ranking = json["ranking"];
    final String? grade = json["grade"];
    final String? major = json["major"];
    final String? department = json["department"];
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
    return item;
  }
}

class SemesterNoExamException implements Exception {}

class ClickTooFastException implements Exception {}
