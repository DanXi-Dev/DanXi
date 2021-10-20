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

import 'package:dan_xi/model/opentreehole/user_permission_silent_config.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_permission.g.dart';

@JsonSerializable()
class OTUserPermission {
  OTUserPermissionSilentConfig silent;
  String? admin;

  factory OTUserPermission.fromJson(Map<String, dynamic> json) =>
      _$OTUserPermissionFromJson(json);

  Map<String, dynamic> toJson() => _$OTUserPermissionToJson(this);

  OTUserPermission(this.silent, this.admin);
}
