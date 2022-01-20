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
import 'dart:ui';

import 'package:dan_xi/generated/l10n.dart';
import 'package:dan_xi/model/opentreehole/floor.dart';
import 'package:dan_xi/model/opentreehole/hole.dart';
import 'package:dan_xi/model/opentreehole/message.dart';
import 'package:dan_xi/page/opentreehole/hole_detail.dart';
import 'package:dan_xi/page/subpage_treehole.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/master_detail_view.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/opentreehole/human_duration.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/viewport_utils.dart';
import 'package:dan_xi/widget/libraries/error_page_widget.dart';
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/material_x.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dan_xi/widget/libraries/round_chip.dart';
import 'package:dan_xi/page/opentreehole/hole_editor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_progress_dialog/flutter_progress_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

Color? getDefaultCardBackgroundColor(
        BuildContext context, bool hasBackgroundImage) =>
    hasBackgroundImage
        ? Theme.of(context).cardTheme.color?.withOpacity(0.8)
        : null;

class OTLeadingTag extends StatelessWidget {
  final Color color;
  final String text;

  const OTLeadingTag({Key? key, required this.color, this.text = "DZ"})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      //height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: const BorderRadius.all(Radius.circular(2.0))),
      child: Text(
        text,
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color.withOpacity(0.8).computeLuminance() <= 0.5
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
  for (var element in e.tags!) {
    if (element.name == KEY_NO_TAG) continue;
    _tags.add(Flex(
        direction: Axis.horizontal,
        mainAxisSize: MainAxisSize.min,
        children: [
          RoundChip(
            onTap: () => onTap(element.name),
            label: element.name,
            color: useAccessibilityColoring
                ? Theme.of(context).textTheme.bodyText1!.color
                : element.color,
          ),
        ]));
  }
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
  final bool hasBackgroundImage;
  final bool showBottomBar;
  final OTHole? parentHole;
  final int? index;
  final void Function()? onTap;
  final void Function()? onLongPress;

  const OTFloorWidget({
    Key? key,
    required this.floor,
    this.isInMention = false,
    this.showBottomBar = true,
    this.index,
    this.onTap,
    this.onLongPress,
    this.parentHole,
    required this.hasBackgroundImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool generateTags = (index == 0);
    onLinkTap(url) {
      BrowserUtil.openUrl(url!, context);
    }

    onImageTap(url) {
      smartNavigatorPush(context, '/image/detail', arguments: {'url': url});
    }

    final nameColor = floor.anonyname?.hashColor() ?? Colors.red;

    final cardChild = ListTile(
      dense: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (generateTags)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child:
                    generateTagWidgets(context, parentHole, (String? tagName) {
                  smartNavigatorPush(context, '/bbs/discussions',
                      arguments: {"tagFilter": tagName},
                      forcePushOnMainNavigator: true);
                }, SettingsProvider.getInstance().useAccessibilityColoring)),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ColoredBox(
                        color: nameColor,
                        child: const SizedBox(width: 2, height: 12)),
                    const SizedBox(
                      width: 8,
                    ),
                    if (floor.anonyname ==
                        parentHole?.floors?.first_floor?.anonyname) ...[
                      OTLeadingTag(color: nameColor),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      "${floor.anonyname}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: nameColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (floor.deleted == true) ...[
                      const SizedBox(width: 4),
                      OTLeadingTag(
                        color: Theme.of(context).colorScheme.primary,
                        text: S.of(context).deleted,
                      ),
                    ],
                    if (floor.history?.isNotEmpty == true) ...[
                      const SizedBox(width: 4),
                      OTLeadingTag(
                        color: Theme.of(context).colorScheme.primary,
                        text: S.of(context).modified,
                      ),
                    ],
                    if (floor.special_tag?.isNotEmpty == true) ...[
                      const SizedBox(width: 4),
                      OTLeadingTag(
                        color: Colors.red,
                        text: floor.special_tag!,
                      ),
                    ]
                  ],
                )
              ],
            ),
          ),
          Align(
              alignment: Alignment.topLeft,
              child: isInMention
                  // If content is being quoted, limit its height so that the view won't be too long.
                  ? Linkify(
                      text: renderText(floor.filteredContent!,
                              S.of(context).image_tag, S.of(context).formula)
                          .trim(),
                      textScaleFactor: 0.8,
                      maxLines: 3,
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
                      context,
                      floor.filteredContent ?? S.of(context).fatal_error,
                      onLinkTap,
                      onImageTap,
                      hasBackgroundImage)),
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
              style:
                  TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
            ),
          ],
        ),
        if (showBottomBar) OTFloorWidgetBottomBar(floor: floor),
      ]),
      onTap: onTap,
    );

    return GestureDetector(
      onLongPress: onLongPress,
      child: Card(
        color: isInMention && PlatformX.isCupertino(context)
            ? Theme.of(context).dividerColor.withOpacity(0.05)
            : getDefaultCardBackgroundColor(context, hasBackgroundImage),
        child: (floor.deleted == true || floor.fold?.isNotEmpty == true)
            ? ExpansionTileX(
                title: Text(
                  floor.deleteReason ??
                      floor.foldReason ??
                      "_error_incomplete_data_",
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
                children: [cardChild],
              )
            : cardChild,
      ),
    );
  }
}

class OTFloorMentionWidget extends StatelessWidget {
  final Future<OTFloor?> future;
  final bool showBottomBar;
  final bool hasBackgroundImage;

