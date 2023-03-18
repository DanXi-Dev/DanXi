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

import 'package:dan_xi/util/platform_universal.dart';
import 'package:screen_brightness/screen_brightness.dart';

/// A proxy class for [ScreenBrightness] to make it work on all platforms.
class ScreenProxy {
  static Future<void> init() async {
    if (PlatformX.isMobile) await ScreenBrightness().setAutoReset(false);
  }

  static Future<double?> get brightness async {
    if (PlatformX.isMobile) {
      return await ScreenBrightness().current;
    } else {
      return 0;
    }
  }

  static setBrightness(double brightness) async {
    if (PlatformX.isMobile) {
      await ScreenBrightness().setScreenBrightness(brightness);
    }
  }

  static resetBrightness() async {
    if (PlatformX.isMobile) {
      await ScreenBrightness().resetScreenBrightness();
    }
  }
}
