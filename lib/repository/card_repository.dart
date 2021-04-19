/*
 *     Copyright (C) 2021  w568w
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
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/uis_login_tool.dart';
import 'package:dan_xi/util/retryer.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class CardRepository extends BaseRepositoryWithDio {
  PersonInfo _info;
  static const String LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Fecard.fudan.edu.cn%2Fepay%2Fj_spring_cas_security_check";
  static const String USER_DETAIL_URL =
      "https://ecard.fudan.edu.cn/epay/myepay/index";
  static const String CONSUME_DETAIL_URL =
      "https://ecard.fudan.edu.cn/epay/consume/query";
  static const String CONSUME_DETAIL_CSRF_URL =
      "https://ecard.fudan.edu.cn/epay/consume/index";

  static const Map<String, String> _CONSUME_DETAIL_HEADER = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:84.0) Gecko/20100101 Firefox/84.0",
    "Accept": "text/xml",
    "Accept-Language": "zh-CN,en-US;q=0.7,en;q=0.3",
    "Content-Type": "application/x-www-form-urlencoded",
    "Origin": "http://ecard.fudan.edu.cn",
    "DNT": "1",
    "Connection": "keep-alive",
    "Referer": "http://ecard.fudan.edu.cn/epay/consume/index",
    "Sec-GPC": "1"
  };

  CardRepository._() {
    initRepository();
  }

  static final _instance = CardRepository._();

  factory CardRepository.getInstance() => _instance;

  bool _testLoginSuccess() {
    return cookieJar
        .loadForRequest(Uri.parse("http://ecard.fudan.edu.cn/"))
        .any((element) => element.name == "iPlanetDirectoryPro");
  }

  Future<void> login(PersonInfo info) async {
    _info = info;
    await Retrier.runAsyncWithRetry(() async {
      try {
        await UISLoginTool.loginUIS(dio, LOGIN_URL, cookieJar, _info);
      } catch (e) {
        throw e;
      }
      if (!_testLoginSuccess()) {
        throw new LoginException();
      }
      return null;
    });
  }

  Future<String> getName() async {
    if (_info != null && _info.name.length > 0) return _info.name;
    return (await loadCardInfo(-1)).name;
  }

  Future<Iterable<CardRecord>> _loadOnePageCardRecord(
      Map<String, String> requestData, int pageNum) async {
    requestData['pageNo'] = pageNum.toString();
    var detailResponse = await dio.post(CONSUME_DETAIL_URL,
        data: requestData.encodeMap(),
        options: Options(headers: Map.of(_CONSUME_DETAIL_HEADER)));
    var soup = Beautifulsoup(
        detailResponse.data.toString().between("<![CDATA[", "]]>"));
    var elements = soup.find(id: "tbody").querySelectorAll("tr");
    Iterable<CardRecord> records = elements.map((e) {
      var details = e.querySelectorAll("td");
      return CardRecord(
          DateTime.parse(
              "${details[0].children[0].text.trim().replaceAll("\.", "-")}T${details[0].children[1].text.trim()}"),
          details[1].children[0].text.trim(),
          details[2].text.trim().replaceAll("&nbsp;", ""),
          details[3].text.trim().replaceAll("&nbsp;", ""));
    });
    return records;
  }

  /// Load the card record.
  ///
  /// If [logDays] > 0, it will return records of recent [logDays] days;
  /// If [logDays] = 0, it will return the latest records;
  /// If [logDays] < 0, it will return null.
  Future<List<CardRecord>> loadCardRecord(int logDays) async {
    print("Start load record.");
    if (logDays < 0) return null;
    //Get csrf id.
    var consumeCsrfPageResponse = await dio.get(CONSUME_DETAIL_CSRF_URL);
    var consumeCsrfPageSoup =
        Beautifulsoup(consumeCsrfPageResponse.data.toString());
    var metas = consumeCsrfPageSoup.find_all("meta");
    var element = metas.firstWhere(
        (element) => element.attributes["name"] == "_csrf",
        orElse: () => null);
    var csrfId = element.attributes["content"];
    //Build the request body.
    var end = new DateTime.now();
    int backDays = logDays == 0 ? 30 : logDays;
    var start = end.add(Duration(days: -backDays));
    var formatter = new DateFormat('yyyy-MM-dd');
    var data = {
      "aaxmlrequest": "true",
      "pageNo": "1",
      "tabNo": "1",
      "pager.offset": "10",
      "tradename": "",
      "starttime": formatter.format(start),
      "endtime": formatter.format(end),
      "timetype": "1",
      "_tradedirect": "on",
      "_csrf": csrfId,
    };

    //Get the number of pages, only when logDays > 0.
    var totalPages = 1;
    if (logDays > 0) {
      var detailResponse = await dio.post(CONSUME_DETAIL_URL,
          data: data.encodeMap(),
          options: Options(headers: Map.of(_CONSUME_DETAIL_HEADER)));

      totalPages =
          int.parse(detailResponse.data.toString().between('</b>/', '页'));
    }
    //Get pages.
    List<CardRecord> list = [];
    for (int pageIndex = 1; pageIndex <= totalPages; pageIndex++) {
      list.addAll(await _loadOnePageCardRecord(data, pageIndex));
    }
    return list;
  }

  Future<CardInfo> loadCardInfo(int logDays) async {
    if (!_testLoginSuccess()) {
      throw new LoginException();
    }
    var cardInfo = CardInfo();

    //获取用户页面信息
    var userPageResponse = await dio.get(USER_DETAIL_URL);
    cardInfo.cash =
        userPageResponse.data.toString().between("<p>账户余额：", "元</p>");
    cardInfo.name = userPageResponse.data.toString().between("姓名：", "</p>");
    List<CardRecord> records =
        await Retrier.runAsyncWithRetry(() => loadCardRecord(logDays));
    cardInfo.records = records;
    return cardInfo;
  }
}

class CardInfo {
  String cash;
  String name;
  List<CardRecord> records;

}

class CardRecord {
  DateTime time;
  String type;
  String location;
  String payment;

  CardRecord(this.time, this.type, this.location, this.payment);
}

class LoginException implements Exception {}