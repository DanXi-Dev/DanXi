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

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/danke/course_group.dart';
import 'package:dan_xi/model/danke/search_results.dart';
import 'package:dan_xi/repository/danke/curriculum_board_repository.dart';
import 'package:dan_xi/widget/danke/course_widgets.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// A list of courses.
///
/// Note: this widget is not a complete page!
class CourseListWidget extends StatefulWidget {
  @override
  CourseListWidgetState createState() => CourseListWidgetState();

  final String? searchKeyword;

  const CourseListWidget({super.key, this.searchKeyword});
}

class CourseListWidgetState extends State<CourseListWidget> {
  String? searchKeyword;

  final PagedListViewController<CourseGroup> _listViewController =
      PagedListViewController<CourseGroup>();

  Future<List<CourseGroup>?> _loadContent(int page) async {
    CourseSearchResults? result = await CurriculumBoardRepository.getInstance()
        .searchCourseGroups(searchKeyword!, page: page);
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
    searchKeyword = widget.searchKeyword;
    _listViewController.notifyUpdate(
        useInitialData: false, queueDataClear: false);
  }

  @override
  Widget build(BuildContext context) {
    return PagedListView<CourseGroup>(
        pagedController: _listViewController,
        withScrollbar: true,
        scrollController: PrimaryScrollController.of(context),
        // If we need to scroll to the end, we should prefetch all the data beforehand.
        // See also [prefetchAllFloors] in [ForumSubpageState].
        dataReceiver: _loadContent,
        builder: _getListItems,
        loadingBuilder: (BuildContext context) => Container(
              padding: const EdgeInsets.all(8),
              child: Center(child: PlatformCircularProgressIndicator()),
            ),
        fatalErrorBuilder: (context, error) => ErrorPageWidget.buildWidget(
            context, error,
            onTap: () => setState(() {})),
        endBuilder: (context) => Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(S.of(context).end_reached),
              ),
            ),
        emptyBuilder: (context) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(S.of(context).no_data),
              ),
            ));
  }

  Widget _getListItems(BuildContext context,
      ListProvider<CourseGroup> dataProvider, int index, CourseGroup group) {
    return CourseGroupCardWidget(courseGroup: group);
  }
}
