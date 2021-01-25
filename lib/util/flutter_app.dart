import 'dart:io';

import 'package:flutter/services.dart';

class FlutterApp {
  static void exitApp() {
    if (Platform.isAndroid || Platform.isIOS) {
      SystemNavigator.pop(animated: true);
    } else {
      exit(0);
    }
  }
}
