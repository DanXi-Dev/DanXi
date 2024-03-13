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

/// The ellipsis char. From packages/flutter/lib/src/rendering/paragraph.dart.
const String _kEllipsis = '\u2026';

Color? getDefaultCardBackgroundColor(
        BuildContext context, bool hasBackgroundImage) =>
    hasBackgroundImage
        ? Theme.of(context).cardTheme.color?.withOpacity(0.8)
        : null;

enum ActionItem { Modify, Delete, Report }

void launchUrlWithNotice(BuildContext context, LinkableElement link) async {
  try {
    await BrowserUtil.openUrl(link.url, context);
  } catch (_) {
    if (context.mounted) {
      Noticing.showNotice(context, S.of(context).cannot_launch_url);
    }
  }
}

class OTLeadingTag extends StatelessWidget {
  final Color color;
  final String text;

  const OTLeadingTag({super.key, required this.color, this.text = "DZ"});

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
  if (e == null || e.tags == null) return nil;
  List<Widget> tags = [];
  for (var element in e.tags!) {
    if (element.name == KEY_NO_TAG) continue;
    tags.add(RoundChip(
      onTap: () => onTap(element.name),
      label: Constant.withZwb(element.name),
      color: useAccessibilityColoring
          ? Theme.of(context).textTheme.bodyLarge!.color
          : element.color,
    ));
  }
  return Wrap(
    direction: Axis.horizontal,
    spacing: 4,
    runSpacing: 4,
    children: tags,
  );
}

class OTHoleWidget extends StatelessWidget {
  final OTHole postElement;
  final bool translucent;
  final bool isPinned;
  final bool isFolded;

  const OTHoleWidget(
      {super.key,
      required this.postElement,
      this.translucent = false,
      this.isPinned = false,
      this.isFolded = false});

