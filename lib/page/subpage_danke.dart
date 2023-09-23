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
import 'package:dan_xi/model/danke/course_group.dart';
import 'package:dan_xi/model/danke/course_review.dart';
import 'package:dan_xi/page/danke/course_list_widget.dart';
import 'package:dan_xi/page/home_page.dart';
import 'package:dan_xi/provider/fduhole_provider.dart';
import 'package:dan_xi/repository/danke/curriculum_board_repository.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/shared_preferences.dart';
import 'package:dan_xi/widget/danke/course_search_bar.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/widget/danke/course_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';

import '../widget/danke/random_review_widgets.dart';

class DankeSubPage extends PlatformSubpage<DankeSubPage> {
  @override
  DankeSubPageState createState() => DankeSubPageState();

  /// leading button
  // @override
  // Create<List<AppBarButtonItem>> get leading => (cxt) => [
  //   AppBarButtonItem(
  //     S.of(cxt).messages,
  //     Icon(PlatformX.isMaterial(cxt)
  //         ? Icons.notifications
  //         : CupertinoIcons.bell),
  //         () {
  //       // if (cxt.read<FDUHoleProvider>().isUserInitialized) {
  //       //   smartNavigatorPush(cxt, '/bbs/messages',
  //       //       forcePushOnMainNavigator: true);
  //       // }
  //     },
  //   )
  // ];

  const DankeSubPage({Key? key}) : super(key: key);

  @override
  Create<Widget> get title => (cxt) => Text(S.of(cxt).danke);

// @override
// Create<List<AppBarButtonItem>> get trailing => (cxt) => [
//   AppBarButtonItem(
//     S.of(cxt).add_courses,
//     Icon(PlatformX.isMaterial(cxt)
//         ? Icons.add
//         : CupertinoIcons.add_circled),
//         () => ManuallyAddCourseEvent().fire(),
//   ),
//   AppBarButtonItem(
//     S.of(cxt).share,
//     Icon(PlatformX.isMaterial(cxt)
//         ? Icons.share
//         : CupertinoIcons.square_arrow_up),
//         () => ShareTimetableEvent().fire(),
//   ),
// ];

  /// trailing buttons
// @override
// Create<List<AppBarButtonItem>> get trailing {
//   return (cxt) => [
//         AppBarButtonItem(S.of(cxt).refresh, Icon(PlatformIcons(cxt).refresh),
//             () {
//           // RefreshPageEvent().fire();
//         }),
//         AppBarButtonItem(
//             S.of(cxt).reset,
//             Icon(PlatformX.isMaterial(cxt)
//                 ? Icons.medical_services_outlined
//                 : CupertinoIcons.rays), () {
//           // ResetWebViewEvent().fire();
//         }),
//       ];
// }
}

class DankeSubPageState extends PlatformSubpageState<DankeSubPage> {
  // When searching is idle, show random reviews
  bool idle = true;
  double searchBarPositionBoxHeight = 180;
  String searchText = '';

  FileImage? _backgroundImage;

  @override
  Widget buildPage(BuildContext context) {
    _backgroundImage = SettingsProvider.getInstance().backgroundImage;
    return Container(
        // padding top
        decoration: _backgroundImage == null
            ? null
            : BoxDecoration(
                image: DecorationImage(
                    image: _backgroundImage!, fit: BoxFit.cover)),
        child: Column(
          mainAxisAlignment:
              idle ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            // animated sized box
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: searchBarPositionBoxHeight,
            ),
            CourseSearchBar(
              onSearch: (String text) {
                setState(
                  () {
                    idle = text.isEmpty;
                    searchBarPositionBoxHeight = idle ? 180 : 0;
                    searchText = text;
                  },
                );
              },
            ),
            /*
        const ReviewVoteWidget(
          reviewTotalVote: 10,
          reviewVote: 0,
        ),
        CourseReviewWidget(
          review: CourseReview.dummy(),
        )
         */
            _buildPageContent(context)
          ],
          // button
        ));
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
        ? FutureBuilder(
            future: _loadRandomReview(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return RandomReviewWidgets(review: snapshot.data!);
              } else {
                return Center(child: PlatformCircularProgressIndicator());
              }
            })
        : CourseListWidget(searchKeyword: searchText);
  }
}
