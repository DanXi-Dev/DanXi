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
import 'package:dan_xi/model/pair.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/uis_login_tool.dart';
import 'package:dan_xi/util/retryer.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart' as DOM;

class FudanDormRepository extends BaseRepositoryWithDio {
  static const String _LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Felife.fudan.edu.cn%2Flogin2.action";
  static const String _DORM_SELECT_URL =
      "https://elife.fudan.edu.cn/public/ordinary/cityhot/rechargeElecteSelect.htm";

  static String electricityUrl(String roomId) =>
      'https://elife.fudan.edu.cn/public/ordinary/cityhot/rechargeElecte.htm?roomId=$roomId&isphone=';

  FudanDormRepository._();

  static final _instance = FudanDormRepository._();

  factory FudanDormRepository.getInstance() => _instance;

  Future<List<Pair<String, String>>> loadDorms(PersonInfo info) {
    return Retrier.tryAsyncWithFix(
        () => _loadDorms(),
        (exception) =>
            UISLoginTool.loginUIS(dio, _LOGIN_URL, cookieJar, info, true));
  }

  Future<List<Pair<String, String>>> _loadDorms() async {
    Response r = await dio.get(_DORM_SELECT_URL);
    Beautifulsoup soup = Beautifulsoup(r.data.toString());
    List<DOM.Element> rawDorms = soup.find_all(r'option:not([value=""])');
    if (rawDorms.isEmpty) throw 'Empty dorm data';
    // Remove non-number characters from room Id
    return rawDorms
        .map((e) => Pair(
            e.text.trim(), e.attributes['value'].replaceAll(RegExp(r'\D'), '')))
        .toList();
  }

  Future<ElectricityItem> loadElectricityInfo(
      PersonInfo info, Pair<String, String> roomInfo) {
    return Retrier.tryAsyncWithFix(
        () => _loadElectricityInfo(roomInfo),
        (exception) =>
            UISLoginTool.loginUIS(dio, _LOGIN_URL, cookieJar, info, true));
  }

  Future<ElectricityItem> _loadElectricityInfo(
      Pair<String, String> roomInfo) async {
    Response r = await dio.get(electricityUrl(roomInfo.second));
    // debugPrint(r.data.toString());
    return ElectricityItem.fromHtml(roomInfo.first, roomInfo.second,
        Beautifulsoup(r.data.toString()).find(id: 'table'));
  }

  @override
  String get linkHost => "elife.fudan.edu.cn";
}

class ElectricityItem {
  static const _KEY_AVAILABLE = '剩余电数(KWh)：';
  static const _KEY_USED = '电表读数(KWh)：';
  static const _KEY_UPDATE_TIME = '更新时间：';

  final String available;
  final String used;
  final DateTime updateTime;
  final String roomId;
  final String dormName;

  ElectricityItem(
      this.available, this.used, this.updateTime, this.roomId, this.dormName);

  @override
  String toString() {
    return 'ElectricityItem{available: $available, used: $used, updateTime: $updateTime, roomId: $roomId, dormName: $dormName}';
  }

  factory ElectricityItem.fromHtml(
      String dormName, String roomId, DOM.Element html) {
    var keyValuePairs = html.getElementsByTagName('tr').map((e) {
      List<DOM.Element> row = e.getElementsByTagName('td');
      if (row.length == 2) return Pair(row[0].text.trim(), row[1].text.trim());
    });
    return ElectricityItem(
        keyValuePairs
            .firstWhere((element) => element.first == _KEY_AVAILABLE)
            .second,
        keyValuePairs
            .firstWhere((element) => element.first == _KEY_USED)
            .second,
        DateTime.parse(keyValuePairs
            .firstWhere((element) => element.first == _KEY_UPDATE_TIME)
            .second),
        roomId,
        dormName);
  }
}
