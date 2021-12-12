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

import 'dart:io';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/opentreehole/floor.dart';
import 'package:dan_xi/model/opentreehole/hole.dart';
import 'package:dan_xi/model/opentreehole/message.dart';
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
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class OTLeadingTag extends StatelessWidget {
  final String colorString;
  final String text;

  const OTLeadingTag({Key? key, required this.colorString, this.text = "DZ"})
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
  if (e == null || e.tags == null) return const SizedBox();
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

  /// Whether this widget is called as a result of [mention]
  final bool isInMention;

  final bool showBottomBar;
  final OTHole? parentHole;
  final int? index;
  final void Function()? onTap;
  final void Function()? onLongPress;

  const OTFloorWidget({
    required this.floor,
    this.isInMention = false,
    this.showBottomBar = true,
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
        color: isInMention && PlatformX.isCupertino(context)
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (floor.anonyname ==
                            parentHole?.floors?.first_floor?.anonyname) ...[
                          OTLeadingTag(
                              colorString: isInMention
                                  ? 'grey'
                                  : parentHole?.tags?.first.color ?? 'blue'),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          "${floor.anonyname}",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (floor.deleted == true) ...[
                      const SizedBox(width: 4),
                      OTLeadingTag(
                        colorString: 'red',
                        text: S.of(context).deleted,
                      ),
                    ]
                  ],
                ),
              ),
              Align(
                  alignment: Alignment.topLeft,
                  child: isInMention
                      // If content is being quoted, limit its height so that the view won't be too long.
                      ? Linkify(
                          text: renderText(
                                  floor.filteredContent!,
                                  S.of(context).image_tag,
                                  S.of(context).formula)
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
                          floor.filteredContent ?? S.of(context).fatal_error,
                          onLinkTap,
                          onImageTap)),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "#${floor.hole_id}",
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      Text(
                        "  (##${floor.floor_id})",
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
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
                        "  (##${floor.floor_id})",
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                Text(
                  HumanDuration.tryFormat(
                      context, DateTime.tryParse(floor.time_created ?? "")),
                  style: TextStyle(
                      color: Theme.of(context).hintColor, fontSize: 12),
                ),
              ],
            ),
            if (showBottomBar) OTFloorWidgetBottomBar(floor: floor),
          ]),
          onTap: onTap,
        ),
      ),
    );
  }
}

class OTFloorMentionWidget extends StatelessWidget {
  final Future<OTFloor> future;
  final showBottomBar;

  OTFloorMentionWidget({
    required this.future,
    this.showBottomBar = false,
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
                showBottomBar: false,
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
                          if (pagedListViewController.indexOf(floor) != -1) {
                            // Scroll to the corresponding post
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
            isInMention: true,
            showBottomBar: showBottomBar,
            onTap: () => showFloorDetail(context, snapshot.data!),
          );
        },
        errorBuilder: OTFloorWidget(
          floor: OTFloor.special(
              S.of(context).fatal_error, S.of(context).unable_to_find_quote),
          isInMention: true,
          showBottomBar: showBottomBar,
        ),
        loadingBuilder: OTFloorWidget(
          floor: OTFloor.special(S.of(context).loading, S.of(context).loading),
          isInMention: true,
          showBottomBar: showBottomBar,
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
            if (floor.is_me != true)
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
            if (floor.is_me == true) ...[
              Expanded(
                child: InkWell(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.pencil,
                          color: Theme.of(context).hintColor,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(S.of(context).modify,
                            style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  onTap: () {
                    BBSEditor.modifyReply(
                        context, floor.hole_id, floor.floor_id, floor.content);
                  },
                ),
              ),
              Expanded(
                child: InkWell(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.trash,
                          color: Theme.of(context).hintColor,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(S.of(context).delete,
                            style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  onTap: () async {
                    if (await Noticing.showConfirmationDialog(
                            context,
                            S.of(context).about_to_delete_floor(
                                floor.floor_id ?? "null"),
                            title: S.of(context).are_you_sure,
                            isConfirmDestructive: true) ==
                        true) {
                      try {
                        await OpenTreeHoleRepository.getInstance()
                            .deleteFloor(floor.floor_id!);
                      } catch (e) {
                        Noticing.showNotice(context, e.toString(),
                            title: S.of(context).fatal_error);
                      }
                    }
                  },
                ),
              ),
            ]
          ],
        ),
      ],
    );
  }
}

class OTMessageItem extends StatelessWidget {
  final OTMessage message;

  const OTMessageItem({Key? key, required this.message}) : super(key: key);

  static void dispMessageDetailBasedOnGuessedDataType(
      BuildContext context, String? code, Map<String, dynamic>? data) {
    try {
      switch (code) {
        case 'mention':
        case 'favorite':
        case 'modify':
          // data should be [OTFloor]
          final floor = OTFloor.fromJson(data!);
          if (floor.floor_id == null) return;
          OTFloorMentionWidget.showFloorDetail(context, floor);
          break;
        case 'report':
          //TODO: Unimplemented
          break;
      }
    } catch (ignored) {
      // TODO: Support Other Types
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
          leading: PlatformX.isMaterial(context)
              ? Icon(Icons.developer_board)
              : Icon(CupertinoIcons.info_circle),
          title: Text(message.message ?? "null"),
          subtitle: Text(HumanDuration.tryFormat(
              context, DateTime.tryParse(message.time_created ?? ""))),
          onTap: () => dispMessageDetailBasedOnGuessedDataType(
              context, message.code, message.data)),
    );
  }
}

class OTSearchWidget extends StatelessWidget {
  final FocusNode focusNode;

  const OTSearchWidget({Key? key, required this.focusNode}) : super(key: key);

  _goToPIDResultPage(BuildContext context, int pid) async {
    ProgressFuture progressDialog = showProgressDialog(
        loadingText: S.of(context).loading, context: context);
    try {
      final OTHole post =
          await OpenTreeHoleRepository.getInstance().loadSpecificHole(pid);
      smartNavigatorPush(context, "/bbs/postDetail", arguments: {
        "post": post,
      });
    } catch (error) {
      if (error is DioError &&
          error.response?.statusCode == HttpStatus.notFound)
        Noticing.showNotice(context, S.of(context).post_does_not_exist,
            title: S.of(context).fatal_error);
      else
        Noticing.showNotice(context, error.toString(),
            title: S.of(context).fatal_error);
    }
    progressDialog.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final RegExp pidPattern = new RegExp(r'#[0-9]+');
    return Container(
      padding: Theme.of(context)
          .cardTheme
          .margin, //EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: CupertinoSearchTextField(
        focusNode: focusNode,
        placeholder: S.of(context).search_hint,
        onSubmitted: (value) {
          value = value.trim();
          if (value.isEmpty) return;
          // Determine if user is using #PID pattern to reach a specific post
          if (value.startsWith(pidPattern)) {
            // We needn't deal with the situation that "id = null" here.
            // If so, it will turn into a 404 http error.
            try {
              _goToPIDResultPage(context,
                  int.parse(pidPattern.firstMatch(value)![0]!.substring(1)));
              return;
            } catch (ignored) {}
          }
          smartNavigatorPush(context, "/bbs/postDetail",
              arguments: {"searchKeyword": value});
        },
      ),
    );
  }
}
