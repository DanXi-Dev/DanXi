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
import 'package:dan_xi/repository/fdu/neo_login_tool.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dan_xi/util/webvpn_proxy.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class EmptyClassroomRepository extends BaseRepositoryWithDio {
  static String detailUrl(String buildingName, DateTime date) {
    return "http://10.64.130.6/?b=$buildingName&c=&p=&day=${DateFormat("yyyy-MM-dd").format(date)}";
  }

  // Example:
  //
  // {
  //  "status": [
  //
  // {"id":"586","room":"HGX103","color":"white","ec":"1","c1":"green.png","c2":"green.png","c2t":"","mic":"micgreen.png","micstr":"麦克风 (2- ASUS XONAR U5)","fenbei":"0","touying":"0","vol":"00000000000000000000","daping":"0","headcheck":"1","head":"0%","keylock":"1","diskinfo":"good","errfile":"0","taidian":"0","chargeStatus":"-1","batteryLevel":"0","current":"0","duration":"0","chargeday":"yellow","camera":"camera2.png"}
  // ,
  // ...
  // ],
  //
  //  "tempnotice":"",
  //  "time":"2026-1-15 13:39:12.695",
  //  "time1":"13:39",
  //  "time2":47305,
  //  "time3":"
  // <script>
  // ...
  // }
  // which is NOT a valid JSON due to the unescaped <script> tags, etc.
  //
  static String classroomIdUrl(String buildingName, DateTime date) {
    return "http://10.64.130.6/daystatus.asp?b=$buildingName&day=${DateFormat("yyyy-MM-dd").format(date)}";
  }
  final statusMatcher = RegExp(r'"status"\s*:\s*(\[.*\])', dotAll: true);

  EmptyClassroomRepository._() {
    dio.interceptors.add(WebVPNInterceptor());
  }

  /// Dio instance that does not use WebVPN proxy to check LAN connection.
  Dio directDio = DioUtils.newDioWithProxy(BaseOptions(
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3)));

  static final _instance = EmptyClassroomRepository._();

  factory EmptyClassroomRepository.getInstance() => _instance;

  /// Get [RoomInfo]s at [buildingName] on [date].
  Future<List<RoomInfo>> getBuildingRoomInfo(String buildingName, DateTime date) async {
    List<RoomInfo> result = [];
    final Response<String> classroomIdData =
        await dio.get(classroomIdUrl(buildingName, date));
    final Response<String> response =
        await dio.get(detailUrl(buildingName, date));
    // classroomIdData is NOT a valid JSON, so we need to extract the "status" field manually.
    final classroomData = statusMatcher.firstMatch(classroomIdData.data!)?.group(1);
    final List<dynamic> classroomIds = json.decode(classroomData!);
    for (int i = 0; i < classroomIds.length; i++) {
      final classroomInfo = classroomIds[i];
      final classroomName = classroomInfo['room'];
      final classroomId = classroomInfo['id'];
      // quotation mark is necessary
      final start = response.data!.indexOf("\"c$classroomId\"");
      int end;
      if (i != classroomIds.length - 1) {
        final nextClassroom = classroomIds[i + 1];
        end = response.data!.indexOf("\"r${nextClassroom['id']}\"");
      } else {
        end = response.data!.indexOf("innerHTML");
      }
      final html = response.data!.substring(start, end);
      final patternForSeats = RegExp(r'>(\d+)<');
      final patternForUsages =
          RegExp(r'<td style="background-color.*?>(.*?)</td>');
      final match1 = patternForSeats.firstMatch(html);
      String? roomCapacity;
      if (match1 != null) {
        roomCapacity = match1.group(1);
      }
      RoomInfo info = RoomInfo(classroomName, date, roomCapacity);
      info.busy = [];
      final match2 = patternForUsages.allMatches(html);
      for (final match in match2) {
        final content = match.group(1);
        if (content == null || content.isEmpty) {
          info.busy!.add(false);
        } else {
          info.busy!.add(true);
        }
      }
      // remove last course (14th)
      info.busy!.removeLast();
      result.add(info);
    }
    return result;
  }

  Future<bool> checkConnection() =>
      directDio.get('http://$linkHost').then((value) => true, onError: (e) => false);

  @override
  String get linkHost => "10.64.130.6";

  @override
  bool get isWebvpnApplicable => true;
}

@Deprecated("2026-01-15: Seems like this API is no longer available. See #615 for details.")
class EhallEmptyClassroomRepository extends BaseRepositoryWithDio {
  static String detailUrl(
      String areaName, String? buildingName, DateTime date) {
    return "https://zlapp.fudan.edu.cn/fudanzlfreeclass/wap/mobile/index?xqdm=$areaName&floor=$buildingName&date=${DateFormat("yyyy-MM-dd").format(date)}&page=1&flag=3&roomnum=&pagesize=10000";
  }

  EhallEmptyClassroomRepository._();

  static final _instance = EhallEmptyClassroomRepository._();

  factory EhallEmptyClassroomRepository.getInstance() => _instance;

  /// Get [RoomInfo]s at [buildingName] on [date].
  ///
  /// Request [PersonInfo] for logging in, if necessary.
  Future<List<RoomInfo>> getBuildingRoomInfo(
      String areaName, String? buildingName, DateTime date) {
    final options = RequestOptions(
      method: "GET",
      path: detailUrl(areaName, buildingName, date),
    );
    return FudanSession.request(options, (rep) {
      List<RoomInfo> result = [];
      final Map<String, dynamic> json = jsonDecode(rep.data!);
      final Map<String, dynamic> buildingInfo = json['d']['list'];
      for (var element in buildingInfo.values) {
        if (element is List) {
          for (var element in element) {
            RoomInfo info = RoomInfo(element['name'], date, element['roomrl']);
            info.busy = [];
            if (element['kxsds'] is Map) {
              element['kxsds']
                  .values
                  .forEach((element) => info.busy!.add(element != "闲"));
              result.add(info);
            }
          }
        }
      }
      return result;
    });
  }

  @override
  String get linkHost => "fudan.edu.cn";
}

class RoomInfo {
  String? roomName;
  DateTime date;
  String? seats;

  /// the x-th item of busy refers to whether the room is busy at x-th slot.
  List<bool>? busy;

  RoomInfo(this.roomName, this.date, this.seats, {this.busy});
}

class NotConnectedToLANError implements Exception {}
