import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WiFiUtils {
  static Connectivity _connectivity = Connectivity();

  static Connectivity getConnectivity() {
    return _connectivity;
  }

  static Future<dynamic> getWiFiInfo(
      ConnectivityResult connectivityResult) async {
    var result = {};
    switch (connectivityResult) {
      case ConnectivityResult.wifi:
        String wifiName, wifiIP;

        try {
          if (!kIsWeb && Platform.isIOS) {
            LocationAuthorizationStatus status =
                await _connectivity.getLocationServiceAuthorization();
            if (status == LocationAuthorizationStatus.notDetermined) {
              status =
                  await _connectivity.requestLocationServiceAuthorization();
            }
            if (status == LocationAuthorizationStatus.authorizedAlways ||
                status == LocationAuthorizationStatus.authorizedWhenInUse) {
              wifiName = await _connectivity.getWifiName();
            } else {
              await _connectivity.requestLocationServiceAuthorization();
              wifiName = await _connectivity.getWifiName();
            }
          } else {
            wifiName = await _connectivity.getWifiName().catchError((_, stack) {
              return null;
            });
          }
        } on PlatformException {
          wifiName = null;
        }
        result['name'] = wifiName;

        try {
          wifiIP = await _connectivity.getWifiIP();
        } on PlatformException {
          wifiIP = null;
        }
        result['ip'] = wifiIP;
        break;
      default:
        break;
    }
    return result;
  }
}
