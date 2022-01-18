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

import 'package:dan_xi/repository/inpersistent_cookie_manager.dart';
import 'package:dan_xi/util/user_agent_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:dio_log/interceptor/dio_log_interceptor.dart';
import 'package:flutter/foundation.dart';

abstract class BaseRepositoryWithDio {
  /// The host that the implementation works with.
  ///
  /// Should not contain scheme and/or path. e.g. www.jwc.fudan.edu.cn
  String get linkHost;

  @protected
  Dio? get dio {
    if (!_dios.containsKey(linkHost)) {
      _dios[linkHost] = Dio();
      _dios[linkHost]!.options = BaseOptions(
          receiveDataWhenStatusError: true,
          connectTimeout: 10000,
          receiveTimeout: 10000,
          sendTimeout: 10000);

      _dios[linkHost]!.interceptors.add(CookieManager(cookieJar!));
      _dios[linkHost]!.interceptors.add(DioLogInterceptor());
      _dios[linkHost]!.interceptors.add(UserAgentInterceptor());
    }
    return _dios[linkHost];
  }

  @protected
  NonpersistentCookieJar? get cookieJar {
    if (!_cookieJars.containsKey(linkHost)) {
      _cookieJars[linkHost] = NonpersistentCookieJar();
    }
    return _cookieJars[linkHost];
  }

  static Future<void> clearAllCookies() async {
    for (NonpersistentCookieJar jar in _cookieJars.values) {
      await jar.deleteAll();
    }
  }

  static final Map<String, NonpersistentCookieJar> _cookieJars = {};
  static final Map<String, Dio> _dios = {};
}
