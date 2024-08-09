/*
 *     Copyright (C) 2023  DanXi-Dev
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

import 'package:dan_xi/model/forum/floor.dart';
import 'package:json_annotation/json_annotation.dart';

part 'punishment.g.dart';

@JsonSerializable()
class OTPunishment {
  String? created_at;
  String? deleted_at;
  int? division_id;
  int? duration;
  String? end_time;
  OTFloor? floor;
  int? floor_id;
  int? id;
  int? made_by;
  String? reason;
  String? start_time;
  int? user_id;

  factory OTPunishment.fromJson(Map<String, dynamic> json) =>
      _$OTPunishmentFromJson(json);

  Map<String, dynamic> toJson() => _$OTPunishmentToJson(this);

  OTPunishment(
      this.created_at,
      this.deleted_at,
      this.division_id,
      this.duration,
      this.end_time,
      this.floor,
      this.floor_id,
      this.id,
      this.made_by,
      this.reason,
      this.start_time,
      this.user_id);
}
