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

import 'package:dan_xi/common/pubspec.yaml.g.dart' as pubspec;
import 'package:dio/dio.dart';

class UserAgentInterceptor extends Interceptor {
  String? userAgent;

  UserAgentInterceptor({this.userAgent});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    userAgent ??= "DanXi/${pubspec.major}.${pubspec.minor}.${pubspec.patch}";
    options.headers[HttpHeaders.userAgentHeader] = userAgent;
    return handler.next(options);
  }
}
