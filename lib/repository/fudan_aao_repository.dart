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
import 'package:dio/dio.dart';
import 'package:html/dom.dart';

/// This repository is also designed to check whether the app is connected to the school LAN.
class FudanAAORepository extends BaseRepositoryWithDio {
  static const String _LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=http%3A%2F%2Fwww.jwc.fudan.edu.cn%2Fa7%2F97%2Fc9397a305047%2Fpage.psp";

  FudanAAORepository._() {
    initRepository();
  }

  static String _listUrl(String type, int page) {
    return "http://www.jwc.fudan.edu.cn/$type/list${page <= 1 ? "" : page.toString()}.htm";
  }

  static const String _BASE_URL = "http://www.jwc.fudan.edu.cn";
  static const String TYPE_NOTICE_ANNOUNCEMENT = "9397";
  static final _instance = FudanAAORepository._();

  factory FudanAAORepository.getInstance() => _instance;

  Future<List<Notice>> getNotices(
      String type, int page, PersonInfo info) async {
    await UISLoginTool.getInstance().loginUIS(dio, _LOGIN_URL, cookieJar, info);
    List<Notice> notices = [];
    Response response = await dio.get(_listUrl(type, page));
    if (response.data.toString().contains("Under Maintenance")) {
      throw NotConnectedToLANError();
    }
    Beautifulsoup soup = Beautifulsoup(response.data.toString());
    List<Element> noticeNodes = soup
        .find_all(".wp_article_list_table > tbody > tr > td > table > tbody");
    for (Element noticeNode in noticeNodes) {
      List<Element> noticeInfo =
          noticeNode.querySelector("tr").querySelectorAll("td");
      notices.add(Notice(
          noticeInfo[0].text.trim(),
          _BASE_URL + noticeInfo[0].querySelector("a").attributes["href"],
          noticeInfo[1].text.trim()));
    }
    return notices;
  }

  Future<bool> checkConnection(PersonInfo info) =>
      getNotices(TYPE_NOTICE_ANNOUNCEMENT, 1, info)
          .then((value) => true, onError: (e) => false);
}

class NotConnectedToLANError implements Exception {}

class Notice {
  String title;
  String url;
  String time;

  Notice(this.title, this.url, this.time);
}