  @override
  Widget build(BuildContext context) {
    Linkify postContentWidget = LinkifyX(
      text: renderText(
          // if the floor has been folded, do not show the content directly!
          postElement.floors!.first_floor!.foldReason ??
              postElement.floors!.first_floor!.filteredContent!,
          S.of(context).image_tag,
          S.of(context).formula),
      style: const TextStyle(fontSize: 16),
      maxLines: 6,
      overflow: TextOverflow.ellipsis,
      onOpen: (link) => launchUrlWithNotice(context, link),
    );
    final TextStyle infoStyle =
        TextStyle(color: Theme.of(context).hintColor, fontSize: 12);

    return Card(
      color: translucent
          ? Theme.of(context).cardTheme.color?.withOpacity(0.8)
          : null,
      child: Column(
        children: [
          ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 4, 10, 0),
              dense: false,
              title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.spaceBetween,
                        runSpacing: 4,
                        children: [
                          generateTagWidgets(context, postElement,
                              (String? tagName) {
                            smartNavigatorPush(context, '/bbs/discussions',
                                arguments: {"tagFilter": tagName},
                                forcePushOnMainNavigator: true);
                          },
                              context
                                  .read<SettingsProvider>()
                                  .useAccessibilityColoring),
                          Row(
                            //mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isPinned)
                                OTLeadingTag(
                                  color: Theme.of(context).colorScheme.primary,
                                  text: S.of(context).pinned,
                                ),
                              if (postElement.floors?.first_floor?.special_tag
                                      ?.isNotEmpty ==
                                  true) ...[
                                const SizedBox(width: 4),
                                OTLeadingTag(
                                  color: Colors.red,
                                  text: postElement
                                      .floors!.first_floor!.special_tag!,
                                ),
                              ],
                              if (postElement.hidden == true) ...[
                                const SizedBox(width: 4),
                                OTLeadingTag(
                                  color: Theme.of(context).colorScheme.primary,
                                  text: S.of(context).hole_hidden,
                                ),
                              ],
                              if (postElement.locked == true) ...[
                                const SizedBox(width: 4),
                                OTLeadingTag(
                                  color: Theme.of(context).colorScheme.primary,
                                  text: S.of(context).hole_locked,
                                )
                              ]
                            ],
                          ),
                        ]),
                    const SizedBox(height: 4),
                    isFolded
                        ? ExpansionTileX(
                            expandedCrossAxisAlignment:
                                CrossAxisAlignment.start,
                            expandedAlignment: Alignment.topLeft,
                            childrenPadding:
                                const EdgeInsets.symmetric(vertical: 4),
                            tilePadding: EdgeInsets.zero,
                            title: Text(S.of(context).folded, style: infoStyle),
                            children: [postContentWidget])
                        : postContentWidget,
                  ]),
              subtitle:
                  Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                const SizedBox(height: 12),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("#${postElement.hole_id}", style: infoStyle),
                      Text(
                          HumanDuration.tryFormat(
                              context,
                              DateTime.parse(postElement.time_created!)
                                  .toLocal()),
                          style: infoStyle),
                      Row(children: [
                        Text("${postElement.reply} ", style: infoStyle),
                        Icon(
                            PlatformX.isMaterial(context)
                                ? Icons.sms_outlined
                                : CupertinoIcons.ellipses_bubble,
                            size: infoStyle.fontSize,
                            color: infoStyle.color),
                      ]),
                    ]),
              ]),
              onTap: () => smartNavigatorPush(context, "/bbs/postDetail",
                  arguments: {"post": postElement})),
          if (!isFolded &&
              postElement.floors?.last_floor !=
                  postElement.floors?.first_floor) ...[
            const Divider(height: 4),
            _buildCommentView(context, postElement)
          ]
        ],
      ),
    );
  }

  Widget _buildCommentView(BuildContext context, OTHole postElement) {
    final String lastReplyContent = renderText(
        // if the floor has been folded, do not show the content directly!
        postElement.floors!.last_floor!.foldReason ??
            postElement.floors!.last_floor!.filteredContent!,
        S.of(context).image_tag,
        S.of(context).formula);
    return ListTile(
        dense: true,
        minLeadingWidth: 16,
        leading: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Icon(
            PlatformX.isMaterial(context)
                ? Icons.sms_outlined
                : CupertinoIcons.quote_bubble,
            color: Theme.of(context).hintColor,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      S.of(context).latest_reply(
                          postElement.floors!.last_floor!.anonyname ?? "?",
                          HumanDuration.tryFormat(
                              context,
                              DateTime.parse(postElement
                                      .floors!.last_floor!.time_created!)
                                  .toLocal())),
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                    Icon(CupertinoIcons.search,
                        size: 14,
                        color: Theme.of(context).hintColor.withOpacity(0.2)),
                  ]),
            ),
            Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LinkifyX(
                    text: lastReplyContent,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    onOpen: (link) => launchUrlWithNotice(context, link))),
          ],
        ),
        onTap: () async {
          ProgressFuture dialog = showProgressDialog(
              loadingText: S.of(context).loading, context: context);
          try {
            smartNavigatorPush(context, "/bbs/postDetail", arguments: {
              "post": await prefetchAllFloors(postElement),
              "scroll_to_end": true
            });
          } catch (error, st) {
            Noticing.showErrorDialog(context, error, trace: st);
          } finally {
            dialog.dismiss(showAnim: false);
          }
        });
  }
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
  final String? searchKeyWord;

  const OTFloorWidget({
    super.key,
    required this.floor,
    this.isInMention = false,
    this.showBottomBar = true,
    this.index,
    this.onTap,
    this.onLongPress,
    this.parentHole,
    required this.hasBackgroundImage,
    this.onTapImage,
    this.searchKeyWord,
  });

  @override
  Widget build(BuildContext context) {
    final bool needGenerateTags = (index == 0);

    const int foldLimit = 500;
    const int showCharCount = 15;
    String? fullContent;
    String? subContent;
    // Use renderText to remove latex, image links and mentions
    if (searchKeyWord != null && floor.content != null) {
      fullContent = renderText(
              floor.content!, S.of(context).image_tag, S.of(context).formula)
          .replaceAll('\n', ' ');
    }
    final bool foldLongFloor =
        fullContent != null && fullContent.length > foldLimit;

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

    Linkify? foldedWidget;

    if (foldLongFloor) {
      final int keywordIndex = fullContent.indexOf(searchKeyWord!);
      int startIndex = keywordIndex - showCharCount;
      if (startIndex > 0) {
        subContent = "$_kEllipsis${fullContent.substring(startIndex)}";
      } else {
        subContent = fullContent;
      }
      foldedWidget = LinkifyX(
        text: subContent,
        style: TextStyle(fontSize: 16, color: Theme.of(context).hintColor),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }

    final cardChild = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (needGenerateTags)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: generateTagWidgets(context, parentHole,
                      (String? tagName) {
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
                      const SizedBox(width: 8),
                      if (floor.anonyname ==
                          parentHole?.floors?.first_floor?.anonyname) ...[
                        OTLeadingTag(color: nameColor),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        floor.anonyname!,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: nameColor),
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Text(
                        HumanDuration.tryFormat(context,
                            DateTime.tryParse(floor.time_created ?? "")),
                        style: TextStyle(
                            color: Theme.of(context).hintColor, fontSize: 12),
                      )
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
                      if ((floor.modified ?? 0) > 0) ...[
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
                      ],
                      // We will only show the hidden tag if this hole is hidden
                      // and this floor is the first floor.
                      if (parentHole?.hidden == true &&
                          floor.floor_id ==
                              parentHole?.floors?.first_floor?.floor_id) ...[
                        const SizedBox(width: 4),
                        OTLeadingTag(
                          color: Colors.red,
                          text: S.of(context).hole_hidden,
                        ),
                      ],
                    ],
                  )
                ],
              ),
            ),
            Align(
                alignment: Alignment.topLeft,
                child: isInMention
                    // If content is being quoted, limit its height so that the view won't be too long.
                    ? LinkifyX(
                        text: renderText(floor.filteredContent!,
                                S.of(context).image_tag, S.of(context).formula)
                            .trim(),
                        textScaleFactor: 0.8,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        onOpen: (link) {
                          launchUrlWithNotice(context, link);
                        })
                    : smartRender(
                        context,
                        floor.filteredContent ?? S.of(context).fatal_error,
                        onLinkTap,
                        onTapImage ?? defaultOnImageTap,
                        hasBackgroundImage)),
            if (showBottomBar)
              OTFloorWidgetBottomBar(floor: floor, index: index),
          ],
        ),
      ),
    );

    return GestureDetector(
      onLongPress: onLongPress,
      child: Card(
        color: isInMention && PlatformX.isCupertino(context)
            ? Theme.of(context).dividerColor.withOpacity(0.05)
            : getDefaultCardBackgroundColor(context, hasBackgroundImage),
        child: (foldLongFloor ||
                floor.deleted == true ||
                floor.fold?.isNotEmpty == true)
            ? ExpansionTileX(
                title: foldLongFloor
                    ? foldedWidget!
                    : Text(
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
    super.key,
    required this.id,
    required this.type,
    this.showBottomBar = false,
    required this.hasBackgroundImage,
  });

  @override
  OTMentionPreviewWidgetState createState() => OTMentionPreviewWidgetState();
}

class OTMentionPreviewWidgetState extends State<OTMentionPreviewWidget> {
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
    super.key,
    required this.future,
    this.showBottomBar = false,
    required this.hasBackgroundImage,
  });

  /// Jump to the post which has [floor] in a new page.
  /// If the floor is in the same hole, it will STILL open a new page.
  static Future<void> jumpToFloorInNewPage(
    BuildContext context,
    OTFloor floor,
  ) async {
    ProgressFuture progressDialog = showProgressDialog(
        loadingText: S.of(context).loading, context: context);
    try {
      OTHole? hole = await OpenTreeHoleRepository.getInstance()
          .loadSpecificHole(floor.hole_id!);
      hole = await prefetchAllFloors(hole!);
      if (context.mounted) {
        smartNavigatorPush(context, "/bbs/postDetail",
            arguments: {"post": hole, "locate": floor});
      }
    } catch (e, st) {
      Noticing.showErrorDialog(context, e, trace: st);
    } finally {
      progressDialog.dismiss(showAnim: false);
    }
  }

  static Future<bool?> showFloorDetail(BuildContext context, OTFloor floor,
      [String? extraTips]) {
    bool inThatFloorPage = false;
    PagedListViewController<OTFloor>? pagedListViewController;
    try {
      // Find the PagedListViewController
      pagedListViewController = context
          .findAncestorWidgetOfExactType<PagedListView<OTFloor>>()!
          .pagedController!;
      // If this floor is directly in the hole
      inThatFloorPage = (pagedListViewController.indexOf(floor) != -1);
    } catch (_) {}

    return showPlatformModalSheet<bool?>(
        context: context,
        builder: (BuildContext cxt) {
          final maxHeightRatio = PlatformX.isMaterial(context) ? 0.3 : 0.85;
          final Widget cardBody = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (extraTips != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(extraTips),
                ),
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
                    // Only show "locate" button if the floor is valid
                    if (floor.valid)
                      TextButton(
                        onPressed: () async {
                          // Note how this code use [cxt] for some context but [context] for others.
                          // This is to prevent looking up deactivated context after [pop].
                          Navigator.pop(cxt);
                          // If this floor is directly in the hole
                          if (inThatFloorPage &&
                              pagedListViewController != null) {
                            // Scroll to the corresponding post
                            await PagedListViewHelper.scrollToItem(
                                context,
                                pagedListViewController,
                                floor,
                                ScrollDirection.UP);
                          } else {
                            // If this floor is in another hole
                            await jumpToFloorInNewPage(context, floor);
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
  }

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
  final int? index;

  const OTFloorWidgetBottomBar(
      {super.key, required this.floor, required this.index});

  @override
  OTFloorWidgetBottomBarState createState() => OTFloorWidgetBottomBarState();
}

class OTFloorWidgetBottomBarState extends State<OTFloorWidgetBottomBar> {
  late OTFloor floor;
  TextStyle? prebuiltStyle;
  ActionItem? selectedActionItem;

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
    prebuiltStyle ??=
        TextStyle(color: Theme.of(context).hintColor, fontSize: 12);
    return DefaultTextStyle(
      style: prebuiltStyle!,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (widget.index == null)
            Expanded(
                child: Row(
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
            )),
          if (widget.index != null)
            Expanded(
                child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${widget.index! + 1}F",
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
            )),
          Row(
            children: [
              OTFloorWidgetBottomBarButton(
                text: "${floor.like}",
                onTap: () async {
                  try {
                    floor.liked ??= false;
                    setState(() {
                      floor.liked = !floor.liked!;
                    });
                    floor = (await OpenTreeHoleRepository.getInstance()
                        .likeFloor(
                            floor.floor_id!, (floor.liked ?? false) ? 1 : 0))!;
                    setState(() {});
                  } catch (e, st) {
                    Noticing.showErrorDialog(context, e, trace: st);
                  }
                },
                icon: Icon(
                  (floor.liked ?? false)
                      ? CupertinoIcons.hand_thumbsup_fill
                      : CupertinoIcons.hand_thumbsup,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 5),
              OTFloorWidgetBottomBarButton(
                text: "${floor.dislike}",
                onTap: () async {
                  try {
                    floor.disliked ??= false;
                    setState(() {
                      floor.disliked = !floor.disliked!;
                    });
                    floor = (await OpenTreeHoleRepository.getInstance()
                        .likeFloor(floor.floor_id!,
                            (floor.disliked ?? false) ? -1 : 0))!;
                    setState(() {});
                  } catch (e, st) {
                    Noticing.showErrorDialog(context, e, trace: st);
                  }
                },
                icon: Icon(
                  (floor.disliked ?? false)
                      ? CupertinoIcons.hand_thumbsdown_fill
                      : CupertinoIcons.hand_thumbsdown,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                  size: 16,
                ),
              ),
              PopupMenuButton<ActionItem>(
                icon: Icon(
                  CupertinoIcons.ellipsis_circle,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                  size: 16,
                ),
                initialValue: selectedActionItem,
                // Callback that sets the selected popup menu item.
                onSelected: (ActionItem item) async {
                  setState(() {
                    selectedActionItem = item;
                  });
                  if (item == ActionItem.Report) {
                    if (await OTEditor.reportPost(context, floor.floor_id)) {
                      if (!context.mounted) return;
                      Noticing.showMaterialNotice(
                          context, S.of(context).report_success);
                    }
                  }
                  if (item == ActionItem.Delete) {
                    if (!context.mounted) return;
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
                        if (!context.mounted) return;
                        Noticing.showErrorDialog(context, e, trace: st);
                      }
                    }
                  }
                  if (item == ActionItem.Modify) {
                    if (!context.mounted) return;
                    if (await OTEditor.modifyReply(context, floor.hole_id,
                        floor.floor_id, floor.content)) {
                      if (!context.mounted) return;
                      Noticing.showMaterialNotice(
                          context, S.of(context).request_success);
                    }
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<ActionItem>>[
                  if (floor.is_me == true && floor.deleted == false)
                    PopupMenuItem<ActionItem>(
                      value: ActionItem.Modify,
                      child: OTFloorWidgetBottomBarButton(
                        icon: Icon(
                          CupertinoIcons.pencil,
                          color: Theme.of(context).hintColor,
                          size: 12,
                        ),
                        text: S.of(context).modify,
                      ),
                    ),
                  if (floor.is_me == true && floor.deleted == false)
                    PopupMenuItem<ActionItem>(
                      value: ActionItem.Delete,
                      child: OTFloorWidgetBottomBarButton(
                        text: S.of(context).delete,
                        icon: Icon(
                          CupertinoIcons.trash,
                          color: Theme.of(context).hintColor,
                          size: 12,
                        ),
                      ),
                    ),
                  if (floor.is_me != true)
                    PopupMenuItem<ActionItem>(
                      value: ActionItem.Report,
                      child: OTFloorWidgetBottomBarButton(
                        text: S.of(context).report,
                        icon: Icon(
                          CupertinoIcons.exclamationmark_octagon,
                          color: Theme.of(context).hintColor,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}

class OTFloorWidgetBottomBarButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String text;
  final Icon icon;

  const OTFloorWidgetBottomBarButton(
      {super.key, this.onTap, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class OTMessageItem extends StatefulWidget {
  final OTMessage message;

  const OTMessageItem({super.key, required this.message});

  static Future<void> markMessageAsRead(OTMessage message) async {
    if (message.has_read == true) return;
    message.has_read = true;
    await OpenTreeHoleRepository.getInstance().modifyMessage(message);
  }

  static void dispatchMessageByCode(BuildContext context, String? code,
      Map<String, dynamic>? data, int? id, String? description) async {
    try {
      switch (code) {
        case 'mention':
        case 'favorite':
        case 'modify':
        case 'reply':
          // data should be an [OTFloor].
          final floor = OTFloor.fromJson(data!);
          if (floor.floor_id == null) return;
          if (await OTFloorMentionWidget.showFloorDetail(context, floor) ==
                  true &&
              id != null) {
            markMessageAsRead(OTMessage(id, null, null, null, true, null));
          }
          break;
        case 'report':
        case 'report_dealt':
          // data should be [OTReport]
          final report = OTReport.fromJson(data!);
          final floor = report.floor!;
          if (floor.floor_id == null) return;
          if (await OTFloorMentionWidget.showFloorDetail(
                      context, floor, report.reason) ==
                  true &&
              id != null) {
            markMessageAsRead(OTMessage(id, null, null, null, true, null));
          }
          break;
        case 'mail':
          final floor = OTFloor.special(
              S.of(context).forum_message, description ?? "null");

          if (await OTFloorMentionWidget.showFloorDetail(context, floor) ==
                  true &&
              id != null) {
            markMessageAsRead(OTMessage(id, null, null, null, true, null));
          }
          break;
      }
    } catch (ignored) {
      // TODO: Support Other Types
    }
  }

  @override
  OTMessageItemState createState() => OTMessageItemState();
}

class OTMessageItemState extends State<OTMessageItem> {
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
              style: (message.has_read == false)
                  ? TextStyle(color: Theme.of(context).colorScheme.primary)
                  : null),
          subtitle: Text(HumanDuration.tryFormat(
              context, DateTime.tryParse(message.time_created ?? ""))),
          onTap: () {
            OTMessageItem.markMessageAsRead(message)
                .then((value) => setState(() {}));
            OTMessageItem.dispatchMessageByCode(context, message.code,
                message.data, message.message_id, message.description);
          }),
    );
  }
}

enum OTMentionType { FLOOR, HOLE }
