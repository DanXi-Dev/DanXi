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

import 'dart:ui';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/page/platform_subpage.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/stream_listener.dart';
import 'package:dan_xi/widget/danke/course_widgets.dart';
import 'package:dan_xi/widget/danke/review_vote_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';

import 'package:dan_xi/model/danke/course.dart';
import 'package:dan_xi/model/danke/course_grade.dart';
import 'package:dan_xi/model/danke/course_review.dart';

class CourseReviewWidget extends StatelessWidget {
  final CourseReview review;

  // changeable style of the card
  final bool translucent;

  const CourseReviewWidget(
      {Key? key, required this.review, this.translucent = false})
      : super(key: key);

  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: _buildCard(context));
  }

  Widget _buildCard(BuildContext context) {
    // style of the card
    final TextStyle infoStyle =
        TextStyle(color: Theme.of(context).hintColor, fontSize: 12);

    return Card(
      color: translucent
          ? Theme.of(context).cardTheme.color?.withOpacity(0.8)
          : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
      ),
      // credits group
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const ReviewVoteWidget(reviewVote: 0, reviewTotalVote: 10),
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 4,
                children: [
                  Column(
                    children: [
                      // course name, department name, course code and credits
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // use Expanded wrap the text to avoid overflow
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // todo add card information style
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 2),
                                  child: ReviewHeader(
                                    userId: review.reviewer_id!,
                                    teacher: review.parent!.teachers!,
                                    time: review.parent!.formatTime(),
                                  ),
                                ),
                                const Divider(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 2),
                                  child: Text(
                                    review.content!,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                        fontSize: 15),
                                  ),
                                ),
                                const Divider(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 2),
                                  child: ReviewFooter(
                                    overallLevel: translateScore(
                                        review.courseGrade!.overall),
                                    styleLevel: translateScore(
                                        review.courseGrade!.style),
                                    workloadLevel: translateScore(
                                        review.courseGrade!.workload),
                                    assessmentLevel: translateScore(
                                        review.courseGrade!.assessment),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ]),
          ),
        )
      ]),
    );
  }
}

// HydrogenC: Don't know what this widget is for
/*
class ReviewOperationBar extends StatefulWidget {
  final CourseReview review;

  const ReviewOperationBar({Key? key, required this.review}) : super(key: key);

  @override
  _ReviewOperationBarState createState() => _ReviewOperationBarState();
}

class _ReviewOperationBarState extends State<ReviewOperationBar> {
  int _liked = 0;
  int like = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // like button
        Row(
          children: [
            ReviewVoteWidget(reviewVote: 1, reviewTotalVote: 10),
            Text(
              like.toString(),
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 12),
            ),
          ],
        ),
        // comment button
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.comment,
                color: Theme.of(context).hintColor,
              ),
              onPressed: () {
                // todo comment
              },
            ),
            Text(
              "0",
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 12),
            ),
          ],
        ),
        // report button
        Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.flag,
                color: Theme.of(context).hintColor,
              ),
              onPressed: () {
                // todo report
              },
            ),
          ],
        ),
      ],
    );
  }
}
*/

class ReviewHeader extends StatelessWidget {
  final int userId;
  final String teacher;
  final String time;

  // final String reviewContent;

  const ReviewHeader(
      {Key? key,
      required this.userId,
      required this.teacher,
      required this.time})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const ColoredBox(
              // Todo: remove hardcoded colors
              color: Colors.deepOrange,
              child: SizedBox(width: 2, height: 12)),
          const SizedBox(width: 8),
          // user
          Text(
            "User $userId",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
              child: GestureDetector(
            onTap: () {},
            child: const Wrap(
              // todo this is the badge list of the user
              spacing: 3,
              alignment: WrapAlignment.end,
              children: [
                // rating
                Icon(
                  Icons.circle,
                  color: Colors.yellow,
                  size: 12,
                ),
                Icon(
                  Icons.circle,
                  color: Colors.red,
                  size: 12,
                ),
                Icon(
                  Icons.circle,
                  color: Colors.blue,
                  size: 12,
                ),
              ],
            ),
          )),

          /*
        
        */
          // review content
          // Padding(
          //   padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          //   child: Text(
          //     reviewContent,
          //     style: TextStyle(
          //         color: Theme.of(context).textTheme.bodyText1?.color,
          //         fontSize: 12),
          //   ),
          // )
        ],
      ),
      const SizedBox(height: 4),
      SizedBox(
        width: double.infinity,
        child: Wrap(
          // todo this is the badge list of the user
          spacing: 4,
          alignment: WrapAlignment.start,
          children: [
            // rating
            FilterTagWidget(
                color: Colors.deepPurpleAccent, text: teacher, onTap: () {}),
            FilterTagWidget(color: Colors.green, text: time, onTap: () {})
          ],
        ),
      ),
    ]);
  }
}

class ReviewFooter extends StatelessWidget {
  const ReviewFooter(
      {Key? key,
      required this.overallLevel,
      required this.styleLevel,
      required this.workloadLevel,
      required this.assessmentLevel})
      : super(key: key);

  final int overallLevel;
  final int styleLevel;
  final int workloadLevel;
  final int assessmentLevel;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(color: Colors.grey, fontSize: 12);

    return Column(
      children: [
        Wrap(
          spacing: 20,
          runSpacing: 6,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('总体评分', style: labelStyle),
                const SizedBox(
                  width: 6,
                ),
                Text(
                  overallWord[overallLevel],
                  style:
                      TextStyle(color: wordColor[overallLevel], fontSize: 12),
                )
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('课程风格', style: labelStyle),
                const SizedBox(
                  width: 6,
                ),
                Text(
                  styleWord[styleLevel],
                  style: TextStyle(color: wordColor[styleLevel], fontSize: 12),
                )
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('工作量', style: labelStyle),
                const SizedBox(
                  width: 6,
                ),
                Text(
                  workloadWord[workloadLevel],
                  style:
                      TextStyle(color: wordColor[workloadLevel], fontSize: 12),
                )
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('考核要求', style: labelStyle),
                const SizedBox(
                  width: 6,
                ),
                Text(
                  assessmentWord[assessmentLevel],
                  style: TextStyle(
                      color: wordColor[assessmentLevel], fontSize: 12),
                )
              ],
            )
          ],
        ),
      ],
    );
  }
}
