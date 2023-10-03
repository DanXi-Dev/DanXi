/*
 *     Copyright (C) 2021  DanXi-Dev
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
import 'package:dan_xi/model/danke/course_review.dart';
import 'package:dan_xi/page/danke/course_list_widget.dart';
import 'package:dan_xi/page/home_page.dart';
import 'package:dan_xi/provider/fduhole_provider.dart';
import 'package:dan_xi/repository/danke/curriculum_board_repository.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/widget/danke/course_search_bar.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/widget/danke/course_widgets.dart';
import 'package:dan_xi/widget/danke/random_review_widgets.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/sized_by_child_builder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';

class DankeSubPage extends PlatformSubpage<DankeSubPage> {
  @override
  DankeSubPageState createState() => DankeSubPageState();

  const DankeSubPage({Key? key}) : super(key: key);

  @override
  Create<Widget> get title => (cxt) => Text(S.of(cxt).curriculum);
}

class DankeSubPageState extends PlatformSubpageState<DankeSubPage> {
  // When searching is idle, show random reviews
  bool idle = true;
  String searchText = '';

  FileImage? _backgroundImage;

  @override
  Widget buildPage(BuildContext context) {
    if (overallWord == null) {
      overallWord = S.of(context).curriculum_ratings_overall_words.split(';');
      contentWord = S.of(context).curriculum_ratings_content_words.split(';');
      workloadWord = S.of(context).curriculum_ratings_workload_words.split(';');
      assessmentWord =
          S.of(context).curriculum_ratings_assessment_words.split(';');
    }

    _backgroundImage = SettingsProvider.getInstance().backgroundImage;
    return Container(
      // padding top
      decoration: _backgroundImage == null
          ? null
          : BoxDecoration(
              image:
                  DecorationImage(image: _backgroundImage!, fit: BoxFit.cover)),
      child: LayoutBuilder(
          builder: (context, constraints) => SizedByChildBuilder(
              child: (context, key) => CourseSearchBar(
                    onSearch: (text) {},
                  ),
              builder: (context, size) => Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // animated sized box
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        // Golden ratio minus the height of the title bar
                        height: idle
                            ? (constraints.maxHeight * 0.382 - size.height)
                                .clamp(0, constraints.maxHeight - size.height)
                            : 0,
                      ),
                      CourseSearchBar(
                        onSearch: (String text) {
                          setState(
                            () {
                              idle = text.isEmpty;
                              searchText = text;
                            },
                          );
                        },
                      ),
                      _buildPageContent(context)
                    ],
                    // button
                  ))),
    );
  }

  Future<CourseReview?> _loadRandomReview() async {
    if (!context.read<FDUHoleProvider>().isUserInitialized) {
      await OpenTreeHoleRepository.getInstance().initializeRepo();
      settingsPageKey.currentState?.setState(() {});
    }

    return CurriculumBoardRepository.getInstance().getRandomReview();
  }

  Widget _buildPageContent(BuildContext context) {
    return idle
        ? FutureWidget<CourseReview?>(
            future: _loadRandomReview(),
            successBuilder: (context, snapshot) => RandomReviewWidgets(
                review: snapshot.data!, onTap: () => setState(() {})),
            errorBuilder:
                (BuildContext context, AsyncSnapshot<CourseReview?> snapshot) =>
                    errorCard(snapshot, () => setState(() {})),
            loadingBuilder: Center(
              child: PlatformCircularProgressIndicator(),
            ))
        : CourseListWidget(searchKeyword: searchText);
  }
}
