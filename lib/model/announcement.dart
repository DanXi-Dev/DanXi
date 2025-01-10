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

part 'announcement.g.dart';

@JsonSerializable()
class Announcement {
  String? createdAt;
  String? updatedAt;
  String? objectId;

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

  // FIXME: Use updatedAt as objectId requires updatedAt to be unique
  Announcement.fromToml(Map<String, dynamic> notice) {
    updatedAt = notice['updated_at'];
    content = notice['content'];
    maxVersion = notice['build'];
    createdAt = updatedAt;
    objectId = updatedAt;
  }
}
