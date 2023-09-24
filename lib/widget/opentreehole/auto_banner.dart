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
import 'package:dan_xi/page/opentreehole/hole_search.dart';
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

  const AutoBanner({Key? key, required this.refreshDuration}) : super(key: key);

  @override
  State<AutoBanner> createState() => _AutoBannerState();
}

class _AutoBannerState extends State<AutoBanner> {
  bool _displayAll = false;

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

  Widget _buildAllList(List<BannerExtra?> list) {
    return ListView.builder(
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      itemCount: list.length,
      itemBuilder: (context, index) {
        var bannerExtra = list[index];
        var elem = SizedByChildBuilder(
            child: (context, key) => SlimMaterialBanner(
                  key: key,
                  icon: PlatformX.isMaterial(context)
                      ? const Icon(Icons.campaign)
                      : const Icon(CupertinoIcons.bell_circle),
                  title: "",
                  actionName: "",
                ),
            builder: (context, size) => ConstrainedBox(
                constraints: BoxConstraints.loose(Size.fromHeight(size.height)),
                child: bannerExtra == null
                    ? Container()
                    : SlimMaterialBanner(
                        icon: PlatformX.isMaterial(context)
                            ? const Icon(Icons.campaign)
                            : const Icon(CupertinoIcons.bell_circle),
                        title: bannerExtra.title,
                        actionName: bannerExtra.actionName,
                        onTapAction: () => onTapAction(bannerExtra.action))));

        return elem;
      },
    );
  }

  Widget _buildSingleItem(List<BannerExtra?> list) {
    return SizedByChildBuilder(
        child: (context, key) => SlimMaterialBanner(
              key: key,
              icon: PlatformX.isMaterial(context)
                  ? const Icon(Icons.campaign)
                  : const Icon(CupertinoIcons.bell_circle),
              title: "",
              actionName: "",
            ),
        builder: (context, size) => ConstrainedBox(
            constraints: BoxConstraints.loose(Size.fromHeight(size.height)),
            child: Swiper(
              itemBuilder: (BuildContext context, int index) {
                final bannerExtra = list[index];
                if (bannerExtra == null) return Container();
                return SlimMaterialBanner(
                    icon: PlatformX.isMaterial(context)
                        ? const Icon(Icons.campaign)
                        : const Icon(CupertinoIcons.bell_circle),
                    title: bannerExtra.title,
                    actionName: bannerExtra.actionName,
                    onTapAction: () => onTapAction(bannerExtra.action));
              },
              itemCount: list.length,
              autoplay: true,
              autoplayDelay: widget.refreshDuration.inMilliseconds,
            )));
  }

  @override
  Widget build(BuildContext context) {
    return Selector<SettingsProvider, bool>(
        builder: (BuildContext context, bool bannerEnabled, Widget? child) {
          if (!bannerEnabled) {
            return Container();
          }
          List<BannerExtra?>? list =
              AnnouncementRepository.getInstance().getBannerExtras();
          if (list == null || list.isEmpty) return Container();
          // Since the banner is not a fixed size, we need to use [SizedByChildBuilder]
          // to get the height of the banner. Otherwise, [Swiper] will have infinite
          // height bound and throw an exception during build.
          return Column(
            children: [
              _displayAll ? _buildAllList(list) : _buildSingleItem(list),
              SizedBox(
                  height: 20,
                  width: double.infinity,
                  child:  InkWell(
                    onTap: () => setState(() {
                      _displayAll = !_displayAll;
                    }),
                    child: Icon(_displayAll
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down),
                  ))
            ],
          );
        },
        selector: (_, model) => model.isBannerEnabled);
  }
}
