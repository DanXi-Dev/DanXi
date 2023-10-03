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
import 'package:dan_xi/model/danke/search_results.dart';
import 'package:dan_xi/repository/danke/curriculum_board_repository.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/shared_preferences.dart';
import 'package:dan_xi/widget/danke/course_widgets.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

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
  List<CourseGroup> _searchResults = [];
  String? searchKeyword;

  Future<List<CourseGroup>?> _fetchResults() async {
    CourseSearchResults? result = await CurriculumBoardRepository.getInstance()
        .searchCourseGroups(searchKeyword!);
    if (result == null || result.items == null) {
      return [];
    }

    return result.items!;
  }

  @override
  void initState() {
    super.initState();
    searchKeyword = widget.searchKeyword;
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
            future: _fetchResults(),
            successBuilder: (context, snapshot) {
              _searchResults = snapshot.data!;
              return _buildPageBody(context);
            },
            errorBuilder: (BuildContext context,
                    AsyncSnapshot<List<CourseGroup>?> snapshot) =>
                ErrorPageWidget.buildWidget(context, snapshot.error,
                    stackTrace: snapshot.stackTrace,
                    onTap: () => setState(() {})),
            loadingBuilder: Center(
              child: PlatformCircularProgressIndicator(),
            )));
  }

  Widget _buildPageBody(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return CourseGroupCardWidget(courses: _searchResults[index]);
      },
      itemCount: _searchResults.length,
      scrollDirection: Axis.vertical,
    );
  }
}
