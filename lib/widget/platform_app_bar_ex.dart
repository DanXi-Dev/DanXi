/*
 *     Copyright (C) 2021  w568w
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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

const Color _kDefaultNavBarBorderColor = const Color(0x4C000000);

const Border _kDefaultNavBarBorder = const Border(
  bottom: const BorderSide(
    color: _kDefaultNavBarBorderColor,
    width: 0.0, // One physical pixel.
    style: BorderStyle.solid,
  ),
);

/// A copy of [PlatformAppBar], solving the issue "iOS navigationBar animation glitch" in commit a540b4f4.
class PlatformAppBarX extends PlatformAppBar {
  final Key widgetKey;

  final Widget title;
  final Color backgroundColor;
  final Widget leading;
  final List<Widget> trailingActions;
  final bool automaticallyImplyLeading;

  final PlatformBuilder<MaterialAppBarData> material;
  final PlatformBuilder<CupertinoNavigationBarData> cupertino;

  PlatformAppBarX({
    Key key,
    this.widgetKey,
    this.title,
    this.backgroundColor,
    this.leading,
    this.trailingActions,
    this.automaticallyImplyLeading,
    this.material,
    this.cupertino,
  }) : super(key: key);

  @override
  PreferredSizeWidget createMaterialWidget(BuildContext context) {
    final data = material?.call(context, platform(context));

    return AppBar(
      key: data?.widgetKey ?? widgetKey,
      title: data?.title ?? title,
      backgroundColor: data?.backgroundColor ?? backgroundColor,
      bottom: data?.bottom,
      actions: data?.actions ?? trailingActions,
      automaticallyImplyLeading:
          data?.automaticallyImplyLeading ?? automaticallyImplyLeading ?? true,
      bottomOpacity: data?.bottomOpacity ?? 1.0,
      brightness: data?.brightness,
      centerTitle: data?.centerTitle,
      elevation: data?.elevation ?? 4.0,
      flexibleSpace: data?.flexibleSpace,
      iconTheme: data?.iconTheme,
      leading: data?.leading ?? leading,
      primary: data?.primary ?? true,
      textTheme: data?.textTheme,
      titleSpacing: data?.titleSpacing ?? NavigationToolbar.kMiddleSpacing,
      toolbarOpacity: data?.toolbarOpacity ?? 1.0,
      actionsIconTheme: data?.actionsIconTheme,
      shape: data?.shape,
      excludeHeaderSemantics: data?.excludeHeaderSemantics ?? false,
      shadowColor: data?.shadowColor,
      toolbarHeight: data?.toolbarHeight,
      leadingWidth: data?.leadingWidth,
      backwardsCompatibility: data?.backwardsCompatibility,
      foregroundColor: data?.foregroundColor,
      systemOverlayStyle: data?.systemOverlayStyle,
      titleTextStyle: data?.titleTextStyle,
      toolbarTextStyle: data?.toolbarTextStyle,
    );
  }

  @override
  CupertinoNavigationBar createCupertinoWidget(BuildContext context) {
    final data = cupertino?.call(context, platform(context));
    final defaultData = CupertinoNavigationBarData(
      // Issue with cupertino where a bar with no transparency
      // will push the list down. Adding some alpha value fixes it (in a hacky way)
      backgroundColor: Colors.white.withAlpha(254),
      leading: MediaQuery(
        data: MediaQueryData(
            textScaleFactor: MediaQuery.textScaleFactorOf(context)),
        child: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: MediaQuery(
          data: MediaQueryData(
              textScaleFactor: MediaQuery.textScaleFactorOf(context)),
          child: data?.title ?? title),
    );
    var trailing = trailingActions?.isEmpty ?? true
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: trailingActions,
          );

    final heroTag = data?.heroTag;
    if (heroTag != null) {
      return CupertinoNavigationBar(
        key: data?.widgetKey ?? widgetKey,
        middle: defaultData.title ?? title,
        backgroundColor: defaultData.backgroundColor ?? backgroundColor,
        automaticallyImplyLeading: data?.automaticallyImplyLeading ??
            automaticallyImplyLeading ??
            true,
        automaticallyImplyMiddle: data?.automaticallyImplyMiddle ?? true,
        previousPageTitle: data?.previousPageTitle,
        padding: data?.padding,
        border: data?.border ?? _kDefaultNavBarBorder,
        leading: defaultData.leading ?? leading,
        trailing: data?.trailing ?? trailing,
        transitionBetweenRoutes: data?.transitionBetweenRoutes ?? true,
        brightness: data?.brightness,
        heroTag: heroTag,
      );
    }

    return CupertinoNavigationBar(
      key: data?.widgetKey ?? widgetKey,
      middle: defaultData.title ?? title,
      backgroundColor: defaultData.backgroundColor ?? backgroundColor,
      automaticallyImplyLeading:
          data?.automaticallyImplyLeading ?? automaticallyImplyLeading ?? true,
      automaticallyImplyMiddle: data?.automaticallyImplyMiddle ?? true,
      previousPageTitle: data?.previousPageTitle,
      padding: data?.padding,
      border: data?.border ?? _kDefaultNavBarBorder,
      leading: defaultData.leading ?? leading,
      trailing: data?.trailing ?? trailing,
      transitionBetweenRoutes: data?.transitionBetweenRoutes ?? true,
      brightness: data?.brightness,
      //heroTag: , used above
    );
  }
}
