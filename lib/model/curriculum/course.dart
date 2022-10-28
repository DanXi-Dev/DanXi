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

import 'package:dan_xi/model/curriculum/review.dart';
import 'package:json_annotation/json_annotation.dart';

part 'course.g.dart';

@JsonSerializable()
class Course {
  int? id;
  String? name;
  String? code;
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
  List<Review>? review_list;

  Course(
      this.id,
      this.name,
      this.code,
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

  @override
  bool operator ==(Object other) => (other is Course) && id == other.id;

  @override
  int get hashCode => id ?? name.hashCode;
}
