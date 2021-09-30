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

import 'package:beautifulsoup/beautifulsoup.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dio/dio.dart';

class PgyerRepository {
  static const String _UPDATE_API_URL = "https://www.pgyer.com/danxi";
  Dio _dio = new Dio();

  PgyerRepository._();

  static final _instance = PgyerRepository._();

  factory PgyerRepository.getInstance() => _instance;

  Future<UpdateInfo> checkVersion() async {
    Response res = await _dio.get(_UPDATE_API_URL);
    var soup = Beautifulsoup(res.data.toString());
    var element = soup.find(id: '.breadcrumb>li');
    var versionName = element.text.trim().between("版本：", "(build ").trim();
    element = soup.find(id: '.update-description');
    return UpdateInfo(versionName, element.text.trim());
  }
}

class UpdateInfo {
  final String latestVersion;
  final String changeLog;

  @override
  String toString() {
    return 'UpdateInfo{latestVersion: $latestVersion, changeLog: $changeLog}';
  }

  UpdateInfo(this.latestVersion, this.changeLog);

  bool isAfter(int major, int minor, int patch) {
    List<int> versions =
        latestVersion.split(".").map((e) => int.tryParse(e)).toList();
    if (versions[0] > major)
      return true;
    else if (versions[0] < major) return false;

    if (versions[1] > minor)
      return true;
    else if (versions[1] < minor) return false;

    if (versions[2] > patch) return true;

    return false;
  }
}
