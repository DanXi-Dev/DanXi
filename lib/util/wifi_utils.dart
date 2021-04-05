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

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:network_info_plus/network_info_plus.dart';

class WiFiUtils {
  static NetworkInfo _networkInfo = NetworkInfo();
  static Connectivity _connectivity = Connectivity();

  static Connectivity getConnectivity() {
    return _connectivity;
  }

  static Future<Map> getWiFiInfo(ConnectivityResult connectivityResult) async {
    Map<String, String> result = {};
    switch (connectivityResult) {
      case ConnectivityResult.wifi:
        String wifiName, wifiIP;
        if (PlatformX.isIOS) {
          // Decide the status of location authorization
          LocationAuthorizationStatus status =
              await _networkInfo.getLocationServiceAuthorization();
          if (status == LocationAuthorizationStatus.notDetermined) {
            // Ask user to authorize
            status = await _networkInfo.requestLocationServiceAuthorization();
          }
          // Recheck again
          if (status == LocationAuthorizationStatus.authorizedAlways ||
              status == LocationAuthorizationStatus.authorizedWhenInUse) {
            wifiName = await _networkInfo.getWifiName();
          }
        } else {
          // On other devices, just try to obtain the wifi name
          wifiName = await _networkInfo.getWifiName();
        }

        result['name'] = wifiName;

        wifiIP = await _networkInfo.getWifiIP().catchError((_) => null);
        result['ip'] = wifiIP;
        break;
      default:
        break;
    }
    return result;
  }
}
