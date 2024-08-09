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

import 'package:dan_xi/model/extra.dart';
import 'package:dan_xi/page/forum/hole_search.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/app/announcement_repository.dart';
import 'package:dan_xi/util/browser_util.dart';
import 'package:dan_xi/util/noticing.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/material_banner.dart';
import 'package:dan_xi/widget/libraries/sized_by_child_builder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:provider/provider.dart';

class AutoBanner extends StatefulWidget {
  final Duration refreshDuration;
  final void Function(bool)? onExpand;
  final int maxDisplay;

  const AutoBanner(
      {super.key,
      required this.refreshDuration,
      this.onExpand,
      this.maxDisplay = 5});

  @override
  State<AutoBanner> createState() => AutoBannerState();
}

class AutoBannerState extends State<AutoBanner> {
  // Only shuffle for once each load
  bool _displayAll = false;
  List<int>? shufflePattern;
  late int _maxDisplay;
  void Function(bool)? onExpand;
  List<BannerExtra?>? list;

  @override
  void initState() {
    super.initState();
    onExpand = widget.onExpand;
    _maxDisplay = widget.maxDisplay;
  }

  bool updateBannerList() {
    var newList = AnnouncementRepository.getInstance().getBannerExtras();
    if (newList == null || newList.isEmpty) {
      return false;
    }

    setState(() {
      list = newList;
      list!.shuffle();
    });
    return true;
  }

  void onTapAction(String action) {
    try {
      if (action.startsWith("##")) {
        final floorMatch = floorPattern.firstMatch(action);
        int floorId = int.parse(floorMatch!.group(1)!);
        goToFloorIdResultPage(context, floorId);
      } else if (action.startsWith("#")) {
        final pidMatch = pidPattern.firstMatch(action);
        int pid = int.parse(pidMatch!.group(1)!);
        goToPIDResultPage(context, pid);
      } else {
        BrowserUtil.openUrl(action, context);
      }
    } catch (e) {
      Noticing.showErrorDialog(context, e);
    }
  }

  Widget _buildAllList(double bannerHeight) {
    return ConstrainedBox(
      constraints:
          BoxConstraints.loose(Size.fromHeight(bannerHeight * _maxDisplay)),
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: list!.length,
        itemBuilder: (context, index) {
          var bannerExtra = list![index];
          return ConstrainedBox(
              constraints: BoxConstraints.loose(Size.fromHeight(bannerHeight)),
              child: bannerExtra == null
                  ? Container()
                  : SlimMaterialBanner(
                      icon: PlatformX.isMaterial(context)
                          ? const Icon(Icons.campaign)
                          : const Icon(CupertinoIcons.bell_circle),
                      title: bannerExtra.title,
                      actionName: bannerExtra.actionName,
                      onTapAction: () => onTapAction(bannerExtra.action)));
        },
      ),
    );
  }

  Widget _buildSingleItem(double bannerHeight) {
    return ConstrainedBox(
        constraints: BoxConstraints.loose(Size.fromHeight(bannerHeight)),
        child: Swiper(
          itemBuilder: (BuildContext context, int index) {
            final bannerExtra = list![index];
            if (bannerExtra == null) return Container();
            return SlimMaterialBanner(
                icon: IconButton(
                    icon: const Icon(Icons.arrow_drop_down),
                    iconSize: 28,
                    padding: EdgeInsets.zero,
                    alignment: Alignment.center,
                    onPressed: () => setState(() {
                          _displayAll = true;
                          if (onExpand != null) {
                            onExpand!(_displayAll);
                          }
                        })),
                title: bannerExtra.title,
                actionName: bannerExtra.actionName,
                onTapAction: () => onTapAction(bannerExtra.action));
          },
          itemCount: list!.length,
          autoplay: true,
          autoplayDelay: widget.refreshDuration.inMilliseconds,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Selector<SettingsProvider, bool>(
        builder: (BuildContext context, bool bannerEnabled, Widget? child) {
          if (!bannerEnabled) {
            return Container();
          }
          list ??= AnnouncementRepository.getInstance().getBannerExtras();
          // Only update if list is null. And if the update fails, return nil
          if (list == null && !updateBannerList()) {
            return Container();
          }
          // If the list is empty (i.e. no banner), return nil
          if (list!.isEmpty) {
            return Container(); // FIXME: using `nil` here will break the layout. Don't know why.
          }

          // Since the banner is not a fixed size, we need to use [SizedByChildBuilder]
          // to get the height of the banner. Otherwise, [Swiper] will have infinite
          // height bound and throw an exception during build.
          return SizedByChildBuilder(
              child: (context, key) => SlimMaterialBanner(
                    key: key,
                    icon: PlatformX.isMaterial(context)
                        ? const Icon(Icons.campaign)
                        : const Icon(CupertinoIcons.bell_circle),
                    title: "",
                    actionName: "",
                  ),
              builder: (context, size) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _displayAll
                          ? _buildAllList(size.height)
                          : _buildSingleItem(size.height),
                      if (_displayAll)
                        SizedBox(
                            height: 20,
                            child: InkWell(
                              onTap: () => setState(() {
                                _displayAll = false;
                                if (onExpand != null) {
                                  onExpand!(_displayAll);
                                }
                              }),
                              child: const Icon(Icons.arrow_drop_up),
                            ))
                    ],
                  ));
        },
        selector: (_, model) => model.isBannerEnabled);
  }
}
