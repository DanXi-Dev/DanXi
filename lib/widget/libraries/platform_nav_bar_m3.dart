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
  const PlatformNavBarM3({
    super.key,
    super.widgetKey,
    super.backgroundColor,
    super.items,
    super.itemChanged,
    super.currentIndex,
    super.material,
    super.cupertino,
  });

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
