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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/opentreehole/floor.dart';
import 'package:dan_xi/model/opentreehole/hole.dart';
import 'package:dan_xi/page/opentreehole/hole_detail.dart';
import 'package:dan_xi/page/subpage_treehole.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/human_duration.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dan_xi/widget/libraries/round_chip.dart';
import 'package:dan_xi/widget/opentreehole/bbs_editor.dart';
import 'package:dan_xi/widget/opentreehole/render/base_render.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class OTLeadingTag extends StatelessWidget {
  final String colorString;
  final String text;

  const OTLeadingTag({Key? key, required this.colorString, this.text = "OP"})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      decoration: BoxDecoration(
          color: Constant.getColorFromString(colorString).withOpacity(0.8),
          borderRadius: BorderRadius.all(Radius.circular(4.0))),
      child: Text(
        text,
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Constant.getColorFromString(colorString)
                        .withOpacity(0.8)
                        .computeLuminance() <=
                    0.5
                ? Colors.white
                : Colors.black,
            fontSize: 12),
      ),
    );
  }
}

/// Turn tags into Widgets
Widget generateTagWidgets(BuildContext context, OTHole? e,
    void Function(String?) onTap, bool useAccessibilityColoring) {
  if (e == null || e.tags == null) return Container();
  List<Widget> _tags = [];
  e.tags!.forEach((element) {
    if (element.name == KEY_NO_TAG) return;
    _tags.add(Flex(
        direction: Axis.horizontal,
        mainAxisSize: MainAxisSize.min,
        children: [
          RoundChip(
            onTap: () => onTap(element.name),
            label: element.name,
            color: useAccessibilityColoring
                ? Theme.of(context).textTheme.bodyText1!.color
                : Constant.getColorFromString(element.color),
          ),
        ]));
  });
  return Wrap(
    direction: Axis.horizontal,
    spacing: 4,
    runSpacing: 4,
    children: _tags,
  );
}

class OTFloorWidget extends StatelessWidget {
  final OTFloor floor;
  final bool isNested;
  final OTHole? parentHole;
  final int? index;
  final void Function()? onTap;
  final void Function()? onLongPress;

  const OTFloorWidget({
    required this.floor,
    this.isNested = false,
    this.index,
    this.onTap,
    this.onLongPress,
    this.parentHole,
  });

  @override
  Widget build(BuildContext context) {
    final bool generateTags = (index == 0);
    final LinkTapCallback onLinkTap = (url) {
      BrowserUtil.openUrl(url!, context);
    };
    final ImageTapCallback onImageTap = (url) {
      smartNavigatorPush(context, '/image/detail', arguments: {'url': url});
    };
    return GestureDetector(
      onLongPress: onLongPress,
      child: Card(
        color: isNested && PlatformX.isCupertino(context)
            ? Theme.of(context).dividerColor.withOpacity(0.05)
            : null,
        child: ListTile(
          dense: true,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (generateTags)
                Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: generateTagWidgets(context, parentHole,
                        (String? tagName) {
                      smartNavigatorPush(context, '/bbs/discussions',
                          arguments: {"tagFilter": tagName});
                    },
                        SettingsProvider.getInstance()
                            .useAccessibilityColoring)),
              Padding(
                padding: EdgeInsets.fromLTRB(2, 4, 2, 4),
                child: Row(
                  children: [
                    if (floor.anonyname ==
                        parentHole?.floors?.first_floor?.anonyname)
                      OTLeadingTag(
                          colorString: parentHole?.tags?.first.color ?? 'blue'),
                    if (floor.anonyname ==
                        parentHole?.floors?.first_floor?.anonyname)
                      const SizedBox(
                        width: 2,
                      ),
                    Text(
                      "${floor.anonyname}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Align(
                  alignment: Alignment.topLeft,
                  child: isNested
                      // If content is being quoted, limit its height so that the view won't be too long.
                      ? Linkify(
                          text: renderText(floor.filteredContent!,
                                  S.of(context).image_tag)
                              .trim(),
                          textScaleFactor: 0.8,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          onOpen: (link) async {
                            if (await canLaunch(link.url)) {
                              BrowserUtil.openUrl(link.url, context);
                            } else {
                              Noticing.showNotice(
                                  context, S.of(context).cannot_launch_url);
                            }
                          })
                      : smartRender(
                          floor.filteredContent!, onLinkTap, onImageTap)),
            ],
          ),
          subtitle: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(
              height: 8,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (index == null)
                  Text(
                    "#${floor.floor_id}",
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                if (index != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${index! + 1}F",
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "  (#${floor.floor_id})",
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                Text(
                  HumanDuration.format(
                      context, DateTime.tryParse(floor.time_created!)),
                  style: TextStyle(
                      color: Theme.of(context).hintColor, fontSize: 12),
                ),
                if (!isNested)
                  GestureDetector(
                    child: Text(S.of(context).modify,
                        style: TextStyle(
                            color: Theme.of(context).hintColor, fontSize: 12)),
                    onTap: () {
                      // TODO: Modify post
                      throw UnimplementedError();
                    },
                  ),
              ],
            ),
            if (!isNested) OTFloorWidgetBottomBar(floor: floor),
          ]),
          onTap: onTap,
        ),
      ),
    );
  }
}

