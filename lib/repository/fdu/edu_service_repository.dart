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
import 'dart:io';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/uis_login_tool.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart' as dom;

class EduServiceRepository extends BaseRepositoryWithDio {
  static const String EXAM_TABLE_LOGIN_URL =
      'https://uis.fudan.edu.cn/authserver/login?service=http%3A%2F%2Fjwfw.fudan.edu.cn%2Feams%2FstdExamTable%21examTable.action';
  static const String EXAM_TABLE_URL =
      'https://jwfw.fudan.edu.cn/eams/stdExamTable!examTable.action';

  static String kExamScoreUrl(semesterId) =>
      'https://jwfw.fudan.edu.cn/eams/teach/grade/course/person!search.action?semesterId=$semesterId';

  static const String GPA_URL =
      "https://jwfw.fudan.edu.cn/eams/myActualGpa!search.action";

  static const String SEMESTER_DATA_URL =
      "https://jwfw.fudan.edu.cn/eams/dataQuery.action";

  static const String HOST = "https://jwfw.fudan.edu.cn/eams/";
  static const String KEY_TIMETABLE_CACHE = "timetable";
  static const String ID_URL =
      'https://jwfw.fudan.edu.cn/eams/courseTableForStd.action';
  static const Map<String, String> _JWFW_HEADER = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:84.0) Gecko/20100101 Firefox/84.0",
    "Accept": "text/xml",
    "Accept-Language": "zh-CN,en-US;q=0.7,en;q=0.3",
    "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
    "Origin": "https://jwfw.fudan.edu.cn",
    "Connection": "keep-alive",
  };

  @override
  String get linkHost => "jwfw.fudan.edu.cn";

  EduServiceRepository._();

  static final _instance = EduServiceRepository._();

  factory EduServiceRepository.getInstance() => _instance;

  Future<List<Exam>?> loadExamListRemotely(PersonInfo? info,
          {String? semesterId}) =>
      UISLoginTool.tryAsyncWithAuth(dio, EXAM_TABLE_LOGIN_URL, cookieJar!, info,
          () => _loadExamList(semesterId: semesterId));

  Future<String?> get semesterIdFromCookie async =>
      (await cookieJar!.loadForRequest(Uri.parse(HOST)))
          .firstWhere((element) => element.name == "semester.id",
              orElse: () => Cookie("semester.id", ""))
          .value;

  Future<List<Exam>?> _loadExamList({String? semesterId}) async {
    String? oldSemesterId = await semesterIdFromCookie;
    // Set the semester id
    if (semesterId != null) {
      cookieJar?.saveFromResponse(
          Uri.parse(HOST), [Cookie("semester.id", semesterId)]);
    }
    final Response<String> r = await dio.get(EXAM_TABLE_URL,
        options: Options(headers: Map.of(_JWFW_HEADER)));

    // Restore old semester id
    if (oldSemesterId != null) {
      cookieJar?.saveFromResponse(
          Uri.parse(HOST), [Cookie("semester.id", oldSemesterId)]);
    }
    final BeautifulSoup soup = BeautifulSoup(r.data!);
    final dom.Element tableBody = soup.find("tbody")!.element!;
    return tableBody
        .getElementsByTagName("tr")
        .map((e) => Exam.fromHtml(e))
        .toList();
  }

  Future<List<ExamScore>?> loadExamScoreRemotely(PersonInfo? info,
          {String? semesterId}) =>
      UISLoginTool.tryAsyncWithAuth(dio, EXAM_TABLE_LOGIN_URL, cookieJar!, info,
          () => _loadExamScore(semesterId));

  Future<List<ExamScore>?> _loadExamScore([String? semesterId]) async {
    final Response<String> r = await dio.get(
        kExamScoreUrl(semesterId ?? await semesterIdFromCookie),
        options: Options(headers: Map.of(_JWFW_HEADER)));
    final BeautifulSoup soup = BeautifulSoup(r.data!);
    final dom.Element tableBody = soup.find("tbody")!.element!;
    return tableBody
        .getElementsByTagName("tr")
        .map((e) => ExamScore.fromEduServiceHtml(e))
        .toList();
  }

  Future<List<GPAListItem>?> loadGPARemotely(PersonInfo? info) =>
      UISLoginTool.tryAsyncWithAuth(
          dio, EXAM_TABLE_LOGIN_URL, cookieJar!, info, () => _loadGPA());

  Future<List<GPAListItem>?> _loadGPA() async {
    final Response<String> r =
        await dio.get(GPA_URL, options: Options(headers: Map.of(_JWFW_HEADER)));
    final BeautifulSoup soup = BeautifulSoup(r.data!);
    final dom.Element tableBody = soup.find("tbody")!.element!;
    return tableBody
        .getElementsByTagName("tr")
        .map((e) => GPAListItem.fromHtml(e))
        .toList();
  }

  /// Load the semesters id & name, etc.
  ///
  /// Returns an unpacked list of [SemesterInfo].
  Future<List<SemesterInfo>?> loadSemesters(PersonInfo? info) =>
      UISLoginTool.tryAsyncWithAuth(
          dio, EXAM_TABLE_LOGIN_URL, cookieJar!, info, () => _loadSemesters());

  Future<List<SemesterInfo>?> _loadSemesters() async {
    await dio.get(EXAM_TABLE_URL,
        options: Options(headers: Map.of(_JWFW_HEADER)));
    final Response<String> semesterResponse = await dio.post(SEMESTER_DATA_URL,
        data: "dataType=semesterCalendar&empty=false",
        options: Options(contentType: 'application/x-www-form-urlencoded'));
    final BeautifulSoup soup = BeautifulSoup(semesterResponse.data!);

    final jsonText = _normalizeJson(soup.getText().trim());
    final json = jsonDecode(jsonText);
    final Map<String, dynamic> semesters = json['semesters'];
    List<SemesterInfo> sems = [];
    for (var element in semesters.values) {
      if (element is List && element.isNotEmpty) {
        var annualSemesters = element.map((e) => SemesterInfo.fromJson(e));
        sems.addAll(annualSemesters);
      }
    }
    if (sems.isEmpty) throw "Retrieval failed";
    return sems;
  }

  /// JSON Like Text: {aaaa:"asdasd"}
  /// Real JSON Text: {"aaaa":"asdasd"}
  ///
  /// Add a pair of quote on the both sides of every key.
  String _normalizeJson(String jsonLikeText) {
    var result = "";
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
  static const MAP_LEVEL_SCORE = {
    "A": "4.0",
    "A-": "3.7",
    "B+": "3.3",
    "B": "3.0",
    "B-": "2.7",
    "C+": "2.3",
    "C": "2.0",
    "C-": "1.7",
    "D+": "1.3",
    "D": "1.0",
    "F": "0",
  };

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
        elements[1].text.trim() + ' ' + elements[2].text.trim(),
        elements[4].text.trim(),
        elements[5].text.trim(),
        MAP_LEVEL_SCORE[elements[5].text.trim()]);
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
