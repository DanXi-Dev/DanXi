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

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// widget for voting on a review

class ReviewVoteWidget extends StatefulWidget {
  const ReviewVoteWidget(
      {Key? key, required this.reviewVote, required this.reviewTotalVote})
      : super(key: key);

  final int reviewTotalVote;
  final int reviewVote;

  @override
  // pass reviewTotalVote to _ReviewVoteWidgetState
  _ReviewVoteWidgetState createState() => _ReviewVoteWidgetState();
}

class _ReviewVoteWidgetState extends State<ReviewVoteWidget> {
  late int _reviewTotalVote;
  late int _reviewVote;

  @override
  void initState() {
    super.initState();
    _reviewTotalVote = widget.reviewTotalVote;
    _reviewVote = widget.reviewVote;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 12,
            padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
            alignment: Alignment.centerRight,
            icon: Icon(
              _reviewVote > 0 ? Icons.thumb_up : Icons.thumb_up_outlined,
              color: _reviewVote > 0
                  ? Colors.blue
                  : Theme.of(context).textTheme.bodyText1!.color,
            ),
            onPressed: () {
              if (_reviewVote != 0) return;
              setState(() {
                // todo http request
                _reviewTotalVote += 1;
                _reviewVote = 1;
              });
            },
          ),
          Text(
            _reviewTotalVote.toString(),
            style: const TextStyle(fontSize: 12),
          ),
          IconButton(
            iconSize: 12,
            padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
            alignment: Alignment.centerLeft,
            icon: Icon(
              _reviewVote < 0
                  ? Icons.thumb_down
                  : Icons.thumb_down_outlined,
              color: _reviewVote < 0
                  // set its color
                  ? Colors.red
                  : Theme.of(context).textTheme.bodyText1!.color,
            ),
            onPressed: () {
              if (_reviewVote != 0) return;
              setState(() {
                // todo http request
                _reviewTotalVote -= 1;
                _reviewVote = -1;
              });
            },
          ),
        ],
      ),
    );
  }
}
