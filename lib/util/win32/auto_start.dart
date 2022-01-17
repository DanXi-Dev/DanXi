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
import 'package:dan_xi/util/win32/registry.dart';
import 'package:win32/win32.dart';

class WindowsAutoStart {
  static const KEY_PATH = r'Software\Microsoft\Windows\CurrentVersion\Run';
  static const KEY_NAME = "Danxi";
  static const KEY_FULL_PATH =
      r"HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run";

  static bool get autoStart {
    int hKey = Registry.getRegistryKeyHandle(HKEY_CURRENT_USER, KEY_PATH);
    String? path;
    try {
      path = Registry.getStringKey(hKey, KEY_NAME);
    } catch (_) {
    } finally {
      RegCloseKey(hKey);
    }
    return PlatformX.executablePath == path;
  }

  static set autoStart(bool value) {
    if (value) {
      Registry.setStringValueA(
          KEY_FULL_PATH, KEY_NAME, PlatformX.executablePath);
    } else {
      Registry.deleteStringKeyA(KEY_FULL_PATH, KEY_NAME);
    }
  }
}
