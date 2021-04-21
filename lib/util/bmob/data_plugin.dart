import 'dart:async';

import 'package:flutter/services.dart';

class DataPlugin {
  static Future<String> get platformVersion async {
    return "";
  }

  static Future<String> get installationId async {
    return "";
  }

  static void toast(String msg) async {}
}
