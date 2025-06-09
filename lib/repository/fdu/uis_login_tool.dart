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
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/forum/forum_repository.dart';
import 'package:dan_xi/repository/cookie/independent_cookie_jar.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dan_xi/util/io/queued_interceptor.dart';
import 'package:dan_xi/util/io/user_agent_interceptor.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/retrier.dart';
import 'package:dio/dio.dart';
import 'package:dio5_log/dio_log.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/painting.dart';
import 'package:mutex/mutex.dart';

class UISLoginTool {
  /// Error patterns from UIS.
  static const String CAPTCHA_CODE_NEEDED = "请输入验证码";
  static const String CREDENTIALS_INVALID = "密码有误";
  static const String WEAK_PASSWORD = "弱密码提示";
  static const String UNDER_MAINTENANCE = "网络维护中 | Under Maintenance";

  static const String ID_HOST = "id.fudan.edu.cn";

  /// RWLocks to prevent multiple login requests happening at the same time.
  static final Map<IndependentCookieJar, ReadWriteMutex> _lockMap = {};

  /// Track the epoch of the last login to prevent multiple sequential login requests.
  /// The epoch should be updated after each change of the cookie jar.
  static final Map<IndependentCookieJar, Accumulator> _epochMap = {};

  /// The main function to request a service behind the UIS login system.
  ///
  /// It will request the service with [function].
  /// If failed, it will try to log in UIS at [serviceUrl] with HTTP client [dio] and credentials [info].
  /// If it logs in successfully, it will put new cookies into [jar] and retry the [function].
  /// The steps above will be repeated for [retryTimes] times.
  ///
  /// If [function] throws an error and [isFatalError] is provided, the error will be checked with [isFatalError].
  /// If it is, stop retrying and throw the error immediately.
  ///
  /// This function is coroutine-safe and will elegantly handle multiple requests at the same time.
  static Future<E> tryAsyncWithAuth<E>(Dio dio, String serviceUrl,
      IndependentCookieJar jar, PersonInfo? info, Future<E> Function() function,
      {int retryTimes = 1, bool Function(dynamic error)? isFatalError}) {
    ReadWriteMutex lock = _lockMap.putIfAbsent(jar, () => ReadWriteMutex());
    Accumulator epoch = _epochMap.putIfAbsent(jar, () => Accumulator());
    int? currentEpoch;
    final serviceUri = Uri.tryParse(serviceUrl)!;
    return Retrier.tryAsyncWithFix(
      () {
        return lock.protectRead(() async {
          currentEpoch = epoch.value;
          if ((await jar.loadForRequest(serviceUri)).isEmpty) {
            throw NotLoginError("Cannot find cookies for $serviceUrl");
          }
          return await function();
        });
      },
      (_) async {
        await lock.protectWrite(() async {
          if (currentEpoch != epoch.value) {
            // Someone has tried to log in before us! We should not log in again.
            return null;
          }
          await _loginUIS(dio, serviceUrl, jar, info);
          epoch.increment(1);
        });
      },
      retryTimes: retryTimes,
      isFatalError: isFatalError,
      // If there is an explicit reason for UIS login failure, we should not retry anymore.
      isFatalRetryError: (e) =>
          e is CredentialsInvalidException ||
          e is CaptchaNeededException ||
          e is NetworkMaintenanceException ||
          e is WeakPasswordException,
    );
  }

  /// Log in Fudan UIS system and return the response.
  ///
  /// Warning: if it has logged in or it's logging in, return null.
  static Future<Response<dynamic>?> loginUIS(Dio dio, String serviceUrl,
      IndependentCookieJar jar, PersonInfo? info) async {
    ReadWriteMutex lock = _lockMap.putIfAbsent(jar, () => ReadWriteMutex());
    Accumulator epoch = _epochMap.putIfAbsent(jar, () => Accumulator());
    return await lock.protectWrite(() async {
      final result = await _loginUIS(dio, serviceUrl, jar, info);
      epoch.increment(1);
      return result;
    });
  }

  static Future<Response<dynamic>?> _loginUIS(Dio dio, String serviceUrl,
      IndependentCookieJar jar, PersonInfo? info) async {
    // Create a temporary dio for logging in.
    Dio workDio = DioUtils.newDioWithProxy();
    workDio.options = BaseOptions(
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5));
    IndependentCookieJar workJar = IndependentCookieJar.createFrom(jar);
    workDio.interceptors.add(LimitedQueuedInterceptor.getInstance());
    workDio.interceptors.add(UserAgentInterceptor(
        userAgent: SettingsProvider.getInstance().customUserAgent));
    workDio.interceptors.add(CookieManager(workJar));
    workDio.interceptors.add(DioLogInterceptor());

    // fixme: workaround by deleting `CASTGC` cookie before requesting the UIS page
    // See https://github.com/DanXi-Dev/DanXi/issues/491 for details.
    workJar.deleteCookiesByName("CASTGC");
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
      throw WeakPasswordException();
    }

    jar.cloneFrom(workJar);
    return response;
  }

  static Future<String?> getAuthenticateTicket(
      Dio dio,
      IndependentCookieJar jar,
      PersonInfo? info,
      String requestURL,
      String uisLoginURL) async {
    Response<dynamic>? res = await dio.get(requestURL,
        options: DioUtils.NON_REDIRECT_OPTION_WITH_FORM_TYPE);
    if (DioUtils.getRedirectLocation(res) != null) {
      // if we are redirected to UIS, we need to login to UIS first
      await DioUtils.processRedirect(dio, res);
      res = await UISLoginTool.loginUIS(dio, uisLoginURL, jar, info);
      if (res == null) {
        throw AuthenticationFailedException();
      }
    }
    return _retrieveTicket(res);
  }

  static Future<void> authenticateWithTicket(
      Dio dio,
      IndependentCookieJar jar,
      PersonInfo? info,
      String requestURL,
      String uisLoginURL,
      String loginURL,
      Map<String, dynamic> queryParams) async {
    final ticket =
        await getAuthenticateTicket(dio, jar, info, requestURL, uisLoginURL);

    queryParams['ticket'] = ticket;

    final response = await dio.get(loginURL,
        queryParameters: queryParams,
        options: DioUtils.NON_REDIRECT_OPTION_WITH_FORM_TYPE);
    await DioUtils.processRedirect(dio, response);
  }

  static String? _retrieveTicket(Response<dynamic> response) {
    // Check if the URL host matches the expected value
    if (response.realUri.host != ID_HOST) {
      return null;
    }

    BeautifulSoup soup = BeautifulSoup(response.data!);

    final element = soup.find('', selector: '#ticket');
    return element?.attributes['value'];
  }
}

class CaptchaNeededException implements Exception {}

class CredentialsInvalidException implements Exception {}

class NetworkMaintenanceException implements Exception {}

class WeakPasswordException implements Exception {}

class AuthenticationFailedException implements Exception {}
