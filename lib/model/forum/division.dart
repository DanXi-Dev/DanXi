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

import 'package:dan_xi/model/forum/hole.dart';
import 'package:json_annotation/json_annotation.dart';

part 'division.g.dart';

@JsonSerializable()
class OTDivision {
  int? division_id;
  String? name;
  String? description;
  List<OTHole>? pinned;

  factory OTDivision.fromJson(Map<String, dynamic> json) =>
      _$OTDivisionFromJson(json);

  Map<String, dynamic> toJson() => _$OTDivisionToJson(this);

  @override
  bool operator ==(Object other) =>
      (other is OTDivision) && division_id == other.division_id;

  OTDivision(this.division_id, this.name, this.description, this.pinned);

  @override
  String toString() => name ?? "null";

  @override
  int get hashCode => division_id!;
}
