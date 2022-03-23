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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/uis_login_tool.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/retrier.dart';
import 'package:dan_xi/util/vague_time.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class FudanBusRepository extends BaseRepositoryWithDio {
  static const String _LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Fzlapp.fudan.edu.cn%2Fa_fudanzlapp%2Fapi%2Fsso%2Findex%3Fredirect%3Dhttps%253A%252F%252Fzlapp.fudan.edu.cn%252Ffudanbus%252Fwap%252Fdefault%252Flists%26from%3Dwap";
  static const String _INFO_URL =
      "https://zlapp.fudan.edu.cn/fudanbus/wap/default/lists";

  FudanBusRepository._();

  static final _instance = FudanBusRepository._();

  factory FudanBusRepository.getInstance() => _instance;

  Future<List<BusScheduleItem>?> loadBusList(PersonInfo? info,
      {bool? holiday = false}) {
    return Retrier.tryAsyncWithFix(
        () => _loadBusList(holiday: holiday!),
        (exception) => UISLoginTool.fixByLoginUIS(
            dio!, _LOGIN_URL, cookieJar!, info, true));
  }

  Future<List<BusScheduleItem>?> _loadBusList({bool holiday = false}) async {
    List<BusScheduleItem> items = [];
    Response<String> r = await dio!.post(_INFO_URL,
        data: FormData.fromMap(
            {"holiday": holiday.toRequestParamStringRepresentation()}));
    Map<String, dynamic> json = jsonDecode(r.data!);
    json['d']['data'].forEach((route) {
      if (route['lists'] is List) {
        items.addAll((route['lists'] as List)
            .map((e) => BusScheduleItem.fromRawJson(e)));
      }
    });
    return items.filter((element) => element.realStartTime != null);
  }

  @override
  String get linkHost => "zlapp.fudan.edu.cn";
}

class BusScheduleItem implements Comparable<BusScheduleItem> {
  final String? id;
  Campus start;
  Campus end;
  VagueTime? startTime;
  VagueTime? endTime;
  BusDirection direction;
  final bool holidayRun;

  VagueTime? get realStartTime => startTime ?? endTime;

  BusScheduleItem(this.id, this.start, this.end, this.startTime, this.endTime,
      this.direction, this.holidayRun);

  factory BusScheduleItem.fromRawJson(
          Map<String, dynamic> json) =>
      BusScheduleItem(
          json['id'],
          CampusEx.fromChineseName(json['start']),
          CampusEx.fromChineseName(json['end']),
          (json['stime'] as String).isNotEmpty
              ? VagueTime.onlyMMSS(json['stime'])
              : null,
          (json['etime'] as String).isNotEmpty
              ? VagueTime.onlyMMSS(json['etime'])
              : null,
          BusDirection.values[int.parse(json['arrow'])],
          int.parse(json['holiday']) != 0);

  @override
  int compareTo(BusScheduleItem other) =>
      realStartTime!.compareTo(other.realStartTime!);

  @override
  String toString() {
    return 'BusScheduleItem{id: $id, start: $start, end: $end, startTime: $startTime, endTime: $endTime, direction: $direction, holidayRun: $holidayRun}';
  }
}

enum BusDirection {
  NONE,
  DUAL,

  /// From end to start
  BACKWARD,

  /// From start to end
  FORWARD
}

extension BusDirectionExtension on BusDirection {
  static const FORWARD_ARROW = " → ";
  static const BACKWARD_ARROW = " ← ";
  static const DUAL_ARROW = " ↔ ";

  String? toText() {
    switch (this) {
      case BusDirection.FORWARD:
        return FORWARD_ARROW;
      case BusDirection.BACKWARD:
        return BACKWARD_ARROW;
      case BusDirection.DUAL:
        return DUAL_ARROW;
      default:
        return null;
    }
  }
}

extension VagueTimeExtension on VagueTime {
  String toDisplayFormat() {
    final format = NumberFormat("00");
    return "${format.format(hour)}:${format.format(minute)}";
  }
}
