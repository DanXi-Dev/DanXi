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

import 'package:dan_xi/model/fduhole_user.dart';
import 'package:dan_xi/model/post.dart';
import 'package:json_annotation/json_annotation.dart';

part 'fduhole_profile.g.dart';

@JsonSerializable()
class FduholeProfile {
  final int id;

  final FduholeUser user;

  // ignore: non_constant_identifier_names
  final List<BBSPost> favored_discussion;

  // ignore: non_constant_identifier_names
  final String encrypted_email;

  factory FduholeProfile.fromJson(Map<String, dynamic> json) =>
      _$FduholeProfileFromJson(json);

  Map<String, dynamic> toJson() => _$FduholeProfileToJson(this);

  FduholeProfile(
      this.id, this.user, this.favored_discussion, this.encrypted_email);
}
