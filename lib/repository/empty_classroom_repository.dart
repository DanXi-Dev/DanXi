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
import 'package:dan_xi/util/retryer.dart';
import 'package:dio/src/response.dart';
import 'package:html/dom.dart';
import 'package:intl/intl.dart';

class EmptyClassroomRepository extends BaseRepositoryWithDio {
  static const String LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=http%3A%2F%2Ftac.fudan.edu.cn%2Fthirds%2Fmap.act";

  static String detailUrl(String buildingName, DateTime date) =>
      "http://map.fudan.edu.cn/src/paike/index.php?b=$buildingName&d=${DateFormat("yyyy-MM-dd").format(date)}&i1=--&i2=--";

  EmptyClassroomRepository._();

  static final _instance = EmptyClassroomRepository._();

  factory EmptyClassroomRepository.getInstance() => _instance;

  /// Get [RoomInfo]s at [buildingName] on [date].
  ///
  /// Request [PersonInfo] for logging in, if necessary.
  Future<List<RoomInfo>> getBuildingRoomInfo(
      PersonInfo info, String buildingName, DateTime date) async {
    // To accelerate the retrieval of RoomInfo,
    // only execute logging in when necessary.
    return Retrier.tryAsyncWithFix(
        () => _getBuildingRoomInfo(buildingName, date),
        (exception) async =>
            await UISLoginTool.loginUIS(dio, LOGIN_URL, cookieJar, info, true));
  }

  Future<List<RoomInfo>> _getBuildingRoomInfo(
      String buildingName, DateTime date) async {
    RegExp roomStatusMatcher = RegExp(r'(?<=div class=")\w+(?=")');
    List<RoomInfo> result = [];
    Response response = await dio.get(detailUrl(buildingName, date));
    Beautifulsoup soup = Beautifulsoup(response.data.toString());
    Element mainTable = soup.find(id: "table");
    List<Element> roomList = mainTable.querySelectorAll("tr")..removeAt(0);

    roomList.forEach((roomNode) {
      String roomName = roomNode.querySelector("a").text;
      RoomInfo roomInfo = RoomInfo(roomName, date);
      roomInfo.busy = [];
      roomStatusMatcher.allMatches(roomNode.innerHtml).forEach((element) {
        if (element.group(0) == 'free') {
          roomInfo.busy.add(false);
        } else {
          roomInfo.busy.add(true);
        }
      });
      result.add(roomInfo);
    });
    return result;
  }

  @override
  String get linkHost => "map.fudan.edu.cn";
}

class RoomInfo {
  String roomName;
  DateTime date;

  /// the x-th item of busy refers to whether the room is busy at x-th slot.
  List<bool> busy;

  RoomInfo(this.roomName, this.date, {this.busy});
}
