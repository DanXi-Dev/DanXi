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

import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// A Widget to dynamically switch theme for its children based on system settings.
class DynamicThemeController extends StatefulWidget {
  final Widget child;
  final ThemeData lightTheme;
  final ThemeData darkTheme;

  const DynamicThemeController(
      {super.key,
      required this.child,
      required this.lightTheme,
      required this.darkTheme});

  @override
  DynamicThemeControllerState createState() => DynamicThemeControllerState();
}

class DynamicThemeControllerState extends State<DynamicThemeController>
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
    final type =
        context.select<SettingsProvider, ThemeType>((s) => s.themeType);

    var effectiveBrightness = _brightness;
    if (type == ThemeType.LIGHT) {
      effectiveBrightness = Brightness.light;
    } else if (type == ThemeType.DARK) {
      effectiveBrightness = Brightness.dark;
    }
    return Theme(
        data: effectiveBrightness == Brightness.light
            ? widget.lightTheme
            : widget.darkTheme,
        child: widget.child);
  }
}

/// A Widget to decide the system overlay style based on the theme.
class ThemedSystemOverlay extends StatelessWidget {
  final Widget child;

  const ThemedSystemOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    var baseStyle = Theme.of(context).brightness == Brightness.light
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light;
    if (PlatformX.isAndroid) {
      // Copy from Flutter's [AnimatedPhysicalModel] widget.
      final bottomColor = ElevationOverlay.applySurfaceTint(
          Theme.of(context).colorScheme.surface,
          Theme.of(context).colorScheme.surfaceTint,
          3.0);

      baseStyle = baseStyle.copyWith(
          systemNavigationBarColor: bottomColor,
          systemNavigationBarIconBrightness:
              bottomColor.computeLuminance() > 0.5
                  ? Brightness.dark
                  : Brightness.light);
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: baseStyle, child: child);
  }
}
