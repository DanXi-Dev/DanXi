/*
 *     Copyright (C) 2025  DanXi-Dev
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

part 'claw_channel.g.dart';

@JsonSerializable()
class ClawChannel {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'user_session_id')
  final int userSessionId;
  final String conversation;
  @JsonKey(name: 'oc_session_id')
  final String ocSessionId;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  factory ClawChannel.fromJson(Map<String, dynamic> json) =>
      _$ClawChannelFromJson(json);

  Map<String, dynamic> toJson() => _$ClawChannelToJson(this);

  ClawChannel({
    required this.id,
    required this.userId,
    required this.userSessionId,
    required this.conversation,
    required this.ocSessionId,
    required this.createdAt,
    required this.updatedAt,
  });
}
