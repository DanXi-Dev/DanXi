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

import 'package:flutter_tagging/flutter_tagging.dart';
import 'package:json_annotation/json_annotation.dart';

part 'post_tag.g.dart';

@JsonSerializable()
class PostTag extends Taggable {
  final String name;
  final String color;
  final int count;

  PostTag(this.name, this.color, this.count);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is PostTag &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => super.hashCode ^ name.hashCode;

  factory PostTag.fromJson(Map<String, dynamic> json) =>
      _$PostTagFromJson(json);

  Map<String, dynamic> toJson() => _$PostTagToJson(this);

  /// Generate an empty BBSPost for special sakes.
  factory PostTag.dummy() => PostTag("默认", "red", 0);

  @override
  List<Object> get props => [name];
}
