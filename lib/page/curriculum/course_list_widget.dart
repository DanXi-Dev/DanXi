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
import 'package:dan_xi/model/curriculum/course_group.dart';
import 'package:dan_xi/model/opentreehole/jwt.dart';
import 'package:dan_xi/provider/fduhole_provider.dart';
import 'package:dan_xi/repository/curriculum/curriculum_board_repository.dart';
import 'package:dan_xi/util/lazy_future.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';

/// A list of courses.
///
/// Note: this widget is not a complete page!
class CourseListWidget extends StatefulWidget {
  @override
  CourseListWidgetState createState() => CourseListWidgetState();

  const CourseListWidget({Key? key}) : super(key: key);
}

class CourseListWidgetState extends State<CourseListWidget> {
  late Future<List<CourseGroup>?> _future;
  List<CourseGroup>? _groups;

  Future<List<CourseGroup>?> _setFuture(JWToken? token) {
    return LazyFuture.pack(
        CurriculumBoardRepository.getInstance().getCourseGroups(token!));
  }

  Future<List<CourseGroup>?> refresh() {
    _future = _setFuture(context.read<FDUHoleProvider>().token);
    setState(() {});
    return _future;
  }

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureWidget<List<CourseGroup>?>(
        future: _future,
        successBuilder: (context, snapshot) {
          _groups = snapshot.data;
          return _buildPageBody(context);
        },
        errorBuilder: (BuildContext context,
                AsyncSnapshot<List<CourseGroup>?> snapshot) =>
            ErrorPageWidget(
              errorMessage: ErrorPageWidget.generateUserFriendlyDescription(
                  S.of(context), snapshot.error),
              error: snapshot.error,
              trace: snapshot.stackTrace,
              onTap: refresh,
              buttonText: S.of(context).retry,
            ),
        loadingBuilder: Center(
          child: PlatformCircularProgressIndicator(),
        ));
  }

  Widget _buildPageBody(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return Card(
          child: Text(_groups![index].name!),
        );
      },
      itemCount: _groups!.length,
    );
  }
}
