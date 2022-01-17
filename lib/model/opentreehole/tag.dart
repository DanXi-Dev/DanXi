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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/widget/opentreehole/tag_selector/flutter_tagging/taggable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tag.g.dart';

@JsonSerializable()
class OTTag extends Taggable {
  final int? tag_id;
  final int? temperature;
  final String? name;

  factory OTTag.fromJson(Map<String, dynamic> json) => _$OTTagFromJson(json);

  Map<String, dynamic> toJson() => _$OTTagToJson(this);

  @override
  bool operator ==(Object other) => (other is OTTag) && tag_id == other.tag_id;

  const OTTag(this.tag_id, this.temperature, this.name);

  @override
  int get hashCode => tag_id!;

  String get color {
    if (name == null || name!.isEmpty || name!.startsWith("*")) return 'red';
    var sum = 0;
    for (var code in name!.runes) {
      sum += code;
    }
    return Constant.TAG_COLOR_LIST[sum % Constant.TAG_COLOR_LIST.length];
  }

  @override
  List<Object> get props {
    if (name == null) return [];
    return [name!];
  }
}
