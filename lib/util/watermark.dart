/*
 *     Copyright (C) 2023  DanXi-Dev
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
import 'package:dan_xi/widget/opentreehole/flutter_watermark_widget.dart';
import 'package:flutter/material.dart';

class Watermark {
  static OverlayEntry? overlayEntry;

  /// Add a watermark to the screen.
  static void addWatermark(BuildContext context,
      {int rowCount = 3, int columnCount = 10, TextStyle? textStyle}) async {
    if (overlayEntry != null) {
      overlayEntry!.remove();
    }

    OverlayState? overlayState = Overlay.of(context, rootOverlay: true);

    overlayEntry = OverlayEntry(
        builder: (context) => FullScreenWatermark(
          rowCount: rowCount,
          columnCount: columnCount,
          textStyle: textStyle ??
              TextStyle(
                  color: PlatformX.isDarkMode
                      ? Color(
                      SettingsProvider.getInstance().darkWatermarkColor)
                      : Color(SettingsProvider.getInstance()
                      .lightWatermarkColor),
                  fontSize: 36,
                  decoration: TextDecoration.none),
        ));

    overlayState.insert(overlayEntry!);
  }
}
