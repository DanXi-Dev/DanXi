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

class RandomReviewWidgets extends StatelessWidget {
  // changeable style of the card
  final bool translucent;

  final String departmentName;
  final String courseName;

  // review information
  final String userId;
  final String reviewContent;

  const RandomReviewWidgets(
      {Key? key,
      this.departmentName = "未知院系",
      this.courseName = "未知课程",
      this.userId = "未知用户",
      this.reviewContent = "未知评论",
      this.translucent = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: buildCard(context));
    throw UnimplementedError();
  }

  buildCard(BuildContext context) {
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
          contentPadding: const EdgeInsets.fromLTRB(0, 3, 0, 2),
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
                                padding: const EdgeInsets.only(left: 10),
                                child: Text(
                                  "$departmentName / $courseName",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  softWrap: true,
                                ),
                              ),
                              const Divider(),
                              ListTile(
                                  dense: true,
                                  minLeadingWidth: 16,
                                  leading: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 0, 5, 0),
                                    child: Icon(
                                      PlatformX.isMaterial(context)
                                          ? Icons.sms_outlined
                                          : CupertinoIcons.quote_bubble,
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                  title: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                              // fixme PlatformX.isMaterial(context) treehole_widgets.dart: 234
                                              CupertinoIcons.person,
                                              size: infoStyle.fontSize,
                                              color: infoStyle.color),
                                          Text(
                                            userId,
                                            textAlign: TextAlign.left,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        reviewContent,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ))
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ]),
        ),
        // rating and comment count
      ]),
    );
  }
}
