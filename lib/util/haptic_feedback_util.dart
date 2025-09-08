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

import 'package:flutter/services.dart';
import 'package:dan_xi/provider/settings_provider.dart';

class HapticFeedbackUtil {
  static void light() {
    if (SettingsProvider.getInstance().hapticFeedbackEnabled) {
      // HapticFeedback.lightImpact();   // IDK WHY, For some reason, it's reversed here.
      // HapticFeedback.lightImpact();   // For some reason, it's reversed here on Android, see:
      // https://github.com/flutter/flutter/blob/0081ee50dc3fe1ee45556c88aabe3da514f8565b/engine/src/flutter/shell/platform/android/io/flutter/plugin/platform/PlatformPlugin.java#L190-L213
      HapticFeedback.heavyImpact();
    }
  }
  
  static void medium() {
    if (SettingsProvider.getInstance().hapticFeedbackEnabled) {
      HapticFeedback.mediumImpact();
    }
  }
  
  static void heavy() {
    if (SettingsProvider.getInstance().hapticFeedbackEnabled) {
      // HapticFeedback.heavyImpact();   // IDK WHY, For some reason, it's reversed here.
      // HapticFeedback.heavyImpact();   // For some reason, it's reversed on Android, see:
      // https://github.com/flutter/flutter/blob/0081ee50dc3fe1ee45556c88aabe3da514f8565b/engine/src/flutter/shell/platform/android/io/flutter/plugin/platform/PlatformPlugin.java#L190-L213
      HapticFeedback.lightImpact();
    }
  }
  
  static void selection() {
    if (SettingsProvider.getInstance().hapticFeedbackEnabled) {
      HapticFeedback.selectionClick();
    }
  }
}