class OTFloorMentionWidget extends StatelessWidget {
  final Future<OTFloor> future;

  OTFloorMentionWidget({
    required this.future,
  });

  static void showFloorDetail(BuildContext context, OTFloor floor) {
    showPlatformModalSheet(
      context: context,
      builder: (BuildContext cxt) => SafeArea(
        child: Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OTFloorWidget(
                floor: floor,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        // Note how this code use [cxt] for some context but [context] for others.
                        // This is to prevent looking up deactivated context after [pop].
                        Navigator.pop(cxt);
                        try {
                          // Find the PagedListViewController
                          final pagedListViewController = context
                              .findAncestorWidgetOfExactType<
                                  PagedListView<OTFloor>>()!
                              .pagedController!;
                          // If this floor is directly in the hole
                          if (pagedListViewController.getIndexOf(floor) != -1) {
                            // Scroll to the corrosponding post
                            while (!(await pagedListViewController
                                .scrollToItem(floor))) {
                              if (pagedListViewController
                                      .getScrollController()!
                                      .offset <
                                  10) break; // Prevent deadlock
                              await pagedListViewController.scrollDelta(-100,
                                  Duration(milliseconds: 1), Curves.linear);
                            }
                            return;
                          }
                        } catch (ignored) {}

                        // If this floor is in another hole
                        ProgressFuture progressDialog = showProgressDialog(
                            loadingText: S.of(context).loading,
                            context: context);
                        try {
                          smartNavigatorPush(context, "/bbs/postDetail",
                              arguments: {
                                "post":
                                    await OpenTreeHoleRepository.getInstance()
                                        .loadSpecificHole(floor.hole_id!),
                                "locate": floor.floor_id!,
                                // TODO: jump to specific floor after push
                              });
                          progressDialog.dismiss();
                        } catch (e) {
                          progressDialog.dismiss();
                          Noticing.showNotice(context, e.toString(),
                              title: S.of(context).fatal_error);
                        }
                      },
                      child: Text(S.of(cxt).jump_to_hole),
                    ),
                    TextButton(
                      child: Text(S.of(cxt).ok),
                      onPressed: () {
                        Navigator.of(cxt).pop();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureWidget(
        future: future,
        successBuilder:
            (BuildContext context, AsyncSnapshot<OTFloor> snapshot) {
          return OTFloorWidget(
            floor: snapshot.data!,
            isNested: true,
            onTap: () => showFloorDetail(context, snapshot.data!),
          );
        },
        errorBuilder: OTFloorWidget(
          floor: OTFloor.special(
              S.of(context).fatal_error, S.of(context).unable_to_find_quote),
          isNested: true,
        ),
        loadingBuilder: OTFloorWidget(
          floor: OTFloor.special(S.of(context).loading, S.of(context).loading),
          isNested: true,
        ));
  }
}

class OTFloorWidgetBottomBar extends StatefulWidget {
  final OTFloor floor;

  const OTFloorWidgetBottomBar({Key? key, required this.floor})
      : super(key: key);

  @override
  _OTFloorWidgetBottomBarState createState() => _OTFloorWidgetBottomBarState();
}

class _OTFloorWidgetBottomBarState extends State<OTFloorWidgetBottomBar> {
  late OTFloor floor;

  @override
  void initState() {
    super.initState();
    floor = widget.floor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: InkWell(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        (floor.liked ?? false)
                            ? CupertinoIcons.heart_fill
                            : CupertinoIcons.heart,
                        color: Theme.of(context).hintColor,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                          (floor.liked ?? false)
                              ? S.of(context).liked(floor.like ?? "...")
                              : S.of(context).like(floor.like ?? "..."),
                          style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 12)),
                    ],
                  ),
                ),
                onTap: () async {
                  try {
                    floor.liked ??= false;
                    setState(() {
                      floor.liked = !floor.liked!;
                    });
                    floor = await OpenTreeHoleRepository.getInstance()
                        .likeFloor(floor.floor_id!, floor.liked!);
                    setState(() {});
                  } catch (e) {
                    Noticing.showNotice(context, e.toString(),
                        title: S.of(context).fatal_error);
                  }
                },
              ),
            ),
            VerticalDivider(width: 0),
            Expanded(
              child: InkWell(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_octagon,
                        color: Theme.of(context).hintColor,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(S.of(context).report,
                          style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 12)),
                    ],
                  ),
                ),
                onTap: () {
                  BBSEditor.reportPost(context, floor.floor_id);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
