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

import 'dart:io';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/src/platform.dart' as platformImpl;

/// A universal implementation of Platform in dart:io and kIsWeb in dart:core.
class PlatformX {
  static bool get isWeb => kIsWeb;

  static bool get isAndroid => !isWeb && Platform.isAndroid;

  static bool get isIOS => !isWeb && Platform.isIOS;

  static bool get isFuchsia => !isWeb && Platform.isFuchsia;

  static bool get isLinux => !isWeb && Platform.isLinux;

  static bool get isMacOS => !isWeb && Platform.isMacOS;

  static bool get isWindows => !isWeb && Platform.isWindows;

  static bool get isMobile => isAndroid || isIOS;

  static bool get isDesktop => !isMobile;

  static bool get isApplePlatform => isIOS || isMacOS;

  static ThemeData getTheme(BuildContext context) {
    return PlatformX.isDarkMode
        ? Constant.darkTheme(PlatformX.isCupertino(context))
        : Constant.lightTheme(PlatformX.isCupertino(context));
  }

  static Color? backgroundColor(BuildContext context) {
    return isMaterial(context) ? null : Theme.of(context).cardColor;
  }

  static Color backgroundAccentColor(BuildContext context) {
    return isMaterial(context)
        ? Theme.of(context).primaryColor
        : Theme.of(context).accentColor;
  }

  static const illegalCharWindows = [r'\/', r':', r'@'];

  static String get fileSystemSlash => isWindows ? "\\" : "/";

  static File createPlatformFile(String path) {
    String fileSystemSlashRegex = isWindows ? r'\\' : r'\/';
    path = path.replaceAll(RegExp(r'\/'), fileSystemSlash);
    List<String> pathSegment = path.split(RegExp(fileSystemSlashRegex));

    // Skip the disk letter(like "C:")
    for (int i = 1; i < pathSegment.length; i++) {
      if (isWindows) {
        illegalCharWindows.forEach((element) =>
            pathSegment[i] = pathSegment[i].replaceAll(RegExp(element), ""));
      }
    }
    return File(pathSegment.join(fileSystemSlash));
  }

  static String get executablePath =>
      PlatformX.createPlatformFile(Platform.resolvedExecutable).path;

  static String getPathFromFile(String filePath) {
    if (filePath.lastIndexOf(fileSystemSlash) == -1) return filePath;
    return filePath.substring(0, filePath.lastIndexOf(fileSystemSlash));
  }

  static bool isMaterial(BuildContext context) =>
      platformImpl.isMaterial(context);

  static bool isCupertino(BuildContext context) =>
      platformImpl.isCupertino(context);

  static bool get isDarkMode =>
      WidgetsBinding.instance!.window.platformBrightness == Brightness.dark;

  static bool isDebugMode(_) => SettingsProvider.getInstance().debugMode;
}
