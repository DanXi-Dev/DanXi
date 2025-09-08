/*
 *     Copyright (C) 2022  DanXi-Dev
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
import 'dart:io';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dio/dio.dart';
import 'package:dio_redirect_interceptor/dio_redirect_interceptor.dart';

/// An interceptor that sets the User-Agent header for HTTP requests.
///
/// If [userAgent] is not provided, it defaults to the value from
/// [StateProvider.onlineUserAgent], [SettingsProvider.customUserAgent],
/// or a predefined constant [Constant.DEFAULT_USER_AGENT].
///
/// The [important] flag determines whether to always set the User-Agent
/// header, even if it has already been set in the request options.
///
/// This interceptor considers [RedirectInterceptor] and ensures that
/// the User-Agent header is set once (and only once) per request.
class UserAgentInterceptor extends Interceptor {
  static const String EXTRA_USER_AGENT_SET_TIME = "user_agent_set";

  String? userAgent;
  bool important;

  UserAgentInterceptor({this.userAgent, this.important = true});

  static String? get defaultUsedUserAgent =>
      StateProvider.onlineUserAgent ??
      SettingsProvider.getInstance().customUserAgent ??
      Constant.DEFAULT_USER_AGENT;

  int getCurrentRedirectTime(RequestOptions options) {
    return options.extra[RedirectInterceptor.redirectCount] as int? ?? 1;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!PlatformX.isWeb) {
      userAgent ??= defaultUsedUserAgent;
      final curTime = getCurrentRedirectTime(options);
      if (important || options.extra[EXTRA_USER_AGENT_SET_TIME] != curTime) {
        options.extra[EXTRA_USER_AGENT_SET_TIME] = curTime;
        options.headers[HttpHeaders.userAgentHeader] = userAgent;
      }
    }
    return handler.next(options);
  }
}
