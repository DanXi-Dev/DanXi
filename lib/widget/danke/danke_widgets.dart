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
import 'package:dan_xi/model/opentreehole/floor.dart';
import 'package:dan_xi/model/opentreehole/hole.dart';
import 'package:dan_xi/model/opentreehole/message.dart';
import 'package:dan_xi/model/opentreehole/report.dart';
import 'package:dan_xi/page/opentreehole/hole_detail.dart';
import 'package:dan_xi/page/opentreehole/hole_editor.dart';
import 'package:dan_xi/page/subpage_treehole.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
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

import '../opentreehole/treehole_widgets.dart';

Color? getDefaultCardBackgroundColor(
        BuildContext context, bool hasBackgroundImage) =>
    hasBackgroundImage
        ? Theme.of(context).cardTheme.color?.withOpacity(0.8)
        : null;

String totalRatingCalc(double score) {
  String rating = "暂无评分";
  if (score >= 90) {
    rating = "优秀";
  } else if (score >= 80) {
    rating = "良好";
  } else if (score >= 70) {
    rating = "中等";
  } else if (score >= 60) {
    rating = "及格";
  } else if (score >= 0) {
    rating = "不及格";
  }
  return rating;
}

class CourseCard extends StatelessWidget {
  final String apartmentName;
  final String courseName;

  // list of numbers of credits
  final List<int> credits;
  final String courseCode;
  final double courseScore;

  const CourseCard(
      {Key? key,
      this.apartmentName = "未知院系",
      this.courseName = "未知课程",
      required this.credits,
      required this.courseCode,
      this.courseScore = -1.0})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      // TODO card的整体高度
      // TODO info style
      child: Card(
        // credits group
        child: Column(children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 5, 16, 0),
            title: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 4,
                children: [
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$apartmentName / $courseName",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                courseCode,
                                textAlign: TextAlign.left,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          // credits group
                          Wrap(
                            // TODO 学分tag之间水平间距
                            direction: Axis.vertical,
                            alignment: WrapAlignment.start,
                            spacing: 5,
                            // for each credit in credits create a text
                            children: <Widget>[
                              ...credits.map((credit) => OTLeadingTag(
                                color: Colors.orange,
                                text: "$credit 学分",
                              )),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        // TODO 用图标
                        children: const [Text("评分数：3", style: TextStyle(fontSize: 12),)],
                      )
                    ],
                  ),
                  const Divider(
                    height: 5,
                    thickness: 1,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("评分: ${totalRatingCalc(courseScore)}", style: const TextStyle(
                        fontSize: 12
                      ),),
                    ],
                  ),
                ]),
          )
        ]),
      ),
    );
    throw UnimplementedError();
  }
}
