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

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/edu_service_repository.dart';
import 'package:dan_xi/repository/fdu/uis_login_tool.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/retrier.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart' as dom;

class DataCenterRepository extends BaseRepositoryWithDio {
  static const String LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Fmy.fudan.edu.cn%2Fsimple_list%2Fstqk";
  static const String DINING_DETAIL_URL =
      "https://my.fudan.edu.cn/simple_list/stqk";
  static const String SCORE_DETAIL_URL =
      "https://my.fudan.edu.cn/list/bks_xx_cj";
  static const String CARD_DETAIL_URL = "https://my.fudan.edu.cn/list/ykt_xx";

  DataCenterRepository._();

  static final _instance = DataCenterRepository._();

  factory DataCenterRepository.getInstance() => _instance;

  /// Divide canteens into different zones.
  /// e.g. 光华，南区，南苑，枫林，张江（枫林和张江无明显划分）
  Map<String?, Map<String, TrafficInfo>> toZoneList(
      String? areaName, Map<String, TrafficInfo>? trafficInfo) {
    Map<String?, Map<String, TrafficInfo>> zoneTraffic = {};
    if (trafficInfo == null) return zoneTraffic;

    // Divide canteens into different zones.
    // e.g. 光华，南区，南苑，枫林，张江（枫林和张江无明显划分）
    trafficInfo.forEach((key, value) {
      List<String> locations = key.split("\n");
      String? zone, canteenName;
      if (locations.length == 1) {
        zone = areaName;
      } else {
        zone = locations[0];
        locations.removeAt(0);
      }
      canteenName = locations.join(' ');
      if (!zoneTraffic.containsKey(zone)) {
        zoneTraffic[zone] = {};
      }
      zoneTraffic[zone]![canteenName] = value;
    });
    return zoneTraffic;
  }

  Future<Map<String, TrafficInfo>?> getCrowdednessInfo(
          PersonInfo? info, int areaCode) async =>
      Retrier.tryAsyncWithFix(() => _getCrowdednessInfo(areaCode),
          (exception) async {
        if (exception is! UnsuitableTimeException) {
          await UISLoginTool.loginUIS(dio!, LOGIN_URL, cookieJar!, info, true);
        }
      });

  Future<Map<String, TrafficInfo>?> _getCrowdednessInfo(int areaCode) async {
    var result = <String, TrafficInfo>{};
    Response<String> response = await dio!.get(DINING_DETAIL_URL);

    //If it's not time for a meal
    if (response.data.toString().contains("仅")) {
      throw UnsuitableTimeException();
    }
    var dataString =
        response.data!.between("}", "</script>", headGreedy: false)!;
    var jsonExtraction = RegExp(r'\[.+\]').allMatches(dataString);
    List<dynamic> names = jsonDecode(
        jsonExtraction.elementAt(areaCode * 3).group(0)!.replaceAll("'", "\""));
    List<dynamic>? cur = jsonDecode(jsonExtraction
        .elementAt(areaCode * 3 + 1)
        .group(0)!
        .replaceAll("'", "\""));
    List<dynamic>? max = jsonDecode(jsonExtraction
        .elementAt(areaCode * 3 + 2)
        .group(0)!
        .replaceAll("'", "\""));
    for (int i = 0; i < names.length; i++) {
      result[names[i]] = TrafficInfo(int.parse(cur![i]), int.parse(max![i]));
    }

    return result;
  }

  /// Load exam scores of all semesters
  ///
  /// Compared to [EduServiceRepository]'s method of the same name,
  /// this method doesn't require a Fudan LAN environment.
  ///
  /// NOTE: Result's [type] is year + semester(e.g. "2020-2021 2"),
  /// and [id] doesn't contain the last 2 digits.
  Future<List<ExamScore>?> loadAllExamScore(PersonInfo? info) =>
      UISLoginTool.tryAsyncWithAuth(
          dio!, LOGIN_URL, cookieJar!, info, () => _loadAllExamScore());

  Future<List<ExamScore>?> _loadAllExamScore() async {
    Response<String> r = await dio!.get(SCORE_DETAIL_URL);
    BeautifulSoup soup = BeautifulSoup(r.data!);
    dom.Element tableBody = soup.find("tbody")!.element!;
    return tableBody
        .getElementsByTagName("tr")
        .map((e) => ExamScore.fromDataCenterHtml(e))
        .toList();
  }

  Future<List<CardDetailInfo>?> getCardDetailInfo(PersonInfo? info) =>
      UISLoginTool.tryAsyncWithAuth(
          dio!, LOGIN_URL, cookieJar!, info, () => _getCardDetailInfo());

  Future<List<CardDetailInfo>?> _getCardDetailInfo() async {
    Response<String> r = await dio!.get(CARD_DETAIL_URL);
    BeautifulSoup soup = BeautifulSoup(r.data.toString());
    dom.Element tableBody = soup.find("tbody")!.element!;
    return tableBody
        .getElementsByTagName("tr")
        .map((e) => CardDetailInfo.fromDataCenterHtml(e))
        .toList();
  }

  @override
  String get linkHost => "my.fudan.edu.cn";
}

class UnsuitableTimeException implements Exception {}

class CardDetailInfo {
  String id;
  String name;
  String status;
  String permission;
  String expireDate;
  String balance;

  CardDetailInfo(this.id, this.name, this.status, this.permission,
      this.expireDate, this.balance);

  factory CardDetailInfo.fromDataCenterHtml(dom.Element html) {
    List<dom.Element> elements = html.getElementsByTagName("td");
    return CardDetailInfo(
        elements[0].text.trim(),
        elements[1].text.trim(),
        elements[2].text.trim(),
        elements[3].text.trim(),
        elements[4].text.trim(),
        elements[5].text.trim());
  }
}

class TrafficInfo {
  int current;
  int max;

  TrafficInfo(this.current, this.max);
}
