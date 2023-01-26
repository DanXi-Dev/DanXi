import 'package:dan_xi/provider/settings_provider.dart';
import 'package:flutter/material.dart';

import '../widget/opentreehole/flutter_watermark_widget.dart';

class Watermark {
  static OverlayEntry? overlayEntry;

  static void addWatermark(BuildContext context, bool isDarkMode,
      {int rowCount = 3, int columnCount = 10, TextStyle? textStyle}) async {

    if (overlayEntry != null) {
      overlayEntry!.remove();
    }

    OverlayState? overlayState = Overlay.of(context);

    overlayEntry = OverlayEntry(
        builder: (context) => FullScreenWatermark(
              rowCount: rowCount,
              columnCount: columnCount,
              textStyle: textStyle ??
                  TextStyle(
                      color: isDarkMode
                          ? Color(
                              SettingsProvider.getInstance().darkWatermarkColor)
                          : Color(SettingsProvider.getInstance()
                              .lightWatermarkColor),
                      fontSize: 18,
                      decoration: TextDecoration.none),
            ));

    overlayState.insert(overlayEntry!);
  }
}
