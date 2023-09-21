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
import 'package:dan_xi/model/danke/course.dart';
import 'package:dan_xi/page/danke/course_group_detail.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/opentreehole/human_duration.dart';
import 'package:dan_xi/util/opentreehole/paged_listview_helper.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/viewport_utils.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/linkify_x.dart';
import 'package:dan_xi/widget/libraries/material_x.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dan_xi/widget/libraries/round_chip.dart';
import 'package:dan_xi/widget/opentreehole/render/base_render.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:nil/nil.dart';
import 'package:provider/provider.dart';

import '../../model/danke/course_group.dart';
import '../opentreehole/treehole_widgets.dart';

Color? getDefaultCardBackgroundColor(
        BuildContext context, bool hasBackgroundImage) =>
    hasBackgroundImage
        ? Theme.of(context).cardTheme.color?.withOpacity(0.8)
        : null;

int translateScore(int score) {
  if (score < 20) {
    return 0;
  } else if (score < 40) {
    return 1;
  } else if (score < 60) {
    return 2;
  } else if (score < 80) {
    return 3;
  } else {
    return 4;
  }
}

const List<String> overallWord = ["特别差评", "差评", "中等", "好评", "特别好评"];
const List<String> styleWord = ["硬核", "较难", "中等", "容易", "非常容易"];
const List<String> workloadWord = ["非常大", "较大", "中等", "较小", "非常小"];
const List<String> assessmentWord = ["非常严格", "严格", "中等", "宽松", "非常宽松"];
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
  final CourseGroup courses;

  CourseGroupCardWidget(
      {Key? key, required this.courses, this.translucent = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // style of the card
    final TextStyle infoStyle =
        TextStyle(color: Theme.of(context).hintColor, fontSize: 12);

    return Card(
      color: translucent
          ? Theme.of(context).cardTheme.color?.withOpacity(0.8)
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
                                courses.getFullName(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                softWrap: true,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                courses.code!,
                                textAlign: TextAlign.left,
                                style: const TextStyle(fontSize: 12),
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
                            OTLeadingTag(
                              color: Colors.orange,
                              text: "${courses.credit!.toStringAsFixed(1)} 学分",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ]),
          onTap: () => smartNavigatorPush(context, "/danke/courseDetail",
              arguments: {"group": courses}),
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
              Text(
                // fixme add backend support instead of hardcoding
                "3",
                style: infoStyle,
              ),
              Row(
                children: [
                  Icon(
                      // fixme PlatformX.isMaterial(context) treehole_widgets.dart: 234
                      CupertinoIcons.ellipses_bubble,
                      size: infoStyle.fontSize,
                      color: infoStyle.color),
                  const SizedBox(
                    width: 3,
                  ),
                  Text(
                    courses.getTotalReviewCount().toString(),
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
      {Key? key, required this.color, required this.text, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) => Flex(
          direction: Axis.horizontal,
          mainAxisSize: MainAxisSize.min,
          children: [
            RoundChip(
              onTap: onTap,
              label: text,
              color: color,
            ),
          ]);
}

class FilterTag<T> {
  FilterTag(this.displayName, this.filter);

  String displayName;
  T filter;
}

class FilterListWidget<T> extends StatefulWidget {
  FilterListWidget(
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
  Widget build(BuildContext context) {
    return Wrap(spacing: 4, runSpacing: 4, children: [
      ...widget.filters.map(
        (e) => FilterTagWidget(
            color: e.filter == selectedTag!.filter
                ? Colors.pinkAccent
                : Colors.white70,
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
