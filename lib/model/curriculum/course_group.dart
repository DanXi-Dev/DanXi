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

import 'package:dan_xi/model/curriculum/course.dart';
import 'package:json_annotation/json_annotation.dart';

part 'course_group.g.dart';

@JsonSerializable()
class CourseGroup {
  int? id;
  String? name;
  String? code;
  String? department;
  List<Course>? course_list;

  CourseGroup(this.id, this.name, this.code, this.department, this.course_list);

  @override
  String toString() {
    return 'CourseGroup{id: $id, name: $name, code: $code, department: $department, course_list: $course_list}';
  }

  factory CourseGroup.fromJson(Map<String, dynamic> json) =>
      _$CourseGroupFromJson(json);

  Map<String, dynamic> toJson() => _$CourseGroupToJson(this);

  @override
  bool operator ==(Object other) => (other is CourseGroup) && id == other.id;

  @override
  int get hashCode => id ?? name.hashCode;
}
