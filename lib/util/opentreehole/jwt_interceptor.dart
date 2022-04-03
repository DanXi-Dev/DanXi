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

import 'package:dan_xi/model/opentreehole/jwt.dart';
import 'package:dan_xi/provider/fduhole_provider.dart';
import 'package:dio/dio.dart';

/// An interceptor that refresh the jwt token automatically.
///
/// Also see:
/// * [JWToken]
/// * [FDUHoleProvider]
class JWTInterceptor extends QueuedInterceptor {
  final Dio _dio = Dio();
  final String refreshUrl;
  final Function tokenGetter;
  final Function? tokenSetter;

  JWTInterceptor(this.refreshUrl, this.tokenGetter, [this.tokenSetter]);

  static _rewriteRequestOptionsWithToken(
      RequestOptions options, JWToken token) {
    Map<String, dynamic> newHeader = options.headers.map((key, value) =>
        MapEntry(
            key, key.toLowerCase() == "authorization" ? token.access : value));
    return options.copyWith(headers: newHeader);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == HttpStatus.unauthorized) {
      JWToken? currentToken = tokenGetter.call();
      if (currentToken != null && currentToken.refresh != null) {
        RequestOptions options = RequestOptions(
            path: refreshUrl,
            method: "POST",
            data: {"token": currentToken.refresh}); //TODO
        try {
          Response<Map<String, dynamic>> response = await _dio.fetch(options);
          JWToken newToken = JWToken.fromJson(response.data!);
          tokenSetter?.call(newToken);
          handler.resolve(await _dio.fetch(
              _rewriteRequestOptionsWithToken(err.requestOptions, newToken)));
        } catch (e) {
          if (e is DioError) {
            handler.reject(e);
          } else {
            handler.reject(DioError(requestOptions: options, error: e));
          }
        }
        return;
      }
    }
    handler.next(err);
  }
}
