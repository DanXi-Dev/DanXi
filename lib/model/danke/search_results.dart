/*
 *     Copyright (C) 2023  DanXi-Dev
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

import 'package:dan_xi/model/danke/course_group.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_results.g.dart';

@JsonSerializable()
class CourseSearchResults {
  int? page;
  @JsonKey(name: 'page_size')
  int? pageSize;
  String? extra;
  List<CourseGroup>? items;

  CourseSearchResults(this.page, this.pageSize, this.extra, this.items);

  factory CourseSearchResults.fromJson(Map<String, dynamic> json) =>
      _$CourseSearchResultsFromJson(json);

  Map<String, dynamic> toJson() => _$CourseSearchResultsToJson(this);
}
