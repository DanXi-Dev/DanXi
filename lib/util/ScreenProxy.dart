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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenProxy {
  static const MethodChannel _channel =
      const MethodChannel('github.com/clovisnicolas/flutter_screen');

  static Future<double> get brightness async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
      return (await _channel.invokeMethod('brightness')) as double;
    else
      return 1.0;
  }

  static setBrightness(double brightness) {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
      _channel.invokeMethod('setBrightness', {"brightness": brightness});
  }

  static Future<bool> get isKeptOn async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
      return (await _channel.invokeMethod('isKeptOn')) as bool;
    else
      return true;
  }

  static keepOn(bool on) {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
      _channel.invokeMethod('keepOn', {"on": on});
  }
}
