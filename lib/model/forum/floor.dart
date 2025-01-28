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

import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/util/forum/clean_mode_filter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'floor.g.dart';

@JsonSerializable()
class OTFloor {
  int? floor_id;
  int? hole_id;
  String? content;
  String? anonyname;
  String? time_updated;
  String? time_created;
  String? special_tag;
  bool? deleted;
  bool? is_me;
  bool? liked;
  List<String>? fold;
  int? modified;
  int? like;
  List<OTFloor>? mention;
  int? dislike;
  bool? disliked;

  factory OTFloor.fromJson(Map<String, dynamic> json) =>
      _$OTFloorFromJson(json);

  Map<String, dynamic> toJson() => _$OTFloorToJson(this);

  /// Generate an empty BBSPost for special sakes.
  factory OTFloor.dummy() =>
      OTFloor(-1, -1, '', '', '', '', false, [], 0, false, false, [], 0, false);

  factory OTFloor.special(String title, String content,
          [int? holeId, int? floorId]) =>
      OTFloor(floorId ?? 0, holeId ?? 0, content, title, '', '', false, [], 0,
          false, false, [], 0, false);

  factory OTFloor.onlyId(int floorId) => OTFloor.special('', '', null, floorId);

  /// Check whether the object has a valid position (i.e. valid floor and hole id).
  bool get valid => (floor_id ?? -1) > 0 && (hole_id ?? -1) > 0;

  @override
  bool operator ==(Object other) =>
      (other is OTFloor) && floor_id == other.floor_id;

  OTFloor(
      this.floor_id,
      this.hole_id,
      this.content,
      this.anonyname,
      this.time_created,
      this.time_updated,
      this.deleted,
      this.fold,
      this.like,
      this.is_me,
      this.liked,
      this.mention,
      this.dislike,
      this.disliked);

  OTFloor copyWith({
    int? floor_id,
    int? hole_id,
    String? content,
    String? anonyname,
    String? time_updated,
    String? time_created,
    bool? deleted,
    bool? is_me,
    bool? liked,
    List<String>? fold,
    int? modified,
    int? like,
    List<OTFloor>? mention,
    int? dislike,
    bool? disliked,
  }) {
    return OTFloor(
      floor_id ?? this.floor_id,
      hole_id ?? this.hole_id,
      content ?? this.content,
      anonyname ?? this.anonyname,
      time_updated ?? this.time_updated,
      time_created ?? this.time_created,
      deleted ?? this.deleted,
      fold ?? this.fold,
      modified ?? this.modified,
      is_me ?? this.is_me,
      liked ?? this.liked,
      mention ?? this.mention,
      dislike ?? this.dislike,
      disliked ?? this.disliked,
    );
  }

  String? get filteredContent => SettingsProvider.getInstance().cleanMode
      ? CleanModeFilter.cleanText(content)
      : content;

  String? get deleteReason => deleted == true ? content : null;

  String? get foldReason => fold?.isNotEmpty == true ? fold?.join(' ') : null;

  @override
  String toString() {
    return 'OTFloor{floor_id: $floor_id, hole_id: $hole_id, content: $content, anonyname: $anonyname, time_updated: $time_updated, time_created: $time_created, special_tag: $special_tag, deleted: $deleted, is_me: $is_me, liked: $liked, fold: $fold, modified: $modified, like: $like, mention: $mention}';
  }

  @override
  int get hashCode => floor_id ?? 0;
}
