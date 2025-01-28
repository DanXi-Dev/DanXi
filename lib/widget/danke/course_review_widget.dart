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

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/danke/course_group.dart';
import 'package:dan_xi/model/danke/course_review.dart';
import 'package:dan_xi/page/danke/course_review_editor.dart';
import 'package:dan_xi/page/forum/hole_detail.dart';
import 'package:dan_xi/repository/danke/curriculum_board_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/widget/danke/course_widgets.dart';
import 'package:dan_xi/widget/danke/review_vote_widget.dart';
import 'package:dan_xi/widget/forum/forum_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CourseReviewWidget extends StatelessWidget {
  final CourseReview review;
  final CourseGroup courseGroup;
  final void Function(CourseReview?)? reviewOperationCallback;

  // changeable style of the card
  final bool translucent;

  const CourseReviewWidget(
      {super.key,
      required this.review,
      required this.courseGroup,
      this.translucent = false,
      this.reviewOperationCallback});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: _buildCard(context));
  }

  Widget _buildCard(BuildContext context) {
    return Card(
      color: translucent
          ? Theme.of(context).cardTheme.color?.withValues(alpha: 0.8)
          : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
      ),
      // credits group
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ReviewVoteWidget(
            myVote: review.vote!,
            reviewVote: review.remark!,
            reviewId: review.reviewId!),
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // todo add card information style
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  child: ReviewHeader(
                    userId: review.reviewerId!,
                    teacher: review.courseInfo.teachers,
                    time: review.courseInfo.time,
                    title: review.title!,
                  ),
                ),
                const Divider(),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  child: smartRender(
                      context, review.content!, null, null, translucent),
                ),
                const Divider(),
                Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    child: Row(children: [
                      Expanded(
                        child: ReviewFooter(
                          overallLevel: review.rank!.overall! - 1,
                          styleLevel: review.rank!.content! - 1,
                          workloadLevel: review.rank!.workload! - 1,
                          assessmentLevel: review.rank!.assessment! - 1,
                        ),
                      ),
                      if (review.isMe!)
                        ModifyMenuWidget(
                          originalReview: review,
                          courseGroup: courseGroup,
                          reviewOperationCallback:
                              reviewOperationCallback ?? (rev) {},
                        )
                    ])),
              ],
            ),
          ),
        )
      ]),
    );
  }
}

class ReviewHeader extends StatelessWidget {
  final int userId;
  final String teacher;
  final String title;
  final String time;

  // final String reviewContent;

  const ReviewHeader(
      {super.key,
      required this.userId,
      required this.teacher,
      required this.time,
      required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
              runSpacing: 2,
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
        ],
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Wrap(
          // todo this is the badge list of the user
          spacing: 3,
          runSpacing: 2,
          alignment: WrapAlignment.start,
          children: [
            // rating
            FilterTagWidget(
                color: Colors.deepPurpleAccent, text: teacher, onTap: () {}),
            FilterTagWidget(color: Colors.green, text: time, onTap: () {})
          ],
        ),
      ),
      Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))
    ]);
  }
}

class ReviewFooter extends StatelessWidget {
  const ReviewFooter(
      {super.key,
      required this.overallLevel,
      required this.styleLevel,
      required this.workloadLevel,
      required this.assessmentLevel});

  final int overallLevel;
  final int styleLevel;
  final int workloadLevel;
  final int assessmentLevel;

  @override
  Widget build(BuildContext context) {
    final overallWord =
        S.of(context).curriculum_ratings_overall_words.split(';');
    final contentWord =
        S.of(context).curriculum_ratings_content_words.split(';');
    final workloadWord =
        S.of(context).curriculum_ratings_workload_words.split(';');
    final assessmentWord =
        S.of(context).curriculum_ratings_assessment_words.split(';');

    const labelStyle = TextStyle(color: Colors.grey, fontSize: 12);

    return Wrap(
      spacing: 20,
      runSpacing: 6,
      alignment: WrapAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(S.of(context).curriculum_ratings_overall, style: labelStyle),
            const SizedBox(
              width: 6,
            ),
            Text(
              overallWord[overallLevel],
              style: TextStyle(color: wordColor[overallLevel], fontSize: 12),
            )
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(S.of(context).curriculum_ratings_content, style: labelStyle),
            const SizedBox(
              width: 6,
            ),
            Text(
              contentWord[styleLevel],
              style: TextStyle(color: wordColor[styleLevel], fontSize: 12),
            )
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(S.of(context).curriculum_ratings_workload, style: labelStyle),
            const SizedBox(
              width: 6,
            ),
            Text(
              workloadWord[workloadLevel],
              style: TextStyle(color: wordColor[workloadLevel], fontSize: 12),
            )
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(S.of(context).curriculum_ratings_assessment,
                style: labelStyle),
            const SizedBox(
              width: 6,
            ),
            Text(
              assessmentWord[assessmentLevel],
              style: TextStyle(color: wordColor[assessmentLevel], fontSize: 12),
            )
          ],
        )
      ],
    );
  }
}

class ModifyMenuWidget extends StatefulWidget {
  const ModifyMenuWidget(
      {super.key,
      required this.originalReview,
      required this.courseGroup,
      required this.reviewOperationCallback});
  final CourseReview originalReview;
  final CourseGroup courseGroup;
  final void Function(CourseReview?) reviewOperationCallback;

  @override
  ModifyMenuWidgetState createState() => ModifyMenuWidgetState();
}

class ModifyMenuWidgetState extends State<ModifyMenuWidget> {
  ActionItem? selectedActionItem;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ActionItem>(
      icon: Icon(
        CupertinoIcons.ellipsis_circle,
        color: Theme.of(context).textTheme.bodyLarge!.color,
        size: 16,
      ),
      initialValue: selectedActionItem,
      // Callback that sets the selected popup menu item.
      onSelected: (ActionItem item) async {
        setState(() {
          selectedActionItem = item;
        });
        if (item == ActionItem.Modify) {
          if (await CourseReviewEditor.modifyReply(
              context, widget.courseGroup, widget.originalReview)) {
            if (!context.mounted) return;
            Noticing.showMaterialNotice(context, S.of(context).request_success);
            widget.reviewOperationCallback(widget.originalReview);
          }
        } else if (item == ActionItem.Delete) {
          if (!context.mounted) return;
          if (await Noticing.showConfirmationDialog(
                  context,
                  S
                      .of(context)
                      .about_to_delete_review(widget.originalReview.reviewId!),
                  title: S.of(context).are_you_sure,
                  isConfirmDestructive: true) ==
              true) {
            try {
              await CurriculumBoardRepository.getInstance()
                  .removeReview(widget.originalReview.reviewId!);
              widget.reviewOperationCallback(null);
            } catch (e, st) {
              if (!context.mounted) return;
              Noticing.showErrorDialog(context, e, trace: st);
            }
          }
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<ActionItem>>[
        PopupMenuItem<ActionItem>(
          value: ActionItem.Modify,
          child: OTFloorWidgetBottomBarButton(
            icon: Icon(
              CupertinoIcons.pencil,
              color: Theme.of(context).hintColor,
              size: 12,
            ),
            text: S.of(context).modify,
          ),
        ),
        PopupMenuItem<ActionItem>(
          value: ActionItem.Delete,
          child: OTFloorWidgetBottomBarButton(
            text: S.of(context).delete,
            icon: Icon(
              CupertinoIcons.trash,
              color: Theme.of(context).hintColor,
              size: 12,
            ),
          ),
        ),
      ],
    );
  }
}
