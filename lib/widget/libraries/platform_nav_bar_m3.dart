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

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class PlatformNavBarM3 extends PlatformNavBar {
  @override
  final Key? widgetKey;
  @override
  final Color? backgroundColor;

  @override
  final List<BottomNavigationBarItem>? items;
  @override
  final void Function(int)? itemChanged;
  @override
  final int? currentIndex;

  @override
  final PlatformBuilder<MaterialNavBarData>? material;
  @override
  final PlatformBuilder<CupertinoTabBarData>? cupertino;

  PlatformNavBarM3({
    super.key,
    this.widgetKey,
    this.backgroundColor,
    this.items,
    this.itemChanged,
    this.currentIndex,
    this.material,
    this.cupertino,
  }) : super(
          widgetKey: widgetKey,
          backgroundColor: backgroundColor,
          items: items,
          itemChanged: itemChanged,
          currentIndex: currentIndex,
          material: material,
          cupertino: cupertino,
        );

  @override
  BottomAppBar createMaterialWidget(BuildContext context) {
    final data = material?.call(context, platform(context));
    var tabItems = data?.items ?? items ?? const <BottomNavigationBarItem>[];

    var barM3 = NavigationBar(
      selectedIndex: data?.currentIndex ?? currentIndex ?? 0,
      destinations: tabItems
          .map((e) => NavigationDestination(
                icon: e.icon,
                selectedIcon: e.activeIcon,
                label: e.label!,
                tooltip: e.tooltip,
              ))
          .toList(),
      onDestinationSelected: data?.itemChanged ?? itemChanged,
      backgroundColor: data?.backgroundColor ?? backgroundColor,
    );

    return BottomAppBar(
      color: data?.backgroundColor ?? backgroundColor,
      elevation: data?.elevation,
      key: data?.widgetKey ?? widgetKey,
      shape: data?.shape,
      clipBehavior: data?.clipBehavior ?? Clip.none,
      notchMargin: data?.notchMargin ?? 4.0,
      child: barM3,
    );
  }
}
