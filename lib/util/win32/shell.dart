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

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class Win32Shell {
  /// Execute shell, return the status code.
  ///
  /// Notes: It WON'T wait the process to finish.
  static int executeShell(String filePath,
      {int showCmd = SHOW_WINDOW_CMD.SW_HIDE,
      String? dir,
      String param = '',
      bool runAsAdmin = false}) {
    return ShellExecute(
        0,
        runAsAdmin ? "runas".toNativeUtf16() : nullptr,
        filePath.toNativeUtf16(),
        param.toNativeUtf16(),
        dir?.toNativeUtf16() ?? nullptr,
        showCmd);
  }
}
