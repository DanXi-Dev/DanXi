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

class UserAgentInterceptor extends Interceptor {
  static const String EXTRA_USER_AGENT_SET = "user_agent_set";

  String? userAgent;
  bool important;

  UserAgentInterceptor({this.userAgent, this.important = true});

  static String? get defaultUsedUserAgent =>
      StateProvider.onlineUserAgent ??
      SettingsProvider.getInstance().customUserAgent ??
      Constant.DEFAULT_USER_AGENT;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!PlatformX.isWeb) {
      userAgent ??= defaultUsedUserAgent;
      if (important || options.extra[EXTRA_USER_AGENT_SET] != true) {
        options.extra[EXTRA_USER_AGENT_SET] = true;
        options.headers[HttpHeaders.userAgentHeader] = userAgent;
      }
    }
    return handler.next(options);
  }
}
