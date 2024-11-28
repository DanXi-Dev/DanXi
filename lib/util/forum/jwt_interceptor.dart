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

import 'package:dan_xi/model/forum/jwt.dart';
import 'package:dan_xi/provider/forum_provider.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dan_xi/util/webvpn_proxy.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/cupertino.dart';

/// An interceptor that refresh the jwt token automatically.
///
/// Also see:
/// * [JWToken]
/// * [ForumProvider]
class JWTInterceptor extends QueuedInterceptor {
  final Dio _dio = DioUtils.newDioWithProxy();
  final String refreshUrl;
  final Function tokenGetter;
  final Function? tokenSetter;

  JWTInterceptor(this.refreshUrl, this.tokenGetter, [this.tokenSetter]) {
    /// Add global cookies, since to make [_dio] compatible with webvpn
    _dio.interceptors.add(CookieManager(WebvpnProxy.webvpnCookieJar));
  }

  static _rewriteRequestOptionsWithToken(
      RequestOptions options, JWToken token) {
    Map<String, dynamic> newHeader =
        options.headers.map((key, value) => MapEntry(key, value));
    newHeader['Authorization'] = "Bearer ${token.access!}";
    return options.copyWith(headers: newHeader);
  }

  void _throwOrBuildDioError(
      ErrorInterceptorHandler handler, RequestOptions options, dynamic error) {
    if (error is DioException) {
      handler.reject(error);
    } else {
      handler.reject(DioException(requestOptions: options, error: error));
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    debugPrint("Huston, we have troubles on ${err.response?.realUri}");

    if (err.response?.statusCode == HttpStatus.unauthorized) {
      JWToken? currentToken = tokenGetter.call();
      if (currentToken != null && currentToken.isValid) {
        RequestOptions options = RequestOptions(
            path: refreshUrl,
            method: "POST",
            headers: {"Authorization": "Bearer ${currentToken.refresh!}"});
        Response<Map<String, dynamic>> response;
        try {
          response = await WebvpnProxy.requestWithProxy(_dio, options);
        } catch (e) {
          if (e is DioException &&
              e.response?.statusCode == HttpStatus.unauthorized) {
            // Oh, we cannot get a token here! Maybe the refresh token we hold has gone invalid.
            // Clear old token, so the next request will definitely generate a [NotLoginError].
            tokenSetter?.call(null);
            handler.reject(e);
            return;
          }
          _throwOrBuildDioError(handler, options, e);
          return;
        }
        try {
          JWToken newToken = JWToken.fromJsonWithVerification(response.data!);
          tokenSetter?.call(newToken);
          handler.resolve(await _dio.fetch(
              _rewriteRequestOptionsWithToken(err.requestOptions, newToken)));
        } catch (e) {
          _throwOrBuildDioError(handler, options, e);
        }
        return;
      }
    }
    handler.next(err);
  }
}
