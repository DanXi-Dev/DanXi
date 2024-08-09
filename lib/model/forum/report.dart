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

// ignore_for_file: non_constant_identifier_names

import 'package:dan_xi/model/forum/floor.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report.g.dart';

@JsonSerializable()
class OTReport {
  final int? report_id;
  final String? reason;
  final String? result;
  final String? content;
  final OTFloor? floor;
  final int? hole_id;
  final String? time_created;
  final String? time_updated;
  final bool? dealt;
  final int? dealt_by;

  const OTReport(
      this.report_id,
      this.reason,
      this.result,
      this.content,
      this.floor,
      this.hole_id,
      this.time_created,
      this.time_updated,
      this.dealt,
      this.dealt_by);

  @override
  int get hashCode => report_id!;

  @override
  String toString() {
    return 'OTReport{report_id: $report_id, reason: $reason, result:$result, content: $content, floor: $floor, hole_id: $hole_id, time_created: $time_created, time_updated: $time_updated, dealt: $dealt, dealt_by: $dealt_by}';
  }

  @override
  bool operator ==(Object other) =>
      (other is OTReport) && report_id == other.report_id;

  factory OTReport.fromJson(Map<String, dynamic> json) =>
      _$OTReportFromJson(json);

  Map<String, dynamic> toJson() => _$OTReportToJson(this);
}
