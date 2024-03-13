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

import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';

part 'course_grade.g.dart';

@JsonSerializable()
class CourseGradeObject {
  int? overall;

  int? content;

  int? workload;

  int? assessment;

  CourseGradeObject(this.overall, this.content, this.workload, this.assessment);

  factory CourseGradeObject.fromJson(Map<String, dynamic> json) =>
      _$CourseGradeObjectFromJson(json);

  Map<String, dynamic> toJson() => _$CourseGradeObjectToJson(this);
}

class CourseGrade with ChangeNotifier {
  int? _overall;

  int? _content;

  int? _workload;

  int? _assessment;

  int? get overall => _overall;

  set overall(int? val) {
    _overall = val;
    notifyListeners();
  }

  int? get content => _content;

  set content(int? val) {
    _content = val;
    notifyListeners();
  }

  int? get workload => _workload;

  set workload(int? val) {
    _workload = val;
    notifyListeners();
  }

  int? get assessment => _assessment;

  set assessment(int? val) {
    _assessment = val;
    notifyListeners();
  }

  CourseGrade(this._overall, this._content, this._workload, this._assessment);

  CourseGrade clone() =>
      CourseGrade(_overall, _content, _workload, _assessment);

  factory CourseGrade.fromJson(Map<String, dynamic> json) {
    final obj = CourseGradeObject.fromJson(json);
    return CourseGrade(
        obj.overall, 6 - obj.content!, 6 - obj.workload!, obj.assessment);
  }

  Map<String, dynamic> toJson() {
    final raw =
        CourseGrade(_overall, 6 - _content!, 6 - _workload!, _assessment);
    return CourseGradeObject(
            raw.overall, raw.content, raw.workload, raw.assessment)
        .toJson();
  }
}
