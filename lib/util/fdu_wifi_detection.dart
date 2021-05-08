/*
 *     Copyright (C) 2021  DanXi-Dev
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

class FDUWiFiConverter {
  static const WIFI_MAP = {
    "iFudan.stu": "宿舍区公共开放付费热点",
    "iFudan.stu.1x": "宿舍区公共加密付费热点",
    "iFudan": "教学区公共开放热点",
    "iFudan.1x": "教学区公共加密热点",
    "iFudanNG.1x": "教学区公共(下一代)加密热点",
    "iSJTU.stu": "405寝室热点",
    "eduroam": "Eduroam 全球漫游服务热点"
  };

  static String recognizeWiFi(String wifiName) {
    if (wifiName == null || wifiName.length == 0) {
      return "未知热点";
    } else {
      return WIFI_MAP.containsKey(wifiName)
          ? WIFI_MAP[wifiName]
          : "$wifiName (未识别热点)";
    }
  }
}
