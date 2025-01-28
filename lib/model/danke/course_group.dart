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

import 'package:dan_xi/model/danke/course.dart';
import 'package:json_annotation/json_annotation.dart';

part 'course_group.g.dart';

@JsonSerializable()
class CourseGroup {
  // 课程代码
  int? id;
  String? name;
  String? code;
  String? department;

  @JsonKey(name: 'week_hour')
  int? weekHour;
  List<double>? credits;

  @JsonKey(name: 'course_list')
  List<Course>? courseList;

  /// These two fields are only valid when retrieving from the v3 Danke api
  /// Currently only the searching api has a v3 version
  @JsonKey(name: 'course_count')
  int? courseCount;
  @JsonKey(name: 'review_count')
  int? reviewCount;

  CourseGroup(
      {this.id,
      this.name,
      this.code,
      this.department,
      this.weekHour,
      this.credits,
      this.courseList});

  @override
  String toString() {
    return 'CourseGroup{id: $id, name: $name, code: $code, department: $department, weekHour: $weekHour, credits: $credits, course_list: $courseList}';
  }

  int getTotalReviewCount() {
    int sum = 0;
    for (var element in courseList!) {
      sum += element.reviewList!.length;
    }
    return sum;
  }

  String getFullName() {
    return "$department / $name";
  }

  factory CourseGroup.fromJson(Map<String, dynamic> json) =>
      _$CourseGroupFromJson(json);

  Map<String, dynamic> toJson() => _$CourseGroupToJson(this);

  @override
  bool operator ==(Object other) => (other is CourseGroup) && id == other.id;

  @override
  int get hashCode => id ?? name.hashCode;
}
