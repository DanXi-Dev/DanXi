/*
 *     Copyright (C) 2022  DanXi-Dev
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

part 'history.g.dart';

@JsonSerializable()
class OTHistory {
  String? content;
  int? user_id;
  String? time_updated;

  factory OTHistory.fromJson(Map<String, dynamic> json) =>
      _$OTHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$OTHistoryToJson(this);

  OTHistory(this.content, this.user_id, this.time_updated);
}
