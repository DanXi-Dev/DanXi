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
import 'package:dan_xi/repository/inpersistent_cookie_manager.dart';
import 'package:dan_xi/util/retryer.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart';

class FudanAAORepository extends BaseRepositoryWithDio {
  static const String _LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=http%3A%2F%2Fjwc.fudan.edu.cn%2Feb%2Fb7%2Fc9397a388023%2Fpage.psp";

  FudanAAORepository._();

  static String _listUrl(String type, int page) {
    return "https://jwc.fudan.edu.cn/$type/list${page <= 1 ? "" : page.toString()}.htm";
  }

  static const String _BASE_URL = "https://jwc.fudan.edu.cn";
  static const String TYPE_NOTICE_ANNOUNCEMENT = "9397";
  static final _instance = FudanAAORepository._();

  PersonInfo? _info;

  factory FudanAAORepository.getInstance() => _instance;

  Future<NonpersistentCookieJar?> get thisCookies async {
    // Log in before getting cookies.
    await Retrier.runAsyncWithRetry(
            () => UISLoginTool.fixByLoginUIS(
            dio!, _LOGIN_URL, cookieJar!, _info, true),
        retryTimes: 3);
    return cookieJar;
  }

  Future<List<Notice>> getNotices(
      String type, int page, PersonInfo? info) async {
    _info = info;
    return Retrier.tryAsyncWithFix(
        () => _getNotices(type, page),
            (exception) => UISLoginTool.fixByLoginUIS(
            dio!, _LOGIN_URL, cookieJar!, info, true));
  }

  Future<List<Notice>> _getNotices(String type, int page) async {
    List<Notice> notices = [];
    Response response = await dio!.get(_listUrl(type, page));
    if (response.data.toString().contains("Under Maintenance")) {
      throw NotConnectedToLANError();
    }
    BeautifulSoup soup = BeautifulSoup(response.data.toString());
    Iterable<Element> noticeNodes = soup
        .findAll(".wp_article_list_table > tbody > tr > td > table > tbody")
        .map((e) => e.element!);
    for (Element noticeNode in noticeNodes) {
      List<Element> noticeInfo =
          noticeNode.querySelector("tr")!.querySelectorAll("td");
      notices.add(Notice(
          noticeInfo[0].text.trim(),
          _BASE_URL + noticeInfo[0].querySelector("a")!.attributes["href"]!,
          noticeInfo[1].text.trim()));
    }
    return notices;
  }

  Future<bool> checkConnection(PersonInfo? info) =>
      getNotices(TYPE_NOTICE_ANNOUNCEMENT, 1, info)
          .then((value) => true, onError: (e) => false);

  @override
  String get linkHost => "jwc.fudan.edu.cn";
}

class NotConnectedToLANError implements Exception {}

class Notice {
  String title;
  String url;
  String time;

  Notice(this.title, this.url, this.time);
}
