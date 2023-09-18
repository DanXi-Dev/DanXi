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
import 'package:dan_xi/model/time_table.dart';
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
    throw UnimplementedError();
  }

  _buildCard(BuildContext context) {
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
                                  child: ReviewerHeader(
                                      userId: review.reviewer_id!),
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
                  color: Theme.of(context).textTheme.bodyText1?.color,
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
                  color: Theme.of(context).textTheme.bodyText1?.color,
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

class ReviewerHeader extends StatelessWidget {
  final int userId;

  // final String reviewContent;

  const ReviewerHeader({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // user
        Text(
          "| user $userId",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const Wrap(
          // todo this is the badge list of the user
          spacing: 3,
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
    );
  }
}
