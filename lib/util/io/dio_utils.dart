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

import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Useful utils when processing network requests with dio.
class DioUtils {
  // ignore: non_constant_identifier_names
  static get NON_REDIRECT_OPTION_WITH_FORM_TYPE {
    return Options(
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false,
        validateStatus: (status) {
          return status! < 400;
        });
  }

  // ignore: non_constant_identifier_names
  static NON_REDIRECT_OPTION_WITH_FORM_TYPE_AND_HEADER(
          Map<String, dynamic> header) =>
      Options(
          headers: header,
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) {
            return status! < 400;
          });

  /// Get the location to which the [response] is redirected.
  ///
  /// If the response is not a valid redirect response, return null.
  ///
  /// It doesn't check whether the "location" is empty, relative, etc.
  /// You should do it yourself.
  ///
  /// ## Formality
  /// This method is a bit different from the original one (see [HttpClientResponse.isRedirect] in `http_impl.dart`),
  /// which considers the request HTTP method and excludes some invalid combinations (e.g., POST can only be redirected by 303).
  /// But in practice, we don't need to (and cannot) be so strict. Some badly designed servers may return 302 for POST requests.
  static String? getRedirectLocation(Response<dynamic> response) {
    final statusCode = response.statusCode;
    bool isRedirect = statusCode == HttpStatus.movedPermanently ||
        statusCode == HttpStatus.permanentRedirect ||
        statusCode == HttpStatus.found ||
        statusCode == HttpStatus.seeOther ||
        statusCode == HttpStatus.temporaryRedirect;
    if (isRedirect) {
      return response.headers['location']?[0];
    }
    return null;
  }

  /// Process the redirect response manually and return the final response.
  ///
  /// What makes this method necessary is that the default behavior of [Dio] is
  /// NOT to trigger any interceptors when sending redirected requests.
  /// Thus, some necessary headers (e.g. cookies) will be missing from the second
  /// request and on.
  static Future<Response<dynamic>> processRedirect(
      Dio dio, Response<dynamic> response) async {
    // Prevent the redirect being processed by HttpClient, with the 302 response caught manually.
    String? location = getRedirectLocation(response);
    if (location != null) {
      if (location.isEmpty) return response;
      if (!Uri.parse(location).isAbsolute) {
        location = '${response.requestOptions.uri.origin}$location';
      }
      return processRedirect(dio,
          await dio.get(location, options: NON_REDIRECT_OPTION_WITH_FORM_TYPE));
    } else {
      return response;
    }
  }

  /// Get the error message from the response.
  ///
  /// See also:
  ///
  /// * [ErrorPageWidget]
  static String? guessErrorMessageFromResponse(Response<dynamic>? response) {
    if (response?.data is Map<String, dynamic>) {
      if (response?.data['message'] != null) {
        return response?.data['message'].toString();
      }
    }
    return response?.data.toString();
  }

  /// Set the [proxy] for the [dio] instance.
  ///
  /// If [proxy] is null, the proxy will be set to DIRECT (i.e. no proxy).
  ///
  /// If the platform is web, this method will return false and do nothing.
  static bool setProxy(Dio dio, String? proxy) {
    if (PlatformX.isWeb) return false; // Web does not support proxy

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()
        ..findProxy = (uri) => proxy != null ? "PROXY $proxy" : "DIRECT",
    );
    return true;
  }

  /// Create a new [Dio] instance with the proxy set to the one in [SettingsProvider].
  static Dio newDioWithProxy([BaseOptions? options]) {
    Dio dio = Dio(options);
    setProxy(dio, SettingsProvider.getInstance().proxy);
    return dio;
  }

  /// Fetch with the [options], but when T is JSON-like and the response is not,
  /// throw a [DioException] WITH the response data.
  /// (The original [fetch] will throw a [DioException] WITHOUT the response data when [FormatException] occurs.)
  static Future<Response<T>> fetchWithJsonError<T>(
      Dio dio, RequestOptions options) async {
    if (T == dynamic ||
        options.responseType == ResponseType.bytes ||
        options.responseType == ResponseType.stream) {
      // If T is dynamic, or the caller wants bytes or stream, just call the original fetch.
      // Because we are going to parse the response data as [String] below!
      return await dio.fetch(options) as Response<T>;
    }

    Response<String> response = await dio.fetch(options);
    if (T == String) {
      return response as Response<T>;
    } else {
      try {
        dynamic transformedResponseData = await dio.transformer
            .transformResponse(
                options.copyWith(responseType: ResponseType.json),
                ResponseBody.fromString(response.data!, response.statusCode!,
                    headers: response.headers.map,
                    statusMessage: response.statusMessage));
        return Response<T>(
          data: transformedResponseData,
          requestOptions: response.requestOptions,
          statusCode: response.statusCode,
          statusMessage: response.statusMessage,
          isRedirect: response.isRedirect,
          redirects: response.redirects,
          headers: response.headers,
        );
      } catch (e) {
        throw DioException(
          requestOptions: options,
          response: response,
          error: e,
        );
      }
    }
  }
}
