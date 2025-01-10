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
import 'package:dan_xi/widget/forum/flutter_watermark_widget.dart';
import 'package:flutter/material.dart';

/// A reference-counted full-screen watermark that shows user ID overlay on the screen.
class Watermark {
  static OverlayEntry? overlayEntry;

  /// The reference count of the watermark. When it is 0, the watermark will be removed.
  static int refCount = 0;

  static void remove() {
    assert(refCount > 0, 'The watermark reference count is already 0.');
    refCount--;
    if (refCount == 0) {
      assert(overlayEntry != null, 'The watermark overlay entry is null.');
      overlayEntry?.remove();
      overlayEntry = null;
    }
  }

  /// Add a watermark to the screen.
  static void addWatermark(BuildContext context,
      {int rowCount = 4, int columnCount = 8, TextStyle? textStyle}) async {
    if (overlayEntry != null) {
      // If the watermark is already added, remove it first so that the new one can be added.
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
                      fontSize: 48,
                      decoration: TextDecoration.none),
            ));

    overlayState.insert(overlayEntry!);
    refCount++;
  }
}

/// A state widget that shows a full-screen watermark when the child widget is shown,
/// and removes the watermark when the child widget is destroyed.
///
/// You can use the [withWatermarkRegion] extension method to wrap a widget with a watermark region.
class WatermarkRegion extends StatefulWidget {
  final Widget child;
  const WatermarkRegion({super.key, required this.child});

  @override
  State<WatermarkRegion> createState() => _WatermarkRegionState();
}

class _WatermarkRegionState extends State<WatermarkRegion> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Watermark.addWatermark(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    Watermark.remove();
    super.dispose();
  }
}

extension WatermarkRegionExtension on Widget {
  /// Wrap the widget with a watermark region.
  Widget withWatermarkRegion() => WatermarkRegion(child: this);
}
