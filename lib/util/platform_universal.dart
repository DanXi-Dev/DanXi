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
import 'package:device_identity/device_identity.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/src/platform.dart' as platform_impl;
import 'package:permission_handler/permission_handler.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

/// A universal implementation of [Platform] in dart:io and [kIsWeb] in dart:core.
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

  static Future<String> getUniqueDeviceId() async {
    String? deviceId;
    try {
      deviceId = await PlatformDeviceId.getDeviceId;
    } catch (_) {}
    if (PlatformX.isAndroid) {
      if (deviceId?.isNotEmpty != true) {
        try {
          deviceId ??= await DeviceIdentity.androidId;
        } catch (_) {}
      }
      if (deviceId?.isNotEmpty != true) {
        try {
          deviceId ??= await DeviceIdentity.oaid;
        } catch (_) {}
      }
      if (deviceId?.isNotEmpty != true) {
        try {
          deviceId ??= await DeviceIdentity.ua;
        } catch (_) {}
      }
    }

    return deviceId ?? const Uuid().v4();
  }

  static ThemeData getTheme(BuildContext context,
      [MaterialColor? primarySwatch, bool? watchChanges]) {
    primarySwatch ??= Colors.blue;
    watchChanges ??= true;

    var isDarkMode = watchChanges
        ? context
                .select<SettingsProvider, ThemeType>(
                    (settings) => settings.themeType)
                .getBrightness() ==
            Brightness.dark
        : PlatformX.isDarkMode;
    return isDarkMode
        ? Constant.darkTheme(PlatformX.isCupertino(context), primarySwatch)
        : Constant.lightTheme(PlatformX.isCupertino(context), primarySwatch);
  }

  static Color? backgroundColor(BuildContext context) {
    return isMaterial(context) ? null : Theme.of(context).cardColor;
  }

  static Color backgroundAccentColor(BuildContext context) {
    return isMaterial(context)
        ? Theme.of(context).primaryColor
        : Theme.of(context).colorScheme.secondary;
  }

  static const illegalCharWindows = [r'/', r':', r'@'];

  static String get fileSystemSlash => isWindows ? "\\" : "/";

  static File createPlatformFile(String path) {
    String fileSystemSlashRegex = isWindows ? r'\\' : r'/';
    path = path.replaceAll(RegExp(r'/'), fileSystemSlash);
    List<String> pathSegment = path.split(RegExp(fileSystemSlashRegex));

    // Skip the disk letter(like "C:")
    for (int i = 1; i < pathSegment.length; i++) {
      if (isWindows) {
        for (var char in illegalCharWindows) {
          pathSegment[i] = pathSegment[i].replaceAll(RegExp(char), "");
        }
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
      platform_impl.isMaterial(context);

  static bool isCupertino(BuildContext context) =>
      platform_impl.isCupertino(context);

  static bool get isDarkMode {
    final type = SettingsProvider.getInstance().themeType;
    return type.getBrightness() == Brightness.dark;
  }

  static bool isDebugMode(_) => SettingsProvider.getInstance().debugMode;

  static Future<bool> get galleryStorageGranted async {
    if (isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      if ((androidInfo.version.sdkInt) >= 29) return true;
      return await Permission.storage.status.isGranted;
    } else {
      return true;
    }
  }
}
