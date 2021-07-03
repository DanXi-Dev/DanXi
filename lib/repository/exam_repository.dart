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

import 'package:beautifulsoup/beautifulsoup.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/uis_login_tool.dart';
import 'package:dan_xi/util/retryer.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart' as DOM;

class EduServiceRepository extends BaseRepositoryWithDio {
  static const String EXAM_TABLE_LOGIN_URL =
      'https://uis.fudan.edu.cn/authserver/login?service=http%3A%2F%2Fjwfw.fudan.edu.cn%2Feams%2FstdExamTable%21examTable.action';
  static const String EXAM_TABLE_URL =
      'https://jwfw.fudan.edu.cn/eams/stdExamTable!examTable.action';

  static String kExamScoreUrl(semesterId) =>
      'https://jwfw.fudan.edu.cn/eams/teach/grade/course/person!search.action?semesterId=$semesterId';

  static const String kGPAUrl =
      "https://jwfw.fudan.edu.cn/eams/myActualGpa!search.action";

  static const String HOST = "https://jwfw.fudan.edu.cn/eams/";
  static const String KEY_TIMETABLE_CACHE = "timetable";

  EduServiceRepository._() {
    initRepository();
  }

  static final _instance = EduServiceRepository._();

  factory EduServiceRepository.getInstance() => _instance;

  Future<List<Exam>> loadExamListRemotely(PersonInfo info) =>
      Retrier.tryAsyncWithFix(
          () => _loadExamList(),
          (exception) => UISLoginTool.getInstance()
              .loginUIS(dio, EXAM_TABLE_LOGIN_URL, cookieJar, info));

  Future<List<Exam>> _loadExamList() async {
    Response r = await dio.get(EXAM_TABLE_URL);
    Beautifulsoup soup = Beautifulsoup(r.data.toString());
    DOM.Element tableBody = soup.find(id: "tbody");
    return tableBody
        .getElementsByTagName("tr")
        .map((e) => Exam.fromHtml(e))
        .toList();
  }

  Future<List<ExamScore>> loadExamScoreRemotely(PersonInfo info) =>
      Retrier.tryAsyncWithFix(
          () => _loadExamScore(),
          (exception) => UISLoginTool.getInstance()
              .loginUIS(dio, EXAM_TABLE_LOGIN_URL, cookieJar, info));

  Future<List<ExamScore>> _loadExamScore() async {
    String semesterId = (await cookieJar.loadForRequest(Uri.parse(HOST)))
        .firstWhere((element) => element.name == "semester.id")
        .value;
    Response r = await dio.get(kExamScoreUrl(semesterId));
    Beautifulsoup soup = Beautifulsoup(r.data.toString());
    DOM.Element tableBody = soup.find(id: "tbody");
    return tableBody
        .getElementsByTagName("tr")
        .map((e) => ExamScore.fromHtml(e))
        .toList();
  }

  Future<List<GPAListItem>> loadGPARemotely(PersonInfo info) =>
      Retrier.tryAsyncWithFix(
          () => _loadGPA(),
          (exception) => UISLoginTool.getInstance()
              .loginUIS(dio, EXAM_TABLE_LOGIN_URL, cookieJar, info));

  Future<List<GPAListItem>> _loadGPA() async {
    Response r = await dio.get(kGPAUrl);
    Beautifulsoup soup = Beautifulsoup(r.data.toString());
    DOM.Element tableBody = soup.find(id: "tbody");
    return tableBody
        .getElementsByTagName("tr")
        .map((e) => GPAListItem.fromHtml(e))
        .toList();
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

  factory Exam.fromHtml(DOM.Element html) {
    List<DOM.Element> elements = html.getElementsByTagName("td");
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
  final String score;

  ExamScore(this.id, this.name, this.type, this.credit, this.level, this.score);

  factory ExamScore.fromHtml(DOM.Element html) {
    List<DOM.Element> elements = html.getElementsByTagName("td");
    return ExamScore(
        elements[2].text.trim(),
        elements[3].text.trim(),
        elements[4].text.trim(),
        elements[5].text.trim(),
        elements[6].text.trim(),
        elements[7].text.trim());
  }
}

class GPAListItem {
  final String name;
  final String id;
  final String gpa;
  final String credits;
  final String rank;

  GPAListItem(this.name, this.id, this.gpa, this.credits, this.rank);

  factory GPAListItem.fromHtml(DOM.Element html) {
    List<DOM.Element> elements = html.getElementsByTagName("td");
    return GPAListItem(elements[1].text, elements[0].text, elements[5].text,
        elements[6].text, elements[7].text);
  }
}
