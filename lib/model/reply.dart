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

part 'reply.g.dart';

@JsonSerializable()
class Reply {
  final int id;
  final String content;
  final String username;
  final int reply_to;
  final String date_created;
  final int discussion;
  final bool is_me;

  @override
  int get hashCode => id;

  @override
  bool operator ==(Object other) => (other is Reply) && id == other.id;

  Reply(this.id, this.content, this.username, this.reply_to, this.date_created,
      this.discussion, this.is_me);

  factory Reply.fromJson(Map<String, dynamic> json) => _$ReplyFromJson(json);

  Map<String, dynamic> toJson() => _$ReplyToJson(this);

  /// Generate an empty Reply for special sakes.
  factory Reply.dummy() => Reply(-1, "", "", null, "", -1, false);
}
