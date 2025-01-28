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
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/widget/libraries/chip_widgets.dart';
import 'package:flutter/material.dart';

const List<Color> wordColor = [
  Colors.red,
  Colors.orange,
  Colors.yellow,
  Colors.lightGreen,
  Colors.green
];

class CourseGroupCardWidget extends StatelessWidget {
  // changeable style of the card
  final bool translucent;
  final CourseGroup courseGroup;

  const CourseGroupCardWidget(
      {super.key, required this.courseGroup, this.translucent = false});

  @override
  Widget build(BuildContext context) {
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
          contentPadding: const EdgeInsets.fromLTRB(16, 3, 13, 2),
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
                              // todo add course information style
                              Text(
                                courseGroup.getFullName(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                softWrap: true,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                courseGroup.code!,
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        // credits tag group
                        Wrap(
                          direction: Axis.vertical,
                          alignment: WrapAlignment.start,
                          spacing: 5,
                          // for each credit in credits create a text
                          children: <Widget>[
                            ...courseGroup.credits!.map((e) => LeadingChip(
                                  color: Colors.orange,
                                  label:
                                      "${e.toStringAsFixed(1)} ${S.of(context).credits}",
                                )),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ]),
          onTap: () => smartNavigatorPush(context, "/danke/courseDetail",
              arguments: {"group_id": courseGroup.id}),
        ),
        const Divider(
          height: 5,
          thickness: 1,
        ),
        // rating and comment count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 3, 13, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                children: [
                  Icon(Icons.file_copy,
                      size: infoStyle.fontSize, color: infoStyle.color),
                  const SizedBox(
                    width: 3,
                  ),
                  Text(
                    // TODO: waiting for upstream support
                    "${courseGroup.courseCount}",
                    style: infoStyle,
                  )
                ],
              ),
              Row(
                children: [
                  Icon(
                      // fixme PlatformX.isMaterial(context) forum_widgets.dart: 234
                      Icons.comment,
                      size: infoStyle.fontSize,
                      color: infoStyle.color),
                  const SizedBox(
                    width: 3,
                  ),
                  Text(
                    "${courseGroup.reviewCount}",
                    style: infoStyle,
                  )
                ],
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class FilterTagWidget extends StatelessWidget {
  final Color color;
  final String text;
  final void Function() onTap;

  const FilterTagWidget(
      {super.key,
      required this.color,
      required this.text,
      required this.onTap});

  @override
  Widget build(BuildContext context) => RoundChip(
        onTap: onTap,
        label: text,
        color: color,
      );
}

class FilterTag<T> {
  FilterTag(this.displayName, this.filter);

  String displayName;
  T filter;
}

class FilterListWidget<T> extends StatefulWidget {
  const FilterListWidget(
      {super.key,
      required this.filters,
      required this.onTap,
      required this.defaultIndex});

  @override
  FilterListWidgetState<T> createState() => FilterListWidgetState<T>();

  final void Function(T) onTap;
  final List<FilterTag<T>> filters;
  final int defaultIndex;
}

class FilterListWidgetState<T> extends State<FilterListWidget<T>> {
  FilterTag<T>? selectedTag;

  @override
  void initState() {
    super.initState();
    selectedTag = widget.filters[widget.defaultIndex];
  }

  @override
  void didUpdateWidget(covariant FilterListWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    selectedTag = widget.filters[widget.defaultIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 3, runSpacing: 2, children: [
      ...widget.filters.map(
        (e) => FilterTagWidget(
            color: e.filter == selectedTag!.filter
                ? Colors.pinkAccent
                : Colors.grey,
            text: e.displayName,
            onTap: () {
              setState(() {
                selectedTag = e;
                widget.onTap(e.filter);
              });
            }),
      )
    ]);
  }
}
