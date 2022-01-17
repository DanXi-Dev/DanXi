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

import 'package:dan_xi/util/bmob/bmob/table/bmob_object.dart';
import 'package:json_annotation/json_annotation.dart';

part 'announcement.g.dart';

@JsonSerializable()
class Announcement extends BmobObject {
  // ignore: unused_field
  final String __type = "Announcement";

  String? content;
  int? maxVersion;

  factory Announcement.fromJson(Map<String, dynamic> json) =>
      _$AnnouncementFromJson(json);

  @override
  String toString() {
    return 'Announcement{content: $content, maxVersion: $maxVersion}';
  }

  Map<String, dynamic> toJson() => _$AnnouncementToJson(this);

  Announcement(this.content);

  @override
  Map<String, dynamic> getParams() =>
      Map<String, dynamic>.from({"content": content, "maxVersion": maxVersion});
}
