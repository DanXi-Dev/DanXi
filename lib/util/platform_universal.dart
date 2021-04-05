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

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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

  static bool isMaterial(BuildContext context) =>
      platformImpl.isMaterial(context);

  static bool isCupertino(BuildContext context) =>
      platformImpl.isCupertino(context);
}
