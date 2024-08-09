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

import 'dart:convert';
import 'dart:io';

import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/fdu/uis_login_tool.dart';
import 'package:dan_xi/repository/independent_cookie_jar.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dan_xi/util/io/queued_interceptor.dart';
import 'package:dan_xi/util/io/user_agent_interceptor.dart';
import 'package:dan_xi/util/webvpn_proxy.dart';
import 'package:dio/dio.dart';
import 'package:dio5_log/interceptor/diox_log_interceptor.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';

enum RequestType { Get, Post, Put, Delete, Head }

abstract class BaseRepositoryWithDio {
  static bool directLinkFailed = false;

  /// The host that the implementation works with.
  ///
  /// Should not contain scheme and/or path. e.g. www.jwc.fudan.edu.cn
  String get linkHost;

  @protected
  Dio get dio {
    if (!_dios.containsKey(linkHost)) {
      _dios[linkHost] = DioUtils.newDioWithProxy();
      _dios[linkHost]!.options = BaseOptions(
          receiveDataWhenStatusError: true,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10));
      _dios[linkHost]!.interceptors.add(LimitedQueuedInterceptor.getInstance());
      _dios[linkHost]!.interceptors.add(UserAgentInterceptor(
          userAgent: SettingsProvider.getInstance().customUserAgent));
      _dios[linkHost]!.interceptors.add(CookieManager(cookieJar!));
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

  Future<T> requestWithProxy<T>(Dio dio, String path, RequestType type,
      {Object? data, Options? options}) async {
    Future<Response<String>> Function(String) requestFunction = switch (type) {
      RequestType.Get => (p) => dio.get(p, data: data, options: options),
      RequestType.Post => (p) => dio.post(p, data: data, options: options),
      RequestType.Put => (p) => dio.put(p, data: data, options: options),
      RequestType.Delete => (p) => dio.delete(p, data: data, options: options),
      RequestType.Head => (p) => dio.head(p, data: data, options: options),
    };

    // Try direct link once
    if (!directLinkFailed || !SettingsProvider.getInstance().useProxy) {
      try {
        final response = await requestFunction(path);
        return jsonDecode(response.data!);
      } on DioException catch (e) {
        debugPrint(
            "Direct connextion failed, trying to connect through proxy: $e");
        // Throw immediately if `useProxy` is false
        if (!SettingsProvider.getInstance().useProxy) {
          rethrow;
        }
      } catch (e) {
        debugPrint("Connection failed with unknown exception: $e");
        rethrow;
      }
    }

    // Turn to the proxy
    directLinkFailed = true;
    String proxiedPath = WebvpnProxy.getProxiedUri(path);
    Response<dynamic> response = await requestFunction(proxiedPath);

    // If not redirected to login, then return
    if (!response.realUri
        .toString()
        .startsWith("https://webvpn.fudan.edu.cn/login")) {
      return jsonDecode(response.data!);
    }

    // Login and retry
    await UISLoginTool.loginUIS(dio, WebvpnProxy.WEBVPN_LOGIN_URL, cookieJar!,
        StateProvider.personInfo.value, false);
    try{
      response = await requestFunction(proxiedPath);
    }catch(err){
      debugPrint("DSHU: $err");
    }

    return jsonDecode(response.data!);
  }

  static final Map<String, IndependentCookieJar> _cookieJars = {};
  static final Map<String, Dio> _dios = {};
}
