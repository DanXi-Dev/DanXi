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

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/uis_login_tool.dart';

class QRCodeRepository extends BaseRepositoryWithDio {
  static const String LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Fworkflow1.fudan.edu.cn%2Fsite%2Flogin%2Fcas-login%3Fredirect_url%3Dhttps%253A%252F%252Fworkflow1.fudan.edu.cn%252Fopen%252Fconnection%252Findex%253Fapp_id%253Dc5gI0Ro%2526state%253D%2526redirect_url%253Dhttps%253A%252F%252Fecard.fudan.edu.cn%252Fepay%252Fwxpage%252Ffudan%252Fzfm%252Fqrcode%253Furl%253D0";
  static const String QR_URL =
      "https://ecard.fudan.edu.cn/epay/wxpage/fudan/zfm/qrcode";

  QRCodeRepository._();

  static final _instance = QRCodeRepository._();

  factory QRCodeRepository.getInstance() => _instance;

  Future<String?> getQRCode(PersonInfo? info) => UISLoginTool.tryAsyncWithAuth(
      dio!, LOGIN_URL, cookieJar!, info, () => _getQRCode());

  Future<String?> _getQRCode() async {
    final res = await dio!.get(QR_URL);
    BeautifulSoup soup = BeautifulSoup(res.data.toString());
    return soup.find("#myText")!.attributes['value'];
  }

  @override
  String get linkHost => "workflow1.fudan.edu.cn";
}
