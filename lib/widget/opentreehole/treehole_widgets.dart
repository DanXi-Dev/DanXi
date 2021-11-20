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
import 'package:dan_xi/master_detail/master_detail_view.dart';
import 'package:dan_xi/model/opentreehole/floor.dart';
import 'package:dan_xi/model/opentreehole/hole.dart';
import 'package:dan_xi/page/bbs_post.dart';
import 'package:dan_xi/page/subpage_bbs.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/human_duration.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/opentreehole/bbs_editor.dart';
import 'package:dan_xi/widget/future_widget.dart';
import 'package:dan_xi/widget/render/base_render.dart';
import 'package:dan_xi/widget/round_chip.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
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

  OTFloorWidget({
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
      onTap: onTap,
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
                    const SizedBox(
                      width: 2,
                    ),
                    if (isNested)
                      Center(
                        child: Icon(CupertinoIcons.search,
                            color: Theme.of(context).hintColor.withOpacity(0.2),
                            size: 12),
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
                          },
                        )
                      : smartRender(
                          floor.filteredContent!, onLinkTap, onImageTap)),
            ],
          ),
          subtitle: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(
              height: 8,
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
                style:
                    TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
              ),
              if (!isNested)
                GestureDetector(
                  child: Text(S.of(context).report,
                      style: TextStyle(
                          color: Theme.of(context).hintColor, fontSize: 12)),
                  onTap: () {
                    BBSEditor.reportPost(context, floor.floor_id);
                  },
                ),
            ]),
          ]),
          onTap: onTap,
        ),
      ),
    );
  }
}

class OTFloorWidgetLazy extends StatelessWidget {
  final Future<OTFloor> future;

  OTFloorWidgetLazy({
    required this.future,
  });

  void showFloorDetail(BuildContext context, OTFloor floor) {
    showPlatformModalSheet(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: OTFloorWidget(
              floor: floor,
            ),
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
