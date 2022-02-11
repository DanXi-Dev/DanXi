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
import 'package:dan_xi/model/opentreehole/message.dart';
import 'package:dan_xi/page/opentreehole/hole_detail.dart';
import 'package:dan_xi/page/opentreehole/hole_editor.dart';
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
import 'package:dan_xi/widget/libraries/future_widget.dart';
import 'package:dan_xi/widget/libraries/material_x.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dan_xi/widget/libraries/round_chip.dart';
import 'package:dan_xi/widget/opentreehole/render/base_render.dart';
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
  final ImageTapCallback? onTapImage;

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
    this.onTapImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool generateTags = (index == 0);
    void onLinkTap(String? url) {
      BrowserUtil.openUrl(url!, context);
    }

    void defaultOnImageTap(String? url, Object heroTag) {
      smartNavigatorPush(context, '/image/detail', arguments: {
        'preview_url': url,
        'hd_url': OpenTreeHoleRepository.getInstance()
            .extractHighDefinitionImageUrl(url!),
        'hero_tag': heroTag
      });
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
                      onTapImage ?? defaultOnImageTap,
                      hasBackgroundImage)),
        ],
      ),
      subtitle: Column(mainAxisSize: MainAxisSize.min, children: [
        if ((floor.hole_id ?? 0) > 0 || (floor.floor_id ?? 0) > 0) ...[
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
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                    Text(
                      "  (##${floor.floor_id})",
                      style: TextStyle(
                          color: Theme.of(context).hintColor, fontSize: 10),
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
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "  (##${floor.floor_id})",
                      style: TextStyle(
                          color: Theme.of(context).hintColor, fontSize: 10),
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
        ],
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

class OTMentionPreviewWidget extends StatefulWidget {
  final int id;
  final OTMentionType type;
  final bool showBottomBar;
  final bool hasBackgroundImage;

  const OTMentionPreviewWidget({
    Key? key,
    required this.id,
    required this.type,
    this.showBottomBar = false,
    required this.hasBackgroundImage,
  }) : super(key: key);

  @override
  _OTMentionPreviewWidgetState createState() => _OTMentionPreviewWidgetState();
}

class _OTMentionPreviewWidgetState extends State<OTMentionPreviewWidget> {
  bool isShowingPreview = false;

  @override
  void didUpdateWidget(OTMentionPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    isShowingPreview = false;
  }

  @override
  Widget build(BuildContext context) {
    if (isShowingPreview) {
      return OTFloorMentionWidget(
        future: widget.type == OTMentionType.FLOOR
            ? OpenTreeHoleRepository.getInstance().loadSpecificFloor(widget.id)
            : OpenTreeHoleRepository.getInstance()
                .loadSpecificHole(widget.id)
                .then((value) => value?.floors?.first_floor),
        hasBackgroundImage: widget.hasBackgroundImage,
        showBottomBar: widget.showBottomBar,
      );
    } else {
      return OTFloorWidget(
        hasBackgroundImage: widget.hasBackgroundImage,
        floor: OTFloor.special(
            S.of(context).quote, S.of(context).tap_to_show_preview),
        isInMention: true,
        showBottomBar: widget.showBottomBar,
        onTap: () => setState(() => isShowingPreview = true),
      );
    }
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
          builder: (BuildContext cxt) {
            final maxHeightRatio = PlatformX.isMaterial(context) ? 0.3 : 0.85;
            final Widget cardBody = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: ViewportUtils.getViewportHeight(context) *
                          maxHeightRatio),
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
                                    Constant.POST_COUNT_PER_PAGE) {
                                  break;
                                } // Prevent deadlock
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
                            OTHole? hole =
                                await OpenTreeHoleRepository.getInstance()
                                    .loadSpecificHole(floor.hole_id!);

                            smartNavigatorPush(context, "/bbs/postDetail",
                                arguments: {
                                  "post": await prefetchAllFloors(hole!),
                                  "locate": floor,
                                });
                          } catch (e, st) {
                            Noticing.showModalError(context, e, trace: st);
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
            );
            if (PlatformX.isCupertino(context)) {
              return SafeArea(
                child: Card(
                  child: cardBody,
                ),
              );
            } else {
              return SafeArea(child: cardBody);
            }
          });

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
                  } catch (e, st) {
                    Noticing.showModalError(context, e, trace: st);
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
                  onTap: () async {
                    if (await OTEditor.reportPost(context, floor.floor_id)) {
                      Noticing.showMaterialNotice(
                          context, S.of(context).report_success);
                    }
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
                  onTap: () async {
                    if (await OTEditor.modifyReply(context, floor.hole_id,
                        floor.floor_id, floor.content)) {
                      Noticing.showMaterialNotice(
                          context, S.of(context).request_success);
                    }
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
                      } catch (e, st) {
                        Noticing.showModalError(context, e, trace: st);
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

enum OTMentionType { FLOOR, HOLE }
