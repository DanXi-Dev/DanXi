import 'package:flutter/material.dart';

import '../widget/opentreehole/flutter_watermark_widget.dart';

class DisableScreenshots {
  static final DisableScreenshots _singleton = DisableScreenshots._internal();
  factory DisableScreenshots() {
    return _singleton;
  }
  DisableScreenshots._internal();

  OverlayEntry? _overlayEntry;

  void addWatermark(BuildContext context, String watermark,
      {int rowCount = 3, int columnCount = 10, TextStyle? textStyle}) async {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
    }

    OverlayState? overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(
        builder: (context) => DisableScreenshotsWatermark(
          rowCount: rowCount,
          columnCount: columnCount,
          text: watermark,
          textStyle: textStyle ??
              const TextStyle(
                  color: Color(0x02000000),
                  fontSize: 18,
                  decoration: TextDecoration.none),
        ));
    overlayState?.insert(_overlayEntry!);
  }

  void removeWatermark() async {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }
}