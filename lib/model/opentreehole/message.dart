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

import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

@JsonSerializable()
class OTMessage {
  int? message_id;
  String? message;
  String? description;
  String? code;
  String? time_created;
  bool? has_read;

  /// This can be anything, in json format
  Map<String, dynamic>? data;

  factory OTMessage.fromJson(Map<String, dynamic> json) =>
      _$OTMessageFromJson(json);

  Map<String, dynamic> toJson() => _$OTMessageToJson(this);

  @override
  bool operator ==(Object other) =>
      (other is OTMessage) && message_id == other.message_id;

  OTMessage(this.message_id, this.message, this.code, this.time_created,
      this.has_read, this.data);

  @override
  int get hashCode => message_id!;
}
