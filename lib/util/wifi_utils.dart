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

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';

class WiFiUtils {
  static NetworkInfo _networkInfo = NetworkInfo();
  static Connectivity _connectivity = Connectivity();

  static Connectivity getConnectivity() {
    return _connectivity;
  }

  static Future<Map> getWiFiInfo(ConnectivityResult connectivityResult) async {
    Map result = {};
    switch (connectivityResult) {
      case ConnectivityResult.wifi:
        String wifiName, wifiIP;

        try {
          if (!kIsWeb && Platform.isIOS) {
            LocationAuthorizationStatus status =
                await _networkInfo.getLocationServiceAuthorization();
            if (status == LocationAuthorizationStatus.notDetermined) {
              status = await _networkInfo.requestLocationServiceAuthorization();
            }
            if (status == LocationAuthorizationStatus.authorizedAlways ||
                status == LocationAuthorizationStatus.authorizedWhenInUse) {
              wifiName = await _networkInfo.getWifiName();
            } else {
              await _networkInfo.requestLocationServiceAuthorization();
              wifiName = await _networkInfo.getWifiName();
            }
          } else {
            wifiName = await _networkInfo.getWifiName().catchError((_, stack) {
              return null;
            });
          }
        } on PlatformException {
          wifiName = null;
        }
        result['name'] = wifiName;

        try {
          wifiIP = await _networkInfo.getWifiIP();
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
