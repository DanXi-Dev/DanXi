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

import 'dart:convert';

import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/uis_login_tool.dart';

class DiningHallCrowdednessRepository extends BaseRepositoryWithDio {
  static const String LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Fmy.fudan.edu.cn%2Fsimple_list%2Fstqk";
  static const String DETAIL_URL = "https://my.fudan.edu.cn/simple_list/stqk";

  DiningHallCrowdednessRepository._() {
    initRepository();
  }

  static final _instance = DiningHallCrowdednessRepository._();

  factory DiningHallCrowdednessRepository.getInstance() => _instance;

  Future<Map<String, TrafficInfo>> getCrowdednessInfo(
      PersonInfo info, int areaCode) async {
    var result = Map<String, TrafficInfo>();
    await UISLoginTool.loginUIS(dio, LOGIN_URL, cookieJar, info);
    var response = await dio.get(DETAIL_URL);

    //If it's not time for a meal
    if (response.data.toString().contains("仅")) {
      throw UnsuitableTimeException();
    }
    var dataString =
        response.data.toString().between("}", "</script>", headGreedy: false);
    var jsonExtraction = new RegExp(r'\[.+\]').allMatches(dataString);
    List names = jsonDecode(
        jsonExtraction.elementAt(areaCode * 3).group(0).replaceAll("\'", "\""));
    List cur = jsonDecode(jsonExtraction
        .elementAt(areaCode * 3 + 1)
        .group(0)
        .replaceAll("\'", "\""));
    List max = jsonDecode(jsonExtraction
        .elementAt(areaCode * 3 + 2)
        .group(0)
        .replaceAll("\'", "\""));
    for (int i = 0; i < names.length; i++) {
      result[names[i]] = TrafficInfo(int.parse(cur[i]), int.parse(max[i]));
    }

    return result;
  }
}

class UnsuitableTimeException implements Exception {}

class TrafficInfo {
  int current;
  int max;

  TrafficInfo(this.current, this.max);
}
