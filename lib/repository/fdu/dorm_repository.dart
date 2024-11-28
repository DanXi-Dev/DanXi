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

import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/uis_login_tool.dart';
import 'package:dio/dio.dart';

/// To implement a repository, you should extend BaseRepositoryWithDio.
class FudanDormRepository extends BaseRepositoryWithDio {
  /// You can get the url from the UIS login page.
  static const String _LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Fzlapp.fudan.edu.cn%2Fa_fudanzlapp%2Fapi%2Fsso%2Findex%3Fredirect%3Dhttps%253A%252F%252Fzlapp.fudan.edu.cn%252Ffudanelec%252Fwap%252Fdefault%252Finfo%26from%3Dwap";

  /// A repository acts as a spider. This is the page containing the target data.
  static const String electricityUrl =
      'https://zlapp.fudan.edu.cn/fudanelec/wap/default/info';

  /// Singleton pattern.
  FudanDormRepository._();
  static final _instance = FudanDormRepository._();
  factory FudanDormRepository.getInstance() => _instance;

  /// For every network request, you should write a private `_xxx` and a public
  /// `xxx`. `_xxx` is the actual implementation, and the `xxx` wraps it with
  /// [Retrier] and/or [UISLoginTool.tryAsyncWithAuth].
  Future<ElectricityItem?> loadElectricityInfo(PersonInfo? info) {
    return UISLoginTool.tryAsyncWithAuth(
        dio, _LOGIN_URL, cookieJar!, info, () => _loadElectricityInfo());
  }

  /// Show your great talent here.
  Future<ElectricityItem?> _loadElectricityInfo() async {
    final Response<Map<String, dynamic>> r = await dio.get(electricityUrl);
    final Map<String, dynamic> json = r.data!;

    final data = json['d'];
    // An example of data:
    // {xq: (string, 校区), ting: (bool), xqid: (int, 校区), roomid: (int), tingid: null, realname: (string), ssmc: (string, 楼号), fjmc: (maybe int, 房间号), fj_update_time: 2021-08-24 00:00:00, fj_used: (double), fj_all: (double), fj_surplus: (double), t_update_time: (double), t_used: (double), t_all: (double), t_surplus: (double)}

    return ElectricityItem(
        data['fj_surplus'].toString(),
        data['fj_used'].toString(),
        data['fj_update_time'].toString(),
        data['roomid'].toString(),
        data['xq'].toString() +
            data['ssmc'].toString() +
            data['fjmc'].toString());
  }

  @override
  String get linkHost => "fudan.edu.cn";
}

/// This class represents the electricity info of a dorm. It's an interface for
/// the UI to use.
class ElectricityItem {
  final String available;
  final String used;
  final String updateTime;
  final String roomId;
  final String dormName;

  ElectricityItem(
      this.available, this.used, this.updateTime, this.roomId, this.dormName);

  @override
  String toString() {
    return 'ElectricityItem{available: $available, used: $used, updateTime: $updateTime, roomId: $roomId, dormName: $dormName}';
  }
}