  const OTFloorMentionWidget({
    Key? key,
    required this.future,
    this.showBottomBar = false,
    required this.hasBackgroundImage,
  }) : super(key: key);

  static Future<bool?> showFloorDetail(BuildContext context, OTFloor floor) =>
      showPlatformModalSheet<bool?>(
        context: context,
        builder: (BuildContext cxt) => SafeArea(
          child: Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: ViewportUtils.getViewportHeight(context) / 2),
                  child: SingleChildScrollView(
                    primary: false,
                    child: OTFloorWidget(
                      hasBackgroundImage: false,
                      floor: floor,
                      showBottomBar: false,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                await pagedListViewController.scrollDelta(
                                    -100,
                                    const Duration(milliseconds: 1),
                                    Curves.linear);
                              }
                              return;
                            }
                          } catch (_) {}

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
                                  "locate": floor,
                                });
                          } catch (e) {
                            Noticing.showNotice(
                                context,
                                ErrorPageWidget.generateUserFriendlyDescription(
                                    S.of(context), e),
                                title: S.of(context).fatal_error,
                                useSnackBar: false);
                          } finally {
                            progressDialog.dismiss(showAnim: false);
                          }
                        },
                        child: Text(S.of(cxt).jump_to_hole),
                      ),
                      TextButton(
                        child: Text(S.of(cxt).ok),
                        onPressed: () {
                          Navigator.of(cxt).pop(true);
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

  @override
  Widget build(BuildContext context) {
    return FutureWidget<OTFloor?>(
        future: future,
        successBuilder:
            (BuildContext context, AsyncSnapshot<OTFloor?> snapshot) {
          return OTFloorWidget(
            hasBackgroundImage: hasBackgroundImage,
            floor: snapshot.data!,
            isInMention: true,
            showBottomBar: showBottomBar,
            onTap: () => showFloorDetail(context, snapshot.data!),
          );
        },
        errorBuilder: OTFloorWidget(
          hasBackgroundImage: hasBackgroundImage,
          floor: OTFloor.special(
              S.of(context).fatal_error, S.of(context).unable_to_find_quote),
          isInMention: true,
          showBottomBar: showBottomBar,
        ),
        loadingBuilder: OTFloorWidget(
          hasBackgroundImage: hasBackgroundImage,
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
  void didUpdateWidget(OTFloorWidgetBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    floor = widget.floor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: InkWell(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
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
                    floor = (await OpenTreeHoleRepository.getInstance()
                        .likeFloor(floor.floor_id!, floor.liked!))!;
                    setState(() {});
                  } catch (e) {
                    Noticing.showNotice(
                        context,
                        ErrorPageWidget.generateUserFriendlyDescription(
                            S.of(context), e),
                        title: S.of(context).fatal_error,
                        useSnackBar: false);
                  }
                },
              ),
            ),
            if (floor.is_me != true)
              Expanded(
                child: InkWell(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
                    OTEditor.reportPost(context, floor.floor_id);
                  },
                ),
              ),
            if (floor.is_me == true && floor.deleted == false) ...[
              Expanded(
                child: InkWell(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
                    OTEditor.modifyReply(
                        context, floor.hole_id, floor.floor_id, floor.content);
                  },
                ),
              ),
              Expanded(
                child: InkWell(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
                        Noticing.showNotice(
                            context,
                            ErrorPageWidget.generateUserFriendlyDescription(
                                S.of(context), e),
                            title: S.of(context).fatal_error,
                            useSnackBar: false);
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

class OTMessageItem extends StatefulWidget {
  final OTMessage message;

  const OTMessageItem({Key? key, required this.message}) : super(key: key);

  static Future<void> markMessageAsRead(OTMessage message) async {
    if (message.has_read == true) return;
    message.has_read = true;
    await OpenTreeHoleRepository.getInstance().modifyMessage(message);
  }

  static void dispMessageDetailBasedOnGuessedDataType(
      BuildContext context, String? code, Map<String, dynamic>? data,
      [int? id]) async {
    try {
      switch (code) {
        case 'mention':
        case 'favorite':
        case 'modify':
          // data should be [OTFloor]
          final floor = OTFloor.fromJson(data!);
          if (floor.floor_id == null) return;
          if (await OTFloorMentionWidget.showFloorDetail(context, floor) ==
                  true &&
              id != null) {
            markMessageAsRead(OTMessage(id, null, null, null, true, null));
          }
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
  _OTMessageItemState createState() => _OTMessageItemState();
}

class _OTMessageItemState extends State<OTMessageItem> {
  late OTMessage message;

  @override
  void initState() {
    super.initState();
    message = widget.message;
  }

  @override
  void didUpdateWidget(OTMessageItem oldWidget) {
    message = widget.message;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
          leading: PlatformX.isMaterial(context)
              ? const Icon(Icons.developer_board)
              : const Icon(CupertinoIcons.info_circle),
          title: Text(message.message ?? "null",
              style: (message.has_read == true)
                  ? TextStyle(color: Theme.of(context).hintColor)
                  : null),
          subtitle: Text(HumanDuration.tryFormat(
              context, DateTime.tryParse(message.time_created ?? ""))),
          onTap: () async {
            OTMessageItem.markMessageAsRead(message)
                .then((value) => setState(() {}));
            OTMessageItem.dispMessageDetailBasedOnGuessedDataType(
                context, message.code, message.data, message.message_id);
          }),
    );
  }
}
