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

import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/uis_login_tool.dart';
import 'package:dan_xi/util/retryer.dart';
import 'package:dio/src/response.dart';
import 'package:intl/intl.dart';

class EmptyClassroomRepository extends BaseRepositoryWithDio {
  static const String LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Fzlapp.fudan.edu.cn%2Fa_fudanzlapp%2Fapi%2Fsso%2Findex%3Fredirect%3Dhttps%253A%252F%252Fzlapp.fudan.edu.cn%252Ffudanzlfreeclass%252Fwap%252Fmobile%252Findex%253Fxqdm%253D%2526amp%253Bfloor%253D%2526amp%253Bdate%253D%2526amp%253Bpage%253D1%2526amp%253Bflag%253D3%2526amp%253Broomnum%253D%2526amp%253Bpagesize%253D10000%26from%3Dwap";

  static String detailUrl(String areaName, String buildingName, DateTime date) {
    return "https://zlapp.fudan.edu.cn/fudanzlfreeclass/wap/mobile/index?xqdm=$areaName&floor=$buildingName&date=${DateFormat("yyyy-MM-dd").format(date)}&page=1&flag=3&roomnum=&pagesize=10000";
  }

  EmptyClassroomRepository._();

  static final _instance = EmptyClassroomRepository._();

  factory EmptyClassroomRepository.getInstance() => _instance;

  /// Get [RoomInfo]s at [buildingName] on [date].
  ///
  /// Request [PersonInfo] for logging in, if necessary.
  Future<List<RoomInfo>> getBuildingRoomInfo(PersonInfo info, String areaName,
      String buildingName, DateTime date) async {
    // To accelerate the retrieval of RoomInfo,
    // only execute logging in when necessary.
    return Retrier.tryAsyncWithFix(
        () => _getBuildingRoomInfo(areaName, buildingName, date),
        (exception) async =>
            await UISLoginTool.loginUIS(dio, LOGIN_URL, cookieJar, info, true));
  }

  Future<List<RoomInfo>> _getBuildingRoomInfo(
      String areaName, String buildingName, DateTime date) async {
    List<RoomInfo> result = [];
    final Response response =
        await dio.get(detailUrl(areaName, buildingName, date));
    final Map json = response.data is Map
        ? response.data
        : jsonDecode(response.data.toString());
    final Map buildingInfo = json['d']['list'];
    buildingInfo.values.forEach((element) {
      if (element is List) {
        element.forEach((element) {
          RoomInfo info = RoomInfo(element['name'], date, element['roomrl']);
          info.busy = [];
          if (element['kxsds'] is Map) {
            element['kxsds']
                .values
                .forEach((element) => info.busy.add(element != "闲"));
            result.add(info);
          }
        });
      }
    });
    return result;
  }

  @override
  String get linkHost => "zlapp.fudan.edu.cn";
}

class RoomInfo {
  String roomName;
  DateTime date;
  String seats;

  /// the x-th item of busy refers to whether the room is busy at x-th slot.
  List<bool> busy;

  RoomInfo(this.roomName, this.date, this.seats, {this.busy});
}
