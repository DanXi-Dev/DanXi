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

import 'package:json_annotation/json_annotation.dart';

part 'course_grade.g.dart';

@JsonSerializable()
class CourseGrade {
  int? overall;
  int? content;
  int? workload;
  int? assessment;

  // Indicates the format of the grade,
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool isClientFormat = false;

  CourseGrade(this.overall, this.content, this.workload, this.assessment,
      {this.isClientFormat = false});

  CourseGrade withFields(
          {int? overall, int? content, int? workload, int? assessment}) =>
      CourseGrade(overall ?? this.overall, content ?? this.content,
          workload ?? this.workload, assessment ?? this.assessment);

  CourseGrade convertFormat() {
    // Reverse the content and workload score
    return CourseGrade(overall, 6 - content!, 6 - workload!, assessment,
        isClientFormat: !isClientFormat);
  }

  factory CourseGrade.fromJson(Map<String, dynamic> json) =>
      _$CourseGradeFromJson(json);

  Map<String, dynamic> toJson() => _$CourseGradeToJson(this);
}
