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

import 'package:dan_xi/model/opentreehole/floors.dart';
import 'package:dan_xi/model/opentreehole/tag.dart';
import 'package:json_annotation/json_annotation.dart';

part 'hole.g.dart';

@JsonSerializable()
class OTHole {
  int? hole_id;
  int? division_id;
  String? time_updated;
  String? time_created;
  List<OTTag>? tags;
  int? view;
  int? reply;
  OTFloors? floors;
  bool? hidden;

  factory OTHole.fromJson(Map<String, dynamic> json) => _$OTHoleFromJson(json);

  Map<String, dynamic> toJson() => _$OTHoleToJson(this);

  @override
  bool operator ==(Object other) =>
      (other is OTHole) && hole_id == other.hole_id;

  OTHole(this.hole_id, this.division_id, this.time_created, this.time_updated,
      this.tags, this.view, this.reply, this.floors);

  /// Generate an empty BBSPost for special sakes.
  factory OTHole.dummy() => OTHole(-1, -1, "", "", [], -1, -1, null);

  bool get is_folded =>
      tags?.any((element) => element.name?.startsWith("*") ?? false) ?? false;

  static final DUMMY_POST = OTHole.dummy();

  @override
  int get hashCode => hole_id!;
}
