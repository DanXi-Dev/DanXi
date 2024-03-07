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
import 'package:dan_xi/repository/danke/curriculum_board_repository.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:flutter/material.dart';

// widget for voting on a review

class ReviewVoteWidget extends StatefulWidget {
  const ReviewVoteWidget(
      {super.key,
      required this.myVote,
      required this.reviewVote,
      required this.reviewId});

  final int reviewVote;
  final int myVote;
  final int reviewId;

  @override
  // pass reviewTotalVote to _ReviewVoteWidgetState
  _ReviewVoteWidgetState createState() => _ReviewVoteWidgetState();
}

class _ReviewVoteWidgetState extends State<ReviewVoteWidget> {
  // HydrogenC: Why is this field called remark on the server?
  late int _reviewVote;

  late int _myVote;
  late int _reviewId;

  @override
  void initState() {
    super.initState();
    _reviewVote = widget.reviewVote;
    _myVote = widget.myVote;
    _reviewId = widget.reviewId;
  }

  Future<void> vote(bool upVote) async {
    var newReview = await CurriculumBoardRepository.getInstance()
        .voteReview(_reviewId, upVote);
    setState(() {
      _reviewVote = newReview.remark!;
      _myVote = newReview.vote!;
    });
  }

  void errorHandler(dynamic error, stackTrace) {
    Noticing.showNotice(context, error.toString(),
        title: S.of(context).operation_failed, useSnackBar: false);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            iconSize: 20,
            splashRadius: 16,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            alignment: Alignment.bottomCenter,
            icon: Icon(
              Icons.keyboard_arrow_up,
              color: _myVote > 0
                  ? Colors.blue
                  : Theme.of(context).textTheme.bodyLarge!.color,
            ),
            onPressed: () {
              if (_myVote < 0) {
                // If already downvoted, then cancel the downvote
                vote(false).onError(errorHandler);
              } else {
                vote(true).onError(errorHandler);
              }
            },
          ),
          Text(
            _reviewVote.toString(),
            style: const TextStyle(fontSize: 20),
          ),
          IconButton(
            iconSize: 20,
            splashRadius: 16,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            alignment: Alignment.topCenter,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: _myVote < 0
                  // set its color
                  ? Colors.red
                  : Theme.of(context).textTheme.bodyLarge!.color,
            ),
            onPressed: () {
              // HydrogenC: Why prevent user from modifying his/her vote?
              // if (_myVote != 0) return;
              if (_myVote > 0) {
                // If already upvoted, then cancel the upvote
                vote(true).onError(errorHandler);
              } else {
                vote(false).onError(errorHandler);
              }
            },
          ),
        ],
      ),
    );
  }
}
