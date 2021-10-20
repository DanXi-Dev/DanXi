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

import 'package:json_annotation/json_annotation.dart';

part 'floor.g.dart';

@JsonSerializable()
class OTFloor {
  int? floor_id;
  int? hole_id;
  String? content;
  String? anonyname;
  String? time_updated;
  String? time_created;
  bool? deleted;
  bool? is_me;
  bool? liked;
  List<String>? fold;
  int? like;
  List<OTFloor>? mention;

  factory OTFloor.fromJson(Map<String, dynamic> json) =>
      _$OTFloorFromJson(json);

  Map<String, dynamic> toJson() => _$OTFloorToJson(this);

  @override
  bool operator ==(Object other) =>
      (other is OTFloor) && floor_id == other.floor_id;

  OTFloor(
      this.floor_id,
      this.hole_id,
      this.content,
      this.anonyname,
      this.time_created,
      this.time_updated,
      this.deleted,
      this.fold,
      this.like,
      this.is_me,
      this.liked,
      this.mention);

  @override
  int get hashCode => floor_id!;
}
