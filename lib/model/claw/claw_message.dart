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

part 'claw_message.g.dart';

@JsonSerializable()
class ClawMessage {
  final int id;
  final String type;
  final String from;
  final String content;
  @JsonKey(name: 'message_id')
  final String messageId;
  @JsonKey(name: 'channel_id')
  final int channelId;
  final int timestamp;
  final Map<String, dynamic>? media;
  final String? version;
  @JsonKey(name: 'task_id')
  final String? taskId;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  bool get isUser => from == 'user';

  factory ClawMessage.fromJson(Map<String, dynamic> json) =>
      _$ClawMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ClawMessageToJson(this);

  ClawMessage({
    required this.id,
    required this.type,
    required this.from,
    required this.content,
    required this.messageId,
    required this.channelId,
    required this.timestamp,
    this.media,
    this.version,
    this.taskId,
    this.createdAt,
    this.updatedAt,
  });
}
