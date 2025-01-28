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
import 'package:dan_xi/model/danke/course_review.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/chip_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RandomReviewWidgets extends StatelessWidget {
  // changeable style of the card
  final bool translucent;
  final void Function()? onTap;

  final CourseReview review;

  const RandomReviewWidgets(
      {super.key, required this.review, this.translucent = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: _buildCard(context));
  }

  _buildCard(BuildContext context) {
    // style of the card
    final TextStyle infoStyle =
        TextStyle(color: Theme.of(context).hintColor, fontSize: 12);

    return Card(
      color: translucent
          ? Theme.of(context).cardTheme.color?.withValues(alpha: 0.8)
          : null,
      // credits group
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
            contentPadding: const EdgeInsets.fromLTRB(0, 3, 0, 2),
            onTap: onTap ?? () {},
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(review.course!.code!,
                          style: const TextStyle(color: Colors.grey))),
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        "${review.course?.department} / ${review.course?.name}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        softWrap: true,
                      )),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          LeadingChip(
                            color: Colors.orange,
                            label:
                                "${review.course!.credit!.toStringAsFixed(1)} ${S.of(context).credits}",
                          ),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Icon(
                                Icons.thumb_up_outlined,
                                size: infoStyle.fontSize,
                                color: infoStyle.color,
                              ),
                              const SizedBox(
                                width: 3,
                              ),
                              Text(
                                "${review.remark}",
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      )),
                  ListTile(
                      dense: true,
                      minLeadingWidth: 16,
                      leading: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                        child: Icon(
                          PlatformX.isMaterial(context)
                              ? Icons.sms_outlined
                              : CupertinoIcons.quote_bubble,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      title: Column(
                        children: [
                          const SizedBox(height: 5),
                          Text(
                            review.content!,
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ))
                ],
              ),
            )),
        // rating and comment count
      ]),
    );
  }
}
