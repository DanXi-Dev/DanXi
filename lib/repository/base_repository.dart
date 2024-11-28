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

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/cookie/independent_cookie_jar.dart';
import 'package:dan_xi/repository/cookie/parallel_cookie_jars.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dan_xi/util/io/queued_interceptor.dart';
import 'package:dan_xi/util/io/user_agent_interceptor.dart';
import 'package:dan_xi/util/webvpn_proxy.dart';
import 'package:dio/dio.dart';
import 'package:dio5_log/interceptor/diox_log_interceptor.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';

abstract class BaseRepositoryWithDio {
  /// The host that the implementation works with.
  ///
  /// Should not contain scheme and/or path. e.g. fudan.edu.cn
  ///
  /// This is used to create a separate [Dio] instance (and [CookieJar]) for each host. That is to say,
  /// the cookies which can be shared among multiple domains should come with the same [linkHost].
  String get linkHost;

  /// Whether or not this repository may require webvpn to be accessed
  bool get isWebvpnApplicable => false;

  @protected
  Dio get dio {
    if (!_dios.containsKey(linkHost)) {
      _dios[linkHost] = DioUtils.newDioWithProxy();
      _dios[linkHost]!.options = BaseOptions(
          receiveDataWhenStatusError: true,
          connectTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
          sendTimeout: const Duration(seconds: 2));
      _dios[linkHost]!.interceptors.add(LimitedQueuedInterceptor.getInstance());
      _dios[linkHost]!.interceptors.add(UserAgentInterceptor(
          userAgent: SettingsProvider.getInstance().customUserAgent));
      if (isWebvpnApplicable && SettingsProvider.getInstance().useWebvpn) {
        _dios[linkHost]!.interceptors.add(CookieManager(
            ParallelCookieJars([cookieJar!, WebvpnProxy.webvpnCookieJar])));
      } else {
        _dios[linkHost]!.interceptors.add(CookieManager(cookieJar!));
      }
      DioLogInterceptor.enablePrintLog = false;
      _dios[linkHost]!.interceptors.add(DioLogInterceptor());
    }
    return _dios[linkHost]!;
  }

  @protected
  IndependentCookieJar? get cookieJar {
    if (!_cookieJars.containsKey(linkHost)) {
      _cookieJars[linkHost] = IndependentCookieJar();
    }
    return _cookieJars[linkHost];
  }

  static Future<void> clearAllCookies() async {
    for (IndependentCookieJar jar in _cookieJars.values) {
      await jar.deleteAll();
    }
  }

  static final Map<String, IndependentCookieJar> _cookieJars = {};
  static final Map<String, Dio> _dios = {};
}
