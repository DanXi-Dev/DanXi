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

import 'package:dan_xi/model/opentreehole/user_config.dart';
import 'package:dan_xi/model/opentreehole/user_permission.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class OTUser {
  int? user_id;
  String? nickname;
  List<int>? favorites;
  OTUserPermission? permission;
  OTUserConfig? config;
  String? joined_time;
  bool? is_admin;

  factory OTUser.fromJson(Map<String, dynamic> json) => _$OTUserFromJson(json);

  Map<String, dynamic> toJson() => _$OTUserToJson(this);

  @override
  bool operator ==(Object other) =>
      (other is OTUser) && user_id == other.user_id;

  OTUser(this.user_id, this.nickname, this.favorites, this.is_admin,
      this.joined_time, this.config, this.permission);

  @override
  int get hashCode => user_id!;
}
