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

import 'package:flutter/material.dart';

/// A Widget to dynamically switch theme for its children based on system settings
class DynamicThemeController extends StatefulWidget {
  final Widget child;
  final ThemeData lightTheme;
  final ThemeData darkTheme;

  const DynamicThemeController(
      {Key? key,
      required this.child,
      required this.lightTheme,
      required this.darkTheme})
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
    WidgetsBinding.instance.addObserver(this);
    _brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
      setState(() {
        _brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
      });
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: _brightness == Brightness.light
            ? widget.lightTheme
            : widget.darkTheme,
        child: widget.child);
  }
}
