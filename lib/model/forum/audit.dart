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
// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

part 'audit.g.dart';

@JsonSerializable()
class OTAudit {
  final String content;
  final int hole_id;
  final int id;
  final bool? is_actual_sensitive;
  final int modified;
  final String? time_created;
  final String? time_updated;
  final String? sensitive_detail;

  OTAudit(
      this.content,
      this.hole_id,
      this.id,
      this.is_actual_sensitive,
      this.modified,
      this.time_created,
      this.time_updated,
      this.sensitive_detail);

  factory OTAudit.fromJson(Map<String, dynamic> json) =>
      _$OTAuditFromJson(json);

  OTAudit processed() => OTAudit("已处理", hole_id, id, is_actual_sensitive,
      modified, time_created, time_updated, sensitive_detail);

  Map<String, dynamic> toJson() => _$OTAuditToJson(this);

  @override
  String toString() {
    return 'OTAudit{content: $content, hole_id: $hole_id, id: $id, is_actual_sensitive: $is_actual_sensitive, modified: $modified, time_created: $time_created, time_updated: $time_updated, sensitive_detail: $sensitive_detail}';
  }
}
