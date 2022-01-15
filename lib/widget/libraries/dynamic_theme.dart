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
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/material.dart';

/// A ListView supporting paged loading and viewing.
class DynamicThemeController extends StatefulWidget {
  final Widget child;

  const DynamicThemeController({Key? key, required this.child})
      : super(key: key);

  @override
  _DynamicThemeControllerState createState() => _DynamicThemeControllerState();
}

class _DynamicThemeControllerState extends State<DynamicThemeController>
    with WidgetsBindingObserver {
  late Brightness _brightness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    _brightness =
        WidgetsBinding.instance!.platformDispatcher.platformBrightness;
    WidgetsBinding.instance!.platformDispatcher.onPlatformBrightnessChanged =
        () {
      setState(() {
        _brightness =
            WidgetsBinding.instance!.platformDispatcher.platformBrightness;
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: _brightness == Brightness.light
            ? Constant.lightTheme(!PlatformX.isMaterial(context))
            : Constant.darkTheme(!PlatformX.isMaterial(context)),
        child: widget.child);
  }
}
