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
import 'package:dan_xi/model/opentreehole/floor.dart';
import 'package:json_annotation/json_annotation.dart';

import 'course.dart';
import 'course_grade.dart';

part 'course_review.g.dart';

/// [CourseReview] is the model class for course review.
/// It is used to store the data of a course review analogous to the [OTFloor].
///
/// [reviewer_id] is
/// [liked] is used to show whether the user have up vote or down vote the review, 1 for up vote, -1 for down vote, 0 for no vote.
/// [isMe] is used to show whether the review is written by the user.
/// [modified] is used to show whether the review is modified.
/// [deleted] is used to show whether the review is deleted, regardless of being deleted by the user or by the administrator.
/// [reviewExtra] is used to store the extra information of the review, such as the achievements of the reviewer.
/// For now, extra only contains the achievements of the reviewer, e.g. badges.

@JsonSerializable()
class CourseReview {
  /// The unique id of a review, based on which the review is compared.
  int? review_id;

  /// The user id of the reviewer.
  int? reviewer_id;

  /// The title of the review.
  String? title;

  /// The content of the review.
  String? content;
  String? timeCreated;
  String? timeUpdated;
  CourseGrade? courseGrade;
  int? like;
  int? liked;
  bool? isMe;
  int? modified;
  bool? deleted;
  ReviewExtra? reviewExtra;
  Course? parent;

  /// [fromJson] and [toJson] are used to convert between JSON and [CourseReview] object.
  factory CourseReview.fromJson(Map<String, dynamic> json) =>
      _$CourseReviewFromJson(json);

  Map<String, dynamic> toJson() => _$CourseReviewToJson(this);

  /// [dummy] is used to generate a dummy [CourseReview] object for testing.
  factory CourseReview.dummy() => CourseReview(
      114514,
      114514,
      "作为嘉然小姐的狗的测评",
      "关注嘉然天天天天天天解馋",
      "dummy",
      "dummy",
      CourseGrade.dummy(),
      100,
      1,
      true,
      0,
      false,
      ReviewExtra.dummy());

  /// override == and hashCode to compare two [CourseReview] objects.
  @override
  bool operator ==(Object other) =>
      (other is CourseReview) && review_id == other.review_id;

  CourseReview(
      this.review_id,
      this.reviewer_id,
      this.title,
      this.content,
      this.timeCreated,
      this.timeUpdated,
      this.courseGrade,
      this.like,
      this.liked,
      this.isMe,
      this.modified,
      this.deleted,
      this.reviewExtra);

  String? get deleteReason => deleted == true ? content : null;

  @override
  String toString() {
    return 'CourseReview{review_id: $review_id, reviewer_id: $reviewer_id, title: $title, content: $content, timeCreated: $timeCreated, timeUpdated: $timeUpdated, course_grade: $courseGrade, like: $like, liked: $liked, is_me: $isMe, modified: $modified, deleted: $deleted, extra: $reviewExtra}';
  }

  @override
  int get hashCode => review_id ?? timeCreated.hashCode;

  void linkCourse(Course c) {
    parent = c;
  }
}
