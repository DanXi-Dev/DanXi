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

import 'package:dan_xi/model/danke/course_review.dart';
import 'package:json_annotation/json_annotation.dart';

part 'course.g.dart';

@JsonSerializable()
class Course {
  int? course_id;
  String? course_name;
  String? course_code;
  String? code_id;
  double? credit;
  String? department;
  String? teachers;
  int? max_student;
  int? week_hour;

  /// (Copied from docs)
  /// 学年。如果是非秋季学期，则年数为（实际日期年数 - 1）。
  String? year;

  /// (Copied from docs)
  /// 学期。
  //     1：秋季学期；
  //     2：（第二年的）寒假；
  //     3：（第二年的）春季学期；
  //     4：（第二年的）暑假
  int? semester;
  List<CourseReview>? review_list;

  Course(
      this.course_id,
      this.course_name,
      this.course_code,
      this.code_id,
      this.credit,
      this.department,
      this.teachers,
      this.max_student,
      this.week_hour,
      this.year,
      this.semester,
      this.review_list);

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);

  Map<String, dynamic> toJson() => _$CourseToJson(this);

  factory Course.dummy() => Course(-3, "Asoul虚拟偶像运营与管理", "OP114514", "01", 4.0,
      "计算机科学与技术系", "Asoul", 100, 4, "2021", 1, [CourseReview.dummy()]);
  @override
  bool operator ==(Object other) =>
      (other is Course) && course_id == other.course_id;

  @override
  int get hashCode => course_id ?? course_name.hashCode;
}
