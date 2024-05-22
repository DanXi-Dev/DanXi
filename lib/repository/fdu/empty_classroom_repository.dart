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
import 'package:dan_xi/repository/fdu/uis_login_tool.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class EmptyClassroomRepository extends BaseRepositoryWithDio {
  static String detailUrl(String? buildingName, DateTime date) {
    return "http://10.64.130.6/?b=$buildingName&c=&p=&day=${DateFormat("yyyy-MM-dd").format(date)}";
  }

  static String classroomIdUrl(String? buildingName, DateTime date) {
    return "http://10.64.130.6/daystatus.asp?b=$buildingName&day=${DateFormat("yyyy-MM-dd").format(date)}";
  }

  EmptyClassroomRepository._();

  @override
  Dio dio = Dio(BaseOptions(connectTimeout: 3000, receiveTimeout: 3000));

  static final _instance = EmptyClassroomRepository._();

  factory EmptyClassroomRepository.getInstance() => _instance;

  /// Get [RoomInfo]s at [buildingName] on [date].
  Future<List<RoomInfo>?> getBuildingRoomInfo(
      _, __, String? buildingName, DateTime date) async {
    List<RoomInfo> result = [];
    final Response<String> classroomIdData =
        await dio.get(classroomIdUrl(buildingName, date));
    final Response<String> response =
        await dio.get(detailUrl(buildingName, date));
    final classroomIds = json.decode(classroomIdData.data!)['status'];
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
          RegExp(r'<td style="background-color.*?>(.*?)<\/td>');
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
      dio.get('http://$linkHost').then((value) => true, onError: (e) => false);

  @override
  String get linkHost => "10.64.130.6";
}

class EhallEmptyClassroomRepository extends BaseRepositoryWithDio {
  static const String LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Fzlapp.fudan.edu.cn%2Fa_fudanzlapp%2Fapi%2Fsso%2Findex%3Fredirect%3Dhttps%253A%252F%252Fzlapp.fudan.edu.cn%252Ffudanzlfreeclass%252Fwap%252Fmobile%252Findex%253Fxqdm%253D%2526amp%253Bfloor%253D%2526amp%253Bdate%253D%2526amp%253Bpage%253D1%2526amp%253Bflag%253D3%2526amp%253Broomnum%253D%2526amp%253Bpagesize%253D10000%26from%3Dwap";

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
  Future<List<RoomInfo>?> getBuildingRoomInfo(PersonInfo? info, String areaName,
          String? buildingName, DateTime? date) =>
      UISLoginTool.tryAsyncWithAuth(dio, LOGIN_URL, cookieJar!, info,
          () => _getBuildingRoomInfo(areaName, buildingName, date!));

  Future<List<RoomInfo>?> _getBuildingRoomInfo(
      String areaName, String? buildingName, DateTime date) async {
    List<RoomInfo> result = [];
    final Response<String> response =
        await dio.get(detailUrl(areaName, buildingName, date));
    final Map<String, dynamic> json = jsonDecode(response.data!);
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
  }

  @override
  String get linkHost => "zlapp.fudan.edu.cn";
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
