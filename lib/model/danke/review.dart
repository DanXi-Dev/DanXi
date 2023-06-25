/*
 *     Copyright (C) 2022  DanXi-Dev
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
import 'dart:core';

import 'package:dan_xi/model/danke/review_extra.dart';
import 'package:json_annotation/json_annotation.dart';

import 'course_rank.dart';

part 'review.g.dart';

@JsonSerializable()
class Review {
  int? id;
  int? reviewerId;
  String? title;
  String? content;
  String? timeCreated;
  String? timeUpdated;
  Rank? rank;
  int? remark;
  int? vote;
  bool? isMe;
  ReviewExtra? extra;

  Review(
      this.id,
      this.reviewerId,
      this.title,
      this.content,
      this.timeCreated,
      this.timeUpdated,
      this.rank,
      this.remark,
      this.vote,
      this.isMe,
      this.extra);

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewToJson(this);

  @override
  bool operator ==(Object other) => (other is Review) && id == other.id;

  @override
  int get hashCode => id ?? timeCreated.hashCode;
}

class Achievement {
  String? name;
}
