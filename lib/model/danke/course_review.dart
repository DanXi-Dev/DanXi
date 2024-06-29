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
import 'package:dan_xi/model/forum/floor.dart';
import 'package:json_annotation/json_annotation.dart';

import 'course.dart';
import 'course_grade.dart';

part 'course_review.g.dart';

/// [CourseReview] is the model class for course review.
/// It is used to store the data of a course review analogous to the [OTFloor].
///
/// [reviewerId] is the id of the author of the review
/// [vote] is used to show whether the user have up vote or down vote the review, 1 for up vote, -1 for down vote, 0 for no vote.
/// [isMe] is used to show whether the review is written by the user.
/// [modified] is used to show whether the review is modified.
/// [deleted] is used to show whether the review is deleted, regardless of being deleted by the user or by the administrator.
/// [extra] is used to store the extra information of the review, such as the achievements of the reviewer.
/// For now, extra only contains the achievements of the reviewer, e.g. badges.
/// TODO: Implement badge showing

@JsonSerializable()
class CourseReview {
  /// The unique id of a review, based on which the review is compared.
  @JsonKey(name: 'id')
  int? reviewId;

  /// The user id of the reviewer.
  @JsonKey(name: 'reviewer_id')
  int? reviewerId;

  /// The title of the review.
  String? title;

  /// The content of the review.
  String? content;
  String? timeCreated;
  String? timeUpdated;
  CourseGrade? rank;
  int? remark;
  int? vote;

  @JsonKey(name: 'is_me')
  bool? isMe;

  int? modified;
  bool? deleted;

  ReviewExtra? extra;

  // Info about its parent course for display
  @JsonKey(includeFromJson: false, includeToJson: false)
  late CourseSummary courseInfo;

  /// These fields is only used when deserializing random reviews !!!
  Course? course;
  @JsonKey(name: 'group_id')
  int? groupId;

  /// [fromJson] and [toJson] are used to convert between JSON and [CourseReview] object.
  factory CourseReview.fromJson(Map<String, dynamic> json) =>
      _$CourseReviewFromJson(json);

  Map<String, dynamic> toJson() => _$CourseReviewToJson(this);

  /// override == and hashCode to compare two [CourseReview] objects.
  @override
  bool operator ==(Object other) =>
      (other is CourseReview) && reviewId == other.reviewId;

  CourseReview(
      {this.reviewId,
      this.reviewerId,
      this.title,
      this.content,
      this.timeCreated,
      this.timeUpdated,
      this.rank,
      this.vote,
      this.isMe,
      this.modified,
      this.deleted,
      this.extra});

  String? get deleteReason => deleted == true ? content : null;

  @override
  String toString() {
    return 'CourseReview{review_id: $reviewId, reviewer_id: $reviewerId, title: $title, content: $content, timeCreated: $timeCreated, timeUpdated: $timeUpdated, rank: $rank, vote: $vote, is_me: $isMe, modified: $modified, deleted: $deleted, extra: $extra}';
  }

  @override
  int get hashCode => reviewId ?? reviewId.hashCode;

  // Fetch some info about its parent course for display
  void linkCourse(CourseSummary cs) {
    courseInfo = cs;
  }
}

class CourseSummary {
  String teachers, time;
  int id;

  CourseSummary(this.id, this.teachers, this.time);
}
