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
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/uis_login_tool.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart' as dom;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SportsReserveRepository extends BaseRepositoryWithDio {
  static const String LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Felife.fudan.edu.cn%2Flogin2.action";
  static const String STADIUM_LIST_URL =
      "https://elife.fudan.edu.cn/public/front/search.htm??id=2c9c486e4f821a19014f82381feb0001";
  static const String STADIUM_LIST_NUMBER_URL =
      "https://elife.fudan.edu.cn/public/front/search.htm?1=1&id=2c9c486e4f821a19014f82381feb0001&orderBack=null&fieldID=&dicID=&dicSql=&pageBean.pageNo=1&pageBean.pageSize=10";

  static sStadiumDetailUrl(String? contentId, DateTime queryDate) =>
      "https://elife.fudan.edu.cn/public/front/getResource2.htm?contentId=$contentId&ordersId=&"
      "currentDate=${DateFormat('yyyy-MM-dd').format(queryDate)}";

  SportsReserveRepository._();

  static final _instance = SportsReserveRepository._();

  factory SportsReserveRepository.getInstance() => _instance;

  Future<List<StadiumData>?> getStadiumFullList(PersonInfo info,
          {DateTime? queryDate, SportsType? type, Campus? campus}) =>
      UISLoginTool.tryAsyncWithAuth(
          dio,
          LOGIN_URL,
          cookieJar!,
          info,
          () => _getStadiumFullList(
              queryDate: queryDate, type: type, campus: campus));

  Future<int> _getStadiumPageNumber() async {
    Response<String> rep = await dio.get(STADIUM_LIST_NUMBER_URL);
    String pageNumber = rep.data!.between('页次:1/', '页')!;
    return int.parse(pageNumber);
  }

  Future<List<StadiumData>?> _getStadiumFullList(
      {DateTime? queryDate, SportsType? type, Campus? campus}) async {
    var result = <StadiumData>[];
    int pages = await _getStadiumPageNumber();
    for (int i = 1; i <= pages; i++) {
      result.addAll((await _getStadiumList(
          queryDate: queryDate, type: type, campus: campus, page: i))!);
    }
    return result;
  }

  Future<List<StadiumData>?> _getStadiumList(
      {DateTime? queryDate,
      SportsType? type,
      Campus? campus,
      int page = 1}) async {
    String body = "id=2c9c486e4f821a19014f82381feb0001&"
        "resourceDate=${queryDate == null ? '' : DateFormat('yyyy-MM-dd').format(queryDate)}&"
        "beginTime=&"
        "endTime=&"
        "fieldID=2c9c486e4f821a19014f824467b70006&"
        "dicID=&"
        "fieldID=2c9c486e4f821a19014f824535480007&"
        "dicID=${type?.id ?? ''}&"
        "pageBean.pageNo=$page";
    Response<String> res = await dio.post(STADIUM_LIST_URL,
        data: body,
        options: Options(contentType: 'application/x-www-form-urlencoded'));
    BeautifulSoup soup = BeautifulSoup(res.data!);
    Iterable<dom.Element> elements =
        soup.findAll('.order_list > table').map((e) => e.element!);

    return elements.map((e) => StadiumData.fromHtml(e)).toList();
  }

  Future<StadiumScheduleData?> getScheduleData(
          PersonInfo info, StadiumData stadium, DateTime date) =>
      UISLoginTool.tryAsyncWithAuth(dio, LOGIN_URL, cookieJar!, info,
          () => _getScheduleData(stadium, date));

  Future<StadiumScheduleData?> _getScheduleData(
      StadiumData stadium, DateTime date) async {
    Response<String> res =
        await dio.get(sStadiumDetailUrl(stadium.contentId, date));
    BeautifulSoup soup = BeautifulSoup(res.data!);
    List<Bs4Element> listOfSchedule = soup
        .findAll("table", class_: "site_table")
        .first
        .findAll("", selector: "tbody>tr");
    return StadiumScheduleData.fromHtmlPart(
        stadium, date, listOfSchedule.map((e) => e.element!).toList());
  }

  @override
  String get linkHost => "fudan.edu.cn";
}

class StadiumData {
  final String? name;
  final Campus? area;
  final SportsType? type;
  final String? info;
  final String? contentId;

  StadiumData(this.name, this.area, this.type, this.info, this.contentId);

  @override
  String toString() {
    return 'StadiumData{name: $name, area: $area, type: $type, info: $info, contentId: $contentId}';
  }

