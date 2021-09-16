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

import 'package:dan_xi/model/post_tag.dart';
import 'package:dan_xi/model/reply.dart';
import 'package:json_annotation/json_annotation.dart';

part 'post.g.dart';

@JsonSerializable()
class BBSPost {
  int id;

  // ignore: non_constant_identifier_names
  Reply first_post;
  int count;
  List<PostTag> tag;
  Map<String, String> mapping;

  // ignore: non_constant_identifier_names
  String date_created;

  // ignore: non_constant_identifier_names
  String date_updated;

  // ignore: non_constant_identifier_names
  bool is_folded;

  // ignore: non_constant_identifier_names
  Reply last_post;

  List<Reply> posts;

  //bool is_top;


  factory BBSPost.fromJson(Map<String, dynamic> json) =>
      _$BBSPostFromJson(json);

  Map<String, dynamic> toJson() => _$BBSPostToJson(this);

  @override
  bool operator ==(Object other) => (other is BBSPost) && id == other.id;

  BBSPost(this.id, this.first_post, this.count, this.tag, this.mapping,
      this.is_folded, this.date_created, this.date_updated, this.posts);

  /// Generate an empty BBSPost for special sakes.
  factory BBSPost.dummy() => BBSPost(
      -1, Reply.dummy(), -1, [PostTag.dummy()], null, false, "", "", []);

  static final DUMMY_POST = BBSPost.dummy();

  @override
  int get hashCode => id;
}
