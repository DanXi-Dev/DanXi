/*
 *     Copyright (C) 2024  DanXi-Dev
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

import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dan_xi/util/webvpn_proxy.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart';

/// [HttpFileService], but backed by dio and supports webvpn.
class HttpFileServiceWithWebvpn extends FileService {
  final Dio _dio = DioUtils.newDioWithProxy();

  HttpFileServiceWithWebvpn() {
    _dio.interceptors.add(CookieManager(WebvpnProxy.webvpnCookieJar));
  }

  @override
  Future<FileServiceResponse> get(String url,
      {Map<String, String>? headers}) async {
    final options = RequestOptions(
        path: url,
        method: "GET",
        headers: headers,
        responseType: ResponseType.bytes);
    final res = await WebvpnProxy.requestWithProxy(_dio, options);
    final byteStream = ByteStream.fromBytes(res.data!);

    return HttpGetResponse(StreamedResponse(byteStream, res.statusCode!,
        contentLength:
            int.tryParse(res.headers[Headers.contentLengthHeader]?.first ?? ""),
        headers: headers ?? {},
        isRedirect: res.isRedirect));
  }
}

/// Exactly the same as [DefaultCacheManager], but backed by dio.
/// This means that it supports proxy and can fallback to WebVPN.
class DefaultCacheManagerWithWebvpn extends CacheManager
    with ImageCacheManager {
  static const key = DefaultCacheManager.key;

  static final DefaultCacheManagerWithWebvpn _instance =
      DefaultCacheManagerWithWebvpn._();

  factory DefaultCacheManagerWithWebvpn() {
    return _instance;
  }

  DefaultCacheManagerWithWebvpn._()
      : super(Config(key, fileService: HttpFileServiceWithWebvpn()));
}
