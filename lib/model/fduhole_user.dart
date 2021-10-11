

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

import 'package:dan_xi/model/post.dart';
import 'package:json_annotation/json_annotation.dart';

part 'fduhole_user.g.dart';

@JsonSerializable()
class FduholeUser {
  final String? username;
  // ignore: non_constant_identifier_names
  final bool? is_active;

  // ignore: non_constant_identifier_names
  final bool? is_staff;

  // ignore: non_constant_identifier_names
  final bool? is_superuser;

  // ignore: non_constant_identifier_names
  final List<BBSPost>? favored_discussion;

  // ignore: non_constant_identifier_names
  final String? encrypted_email;

  factory FduholeUser.fromJson(Map<String, dynamic> json) =>
      _$FduholeUserFromJson(json);

  Map<String, dynamic> toJson() => _$FduholeUserToJson(this);

  FduholeUser(this.username, this.is_active, this.is_staff, this.is_superuser,
      this.favored_discussion, this.encrypted_email);
}
