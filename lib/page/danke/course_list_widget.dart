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

import 'dart:convert';

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/danke/course_group.dart';
import 'package:dan_xi/repository/danke/curriculum_board_repository.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/shared_preferences.dart';
import 'package:dan_xi/widget/danke/course_widgets.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:flutter/material.dart';

/// A list of courses.
///
/// Note: this widget is not a complete page!
class CourseListWidget extends StatefulWidget {
  @override
  CourseListWidgetState createState() => CourseListWidgetState();

  final String? searchKeyword;

  CourseListWidget({Key? key, this.searchKeyword}) : super(key: key);
}

class CourseListWidgetState extends State<CourseListWidget> {
  static List<CourseGroup>? _groups;
  List<CourseGroup>? _displayedGroups;
  String? searchKeyword;

  XSharedPreferences? pref;

  Future<List<CourseGroup>?> _fetchMegaList() async {
    pref ??= await XSharedPreferences.getInstance();

    // List is LARGE, avoid deserializing for a second time
    if (_groups != null) {
      return _groups;
    }

    String? coursesJson;
    if (pref!.containsKey("course_groups")) {
      coursesJson = pref!.getString("course_groups");
    } else {
      coursesJson =
          await CurriculumBoardRepository.getInstance().getCourseGroups();
      pref!.setString("course_groups", coursesJson);
    }

    List<dynamic> jsonArray = jsonDecode(coursesJson!);
    return jsonArray.map((e) => CourseGroup.fromJson(e)).toList();
  }

  Future<List<CourseGroup>?> _fetchList() async {
    _groups ??= await _fetchMegaList();

    if (searchKeyword != null) {
      var searchPattern = searchKeyword!.startsWith('#')
          ? searchKeyword!.substring(1)
          : searchKeyword!;
      return searchKeyword!.startsWith('#')
          ? _groups.filter((element) => element.code!.contains(searchPattern))
          : _groups.filter((element) => element.name!.contains(searchPattern));
    } else {
// This shall not happen
      return _groups!.take(20).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      searchKeyword = widget.searchKeyword;
    });
  }

  @override
  void didUpdateWidget(covariant CourseListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      searchKeyword = widget.searchKeyword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: FutureWidget<List<CourseGroup>?>(
            future: _fetchList(),
            successBuilder: (context, snapshot) {
              _displayedGroups = snapshot.data;
              return _buildPageBody(context);
            },
            errorBuilder: (BuildContext context,
                    AsyncSnapshot<List<CourseGroup>?> snapshot) =>
                errorCard(snapshot, () => setState(() {})),
            loadingBuilder: Center(
              child: Column(children: [
                const SizedBox(height: 6),
                Text(S.of(context).curriculum_first_load)
              ]),
            )));
  }

  Widget _buildPageBody(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return CourseGroupCardWidget(courses: _displayedGroups![index]);
      },
      itemCount: _displayedGroups!.length,
      scrollDirection: Axis.vertical,
    );
  }
}
