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
import 'package:collection/collection.dart' show IterableExtension;
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/uis_login_tool.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/retryer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:intl/intl.dart';

class CardRepository extends BaseRepositoryWithDio {
  PersonInfo? _info;
  static const String _LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Fecard.fudan.edu.cn%2Fepay%2Fj_spring_cas_security_check";
  static const String _USER_DETAIL_URL =
      "https://ecard.fudan.edu.cn/epay/myepay/index";
  static const String _CONSUME_DETAIL_URL =
      "https://ecard.fudan.edu.cn/epay/consume/query";
  static const String _CONSUME_DETAIL_CSRF_URL =
      "https://ecard.fudan.edu.cn/epay/consume/index";

  static const Map<String, String> _CONSUME_DETAIL_HEADER = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:84.0) Gecko/20100101 Firefox/84.0",
    "Accept": "text/xml",
    "Accept-Language": "zh-CN,en-US;q=0.7,en;q=0.3",
    "Content-Type": "application/x-www-form-urlencoded",
    "Origin": "https://ecard.fudan.edu.cn",
    "DNT": "1",
    "Connection": "keep-alive",
    "Referer": "https://ecard.fudan.edu.cn/epay/consume/index",
    "Sec-GPC": "1"
  };

  CardRepository._();

  static final _instance = CardRepository._();

  factory CardRepository.getInstance() => _instance;

  /// Log in before calling any method in this repository.
  Future<void> init(PersonInfo? info) async {
    _info = info;
    await UISLoginTool.loginUIS(dio!, _LOGIN_URL, cookieJar!, _info, true);
  }

  Future<String?> getName() async {
    return (await loadCardInfo(-1))?.name;
  }

  Future<Iterable<CardRecord>> _loadOnePageCardRecord(
      Map<String, String?> requestData, int pageNum) async {
    requestData['pageNo'] = pageNum.toString();
    Response detailResponse = await dio!.post(_CONSUME_DETAIL_URL,
        data: requestData.encodeMap(),
        options: Options(headers: Map.of(_CONSUME_DETAIL_HEADER)));
    BeautifulSoup soup = BeautifulSoup(
        detailResponse.data.toString().between("<![CDATA[", "]]>")!);
    List<Element> elements =
        soup.find("tbody")!.element!.querySelectorAll("tr");
    Iterable<CardRecord> records = elements.map((e) {
      List<Element> details = e.querySelectorAll("td");
      return CardRecord(
          DateTime.parse(
              "${details[0].children[0].text.trim().replaceAll('.', "-")}T${details[0].children[1].text.trim()}"),
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
  Future<List<CardRecord>?> loadCardRecord(int logDays) async {
    if (logDays < 0) return null;
    //Get csrf id.
    Response consumeCsrfPageResponse = await dio!.get(_CONSUME_DETAIL_CSRF_URL);
    BeautifulSoup consumeCsrfPageSoup =
        BeautifulSoup(consumeCsrfPageResponse.data.toString());
    Iterable<Element> metas =
        consumeCsrfPageSoup.findAll("meta").map((e) => e.element!);
    Element element = metas
        .firstWhereOrNull((element) => element.attributes["name"] == "_csrf")!;
    String? csrfId = element.attributes["content"];
    // Build the request body.
    DateTime end = DateTime.now();
    int backDays = logDays == 0 ? 30 : logDays;
    DateTime start = end.add(Duration(days: -backDays));
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    Map<String, String?> data = {
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

    // Get the number of pages, only when logDays > 0.
    int totalPages = 1;
    if (logDays > 0) {
      Response detailResponse = await dio!.post(_CONSUME_DETAIL_URL,
          data: data.encodeMap(),
          options: Options(headers: Map.of(_CONSUME_DETAIL_HEADER)));

      totalPages =
          int.parse(detailResponse.data.toString().between('</b>/', '页')!);
    }
    // Get pages.
    List<CardRecord> list = [];
    for (int pageIndex = 1; pageIndex <= totalPages; pageIndex++) {
      list.addAll(await _loadOnePageCardRecord(data, pageIndex));
    }
    return list;
  }

  Future<CardInfo?> loadCardInfo(int logDays) async {
    var cardInfo = CardInfo();

    //获取用户页面信息
    var userPageResponse = await dio!.get(_USER_DETAIL_URL);
    cardInfo.cash =
        userPageResponse.data.toString().between("<p>账户余额：", "元</p>");
    cardInfo.name = userPageResponse.data.toString().between("姓名：", "</p>");
    List<CardRecord>? records =
        await Retrier.runAsyncWithRetry(() => loadCardRecord(logDays));
    cardInfo.records = records;
    return cardInfo;
  }

  @override
  String get linkHost => "ecard.fudan.edu.cn";
}

class CardInfo {
  String? cash;
  String? name;
  List<CardRecord>? records;
}

@immutable
class CardRecord {
  final DateTime time;
  final String type;
  final String location;
  final String payment;

  const CardRecord(this.time, this.type, this.location, this.payment);
}
