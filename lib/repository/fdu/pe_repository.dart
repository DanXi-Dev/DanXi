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
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/uis_login_tool.dart';
import 'package:dan_xi/util/retrier.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart' as dom;

class FudanPERepository extends BaseRepositoryWithDio {
  static const String _LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=http%3A%2F%2Ftac.fudan.edu.cn%2Fthirds%2Ftjb.act%3Fredir%3DsportScore";
  static const String _INFO_URL =
      "https://fdtyjw.fudan.edu.cn/sportScore/stScore.aspx";

  FudanPERepository._();

  static final _instance = FudanPERepository._();

  factory FudanPERepository.getInstance() => _instance;

  Future<List<ExerciseItem>?> loadExerciseRecords(PersonInfo? info) =>
      Retrier.runAsyncWithRetry(() => _loadExerciseRecords(info));

  Future<List<ExerciseItem>?> _loadExerciseRecords(PersonInfo? info) async {
    // PE system request a token from UIS to log in.
    String token = "";
    await UISLoginTool.loginUIS(dio, _LOGIN_URL, cookieJar!, info, true)
        .catchError((e) {
      if (e is DioException && e.type == DioExceptionType.badResponse) {
        String url = e.response!.requestOptions.path;
        token = Uri.tryParse(url)!.queryParameters['token']!;
      }
      return null;
    });
    final List<ExerciseItem> items = [];
    final Response<String> r = await dio.get("$_INFO_URL?token=$token");
    final BeautifulSoup soup = BeautifulSoup(r.data!);
    final Iterable<dom.Element> tableLines = soup
        .findAll(
            "#pAll > table > tbody > tr:nth-child(6) > td > table > tbody > tr")
        .map((e) => e.element!);

    if (tableLines.isEmpty) throw "Unable to get the data";

    for (var line in tableLines) {
      items.addAll(ExerciseItem.fromHtml(line));
    }
    return items;
  }

  @override
  String get linkHost => "fdtyjw.fudan.edu.cn";
}

class ExerciseItem {
  final String title;
  final int? times;

  ExerciseItem(this.title, this.times);

  static List<ExerciseItem> fromHtml(dom.Element html) {
    List<ExerciseItem> list = [];
    List<dom.Element> elements = html.getElementsByTagName("td");
    for (int i = 0; i < elements.length; i += 2) {
      list.add(ExerciseItem(elements[i].text.trim().replaceFirst("：", ""),
          int.tryParse(elements[i + 1].text.trim())));
    }
    return list;
  }
}