  factory StadiumData.fromHtml(dom.Element element) {
    var tableItems = element
        .querySelector('td[valign=top]:not([align])')!
        .querySelectorAll('tr');
    String? name, info, contentId;
    Campus? campus;
    SportsType? type;
    for (var element in tableItems) {
      var key = element.querySelector('th')?.text.trim();
      var valueElement = element.querySelector('td');
      switch (key) {
        case '服务项目：':
          name = valueElement!.querySelector('a')!.text.trim();
          contentId = valueElement
              .querySelector('a')!
              .attributes['href']!
              .between('contentId=', '&');
          break;
        case '开放说明：':
          info = valueElement!.text.trim();
          break;
        case '校区：':
          campus = CampusEx.fromChineseName(valueElement!.text.trim());
          break;
        case '运动项目：':
          type = SportsType.fromLiterateName(valueElement!.text.trim());
      }
    }
    return StadiumData(name, campus, type, info, contentId);
  }
}

class StadiumScheduleData {
  final StadiumData stadium;
  final DateTime date;

  /// Schedule and reservation details.
  final List<StadiumScheduleItem> schedule;

  StadiumScheduleData(this.stadium, this.schedule, this.date);

  @override
  String toString() {
    return 'StadiumScheduleData{stadium: $stadium, date: $date, schedule: $schedule}';
  }

  factory StadiumScheduleData.fromHtmlPart(
          StadiumData stadium, DateTime date, List<dom.Element> elements) =>
      StadiumScheduleData(
          stadium,
          elements.map((e) {
            var timeElement = e.getElementsByClassName('site_td1').first;
            var timeMatches =
                RegExp(r'\d{2}:\d{2}').allMatches(timeElement.text);
            var reverseElement = e.getElementsByClassName('site_td4').first;
            var reverseNums = reverseElement.text.trim().split("/");
            return StadiumScheduleItem(
                timeMatches.first.group(0)!,
                timeMatches.last.group(0)!,
                int.parse(reverseNums[0]),
                int.parse(reverseNums[1]));
          }).toList(),
          date);
}

class StadiumScheduleItem {
  final String startTime, endTime;
  final int reserved, total;

  @override
  String toString() {
    return 'StadiumScheduleItem{startTime: $startTime, endTime: $endTime, reserved: $reserved, total: $total}';
  }

  StadiumScheduleItem(this.startTime, this.endTime, this.reserved, this.total);
}

// ignore_for_file: non_constant_identifier_names
class SportsType {
  final String id;
  final Create<String?> name;
  static final SportsType BADMINTON =
      SportsType._('2c9c486e4f821a19014f824823c5000c', (context) => null);
  static final SportsType TENNIS =
      SportsType._('2c9c486e4f821a19014f824823c5000d', (context) => null);
  static final SportsType SOCCER =
      SportsType._('2c9c486e4f821a19014f824823c5000e', (context) => null);
  static final SportsType BASKETBALL =
      SportsType._('2c9c486e4f821a19014f824823c5000f', (context) => null);
  static final SportsType VOLLEYBALL =
      SportsType._('2c9c486e4f821a19014f824823c50010', (context) => null);
  static final SportsType BALLROOM =
      SportsType._('2c9c486e4f821a19014f824823c50011', (context) => null);
  static final SportsType GYM =
      SportsType._('8aecc6ce66851ffa0166d77ef48a60e6', (context) => null);
  static final SportsType BATHROOM =
      SportsType._('8aecc6ce7176eb1801719b4ab80c4d73', (context) => null);
  static final SportsType PLAYGROUND =
      SportsType._('8aecc6ce7176eb18017207d74e1a4ef5', (context) => null);

  static SportsType? fromLiterateName(String name) {
    switch (name) {
      case '羽毛球':
        return SportsType.BADMINTON;
      case '网球':
        return SportsType.TENNIS;
      case '足球':
        return SportsType.SOCCER;
      case '篮球':
        return SportsType.BASKETBALL;
      case '排球':
        return SportsType.VOLLEYBALL;
      case '舞蹈房':
        return SportsType.BALLROOM;
      case '体能房':
        return SportsType.GYM;
      case '浴室':
        return SportsType.BATHROOM;
      case '田径场':
        return SportsType.PLAYGROUND;
    }
    return null;
  }

  SportsType._(this.id, this.name);
}
