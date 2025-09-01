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
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/neo_login_tool.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/vague_time.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class FudanBusRepository extends BaseRepositoryWithDio {
  static const String _INFO_URL =
      "https://zlapp.fudan.edu.cn/fudanbus/wap/default/lists";

  FudanBusRepository._();

  static final _instance = FudanBusRepository._();

  factory FudanBusRepository.getInstance() => _instance;

  Future<List<BusScheduleItem>> loadBusList({bool holiday = false}) {
    final options = RequestOptions(
      method: "POST",
      path: _INFO_URL,
      data: FormData.fromMap(
          {"holiday": holiday.toRequestParamStringRepresentation()}),
    );
    return FudanSession.request(options, (rep) {
      List<BusScheduleItem> items = [];
      Map<String, dynamic> json = jsonDecode(rep.data.toString());
      json['d']['data'].forEach((route) {
        if (route['lists'] is List) {
          items.addAll((route['lists'] as List)
              .map((e) => BusScheduleItem.fromRawJson(e)));
        }
      });
      return items.filter((element) => element.realStartTime != null);
    });
  }

  @override
  String get linkHost => "fudan.edu.cn";
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

  factory BusScheduleItem.fromRawJson(Map<String, dynamic> json) =>
      BusScheduleItem(
          json['id'],
          CampusEx.fromChineseName(json['start']),
          CampusEx.fromChineseName(json['end']),
          _parseTime(json['stime']),
          _parseTime(json['etime']),
          BusDirection.values[int.parse(json['arrow'])],
          int.parse(json['holiday']) != 0);

  // Some times are using "." as separator, so we need to parse it manually
  static VagueTime? _parseTime(String time) {
    if (time.isEmpty) {
      return null;
    }
    return VagueTime.onlyHHmm(time.replaceAll(".", ":"));
  }

  BusScheduleItem.reversed(BusScheduleItem original)
      : id = original.id,
        start = original.end,
        end = original.start,
        startTime = original.endTime,
        endTime = original.startTime,
        direction = original.direction.reverse(),
        holidayRun = original.holidayRun;

  BusScheduleItem copyWith({BusDirection? direction}) {
    return BusScheduleItem(id, start, end, startTime, endTime,
        direction ?? this.direction, holidayRun);
  }

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

  BusDirection reverse() {
    switch (this) {
      case BusDirection.FORWARD:
        return BusDirection.BACKWARD;
      case BusDirection.BACKWARD:
        return BusDirection.FORWARD;
      default:
        return this;
    }
  }
}

extension VagueTimeExtension on VagueTime {
  String toDisplayFormat() {
    final format = NumberFormat("00");
    return "${format.format(hour)}:${format.format(minute)}";
  }
}
