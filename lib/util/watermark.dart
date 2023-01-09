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
                      color: isDarkMode ? Color(0x06000000) : Color(0x02000000),
                      fontSize: 18,
                      decoration: TextDecoration.none),
            ));
    overlayState?.insert(overlayEntry!);
  }
}
