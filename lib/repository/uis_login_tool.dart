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

import 'package:beautifulsoup/beautifulsoup.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/inpersistent_cookie_manager.dart';
import 'package:dan_xi/util/dio_utils.dart';
import 'package:dio/dio.dart';

class UISLoginTool {
  static const String CAPTCHA_CODE_NEEDED = "请输入验证码";

  static Future<Response> loginUIS(Dio dio, String serviceUrl,
      NonpersistentCookieJar jar, PersonInfo info) async {
    ArgumentError.checkNotNull(info);
    ArgumentError.checkNotNull(jar);
    ArgumentError.checkNotNull(dio);
    ArgumentError.checkNotNull(serviceUrl);
    jar.deleteAll();
    var data = {};
    var res = await dio.get(serviceUrl);
    Beautifulsoup(res.data.toString()).find_all("input").forEach((element) {
      if (element.attributes['type'] != "button") {
        data[element.attributes['name']] = element.attributes['value'];
      }
    });
    data['username'] = info.id;
    data["password"] = info.password;
    res = await dio.post(serviceUrl,
        data: data.encodeMap(),
        options: DioUtils.NON_REDIRECT_OPTION_WITH_FORM_TYPE);
    Response response = await DioUtils.processRedirect(dio, res);
    if (response.data.toString().contains(CAPTCHA_CODE_NEEDED)) {
      CaptchaNeededException().fire();
    }
    return response;
  }
}

class CaptchaNeededException implements Exception {}
