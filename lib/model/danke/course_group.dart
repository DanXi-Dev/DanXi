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
  int? weekHour;
  double? credit;
  List<Course>? courseList;

  CourseGroup(this.id, this.name, this.code, this.department, this.weekHour,
      this.credit, this.courseList);

  @override
  String toString() {
    return 'CourseGroup{id: $id, name: $name, code: $code, department: $department, weekHour: $weekHour, credit: $credit, course_list: $courseList}';
  }

  int getTotalReviewCount() {
    int sum = 0;
    for (var element in courseList!) {
      sum += element.reviewList!.length;
    }
    return sum;
  }

  factory CourseGroup.fromJson(Map<String, dynamic> json) =>
      _$CourseGroupFromJson(json);

  Map<String, dynamic> toJson() => _$CourseGroupToJson(this);

  factory CourseGroup.dummy() => CourseGroup(
      -1, "Asoul虚拟偶像运营与管理", "OP114514", "计算机科学与技术系", 4, 4.0, [Course.dummy()]);

  @override
  bool operator ==(Object other) => (other is CourseGroup) && id == other.id;

  @override
  int get hashCode => id ?? name.hashCode;
}
