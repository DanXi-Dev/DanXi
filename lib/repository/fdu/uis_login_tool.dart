// ignore_for_file: deprecated_member_use

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
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/independent_cookie_jar.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dan_xi/util/io/queued_interceptor.dart';
import 'package:dan_xi/util/io/user_agent_interceptor.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/retrier.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:dio_log/dio_log.dart';
import 'package:mutex/mutex.dart';

class UISLoginTool {
  static const String CAPTCHA_CODE_NEEDED = "请输入验证码";
  static const String CREDENTIALS_INVALID = "密码有误";
  static const String WEAK_PASSWORD = "弱密码提示";
  static const String UNDER_MAINTENANCE = "网络维护中 | Under Maintenance";
  static final Map<IndependentCookieJar, Mutex> _mutexMap = {};

  static Future<E> tryAsyncWithAuth<E>(
          Dio dio,
          String serviceUrl,
          IndependentCookieJar jar,
          PersonInfo? info,
          Future<E> Function() function,
          {int retryTimes = 1}) =>
      Retrier.tryAsyncWithFix(() async {
        await throwIfNotLogin(serviceUrl, jar);
        return function();
      }, (_) => UISLoginTool.fixByLoginUIS(dio, serviceUrl, jar, info, true),
          retryTimes: retryTimes);

  static Future<void> throwIfNotLogin(
      String serviceUrl, IndependentCookieJar jar) async {
    if ((await jar.loadForRequest(Uri.tryParse(serviceUrl)!)).isEmpty) {
      throw NotLoginError("You have not logged in your UIS.");
    }
  }

  /// Log in Fudan UIS system and return the response.
  ///
  /// Warning: if having logged in, return null.
  static Future<void> fixByLoginUIS(
      Dio dio, String serviceUrl, IndependentCookieJar jar, PersonInfo? info,
      [bool forceReLogin = false]) async {
    await loginUIS(dio, serviceUrl, jar, info, forceReLogin);
  }

  /// Log in Fudan UIS system and return the response.
  ///
  /// Warning: if it has logged in or it's logging in, return null.
  static Future<Response<dynamic>?> loginUIS(
      Dio dio, String serviceUrl, IndependentCookieJar jar, PersonInfo? info,
      [bool forceRelogin = false]) async {
    _mutexMap.putIfAbsent(jar, () => Mutex());
    await _mutexMap[jar]!.acquire();
    dio.interceptors.requestLock.lock();
    Response<dynamic>? result =
        await _loginUIS(dio, serviceUrl, jar, info, forceRelogin)
            .whenComplete(() {
      if (dio.interceptors.requestLock.locked) {
        dio.interceptors.requestLock.unlock();
      }
      _mutexMap[jar]!.release();
    });
    return result;
  }

  static Future<Response<dynamic>?> _loginUIS(
      Dio dio, String serviceUrl, IndependentCookieJar jar, PersonInfo? info,
      [bool forceRelogin = false]) async {
    // Create a temporary dio for logging in.
    Dio workDio = Dio();
    workDio.options = BaseOptions(
        receiveDataWhenStatusError: true,
        connectTimeout: 5000,
        receiveTimeout: 5000,
        sendTimeout: 5000);
    IndependentCookieJar workJar = IndependentCookieJar.createFrom(jar);
    workDio.interceptors.add(LimitedQueuedInterceptor.getInstance());
    workDio.interceptors.add(UserAgentInterceptor(
        userAgent: SettingsProvider.getInstance().customUserAgent));
    workDio.interceptors.add(CookieManager(workJar));
    workDio.interceptors.add(DioLogInterceptor());

    // If we has logged in, return null.
    if (!forceRelogin &&
        (await workJar.loadForRequest(Uri.tryParse(serviceUrl)!)).isNotEmpty) {
      Response<dynamic> res = await workDio.head(serviceUrl,
          options: DioUtils.NON_REDIRECT_OPTION_WITH_FORM_TYPE);
      if (res.statusCode == 302 &&
          !res.headers.map.containsKey('set-cookie') &&
          !res.headers.value("location")!.startsWith(Constant.UIS_URL)) {
        return null;
      }
    }

    // Remove old cookies.
    workJar.deleteAll();
    Map<String?, String?> data = {};
    Response<String> res = await workDio.get(serviceUrl);
    BeautifulSoup(res.data!).findAll("input").forEach((element) {
      if (element.attributes['type'] != "button") {
        data[element.attributes['name']] = element.attributes['value'];
      }
    });
    data['username'] = info!.id;
    data["password"] = info.password;
    res = await workDio.post(serviceUrl,
        data: data.encodeMap(),
        options: DioUtils.NON_REDIRECT_OPTION_WITH_FORM_TYPE);
    final Response<dynamic> response =
        await DioUtils.processRedirect(workDio, res);
    if (response.data.toString().contains(CREDENTIALS_INVALID)) {
      CredentialsInvalidException().fire();
      throw CredentialsInvalidException();
    } else if (response.data.toString().contains(CAPTCHA_CODE_NEEDED)) {
      // Notify [main.dart] to show up a dialog to guide users to log in manually.
      CaptchaNeededException().fire();
      throw CaptchaNeededException();
    } else if (response.data.toString().contains(UNDER_MAINTENANCE)) {
      throw NetworkMaintenanceException();
    } else if (response.data.toString().contains(WEAK_PASSWORD)) {
      throw GeneralLoginFailedException();
    }

    jar.cloneFrom(workJar);
    dio.interceptors.requestLock.unlock();
    return response;
  }
}

class CaptchaNeededException implements Exception {}

class CredentialsInvalidException implements Exception {}

class NetworkMaintenanceException implements Exception {}

class GeneralLoginFailedException implements Exception {}
