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

import 'package:dio/dio.dart';

/// Useful utils when processing network requests by dio.
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

  static Future<Response> processRedirect(Dio dio, Response response) async {
    //Prevent the redirect being processed by HttpClient, with the 302 response caught manually.
    if (response.statusCode == 302 &&
        response.headers['location'] != null &&
        response.headers['location']!.length > 0) {
      String location = response.headers['location']![0];
      if (location.isEmpty) return response;
      if (!Uri.parse(location).isAbsolute) {
        location = response.requestOptions.uri.origin + '/' + location;
      }
      return processRedirect(dio,
          await dio.get(location, options: NON_REDIRECT_OPTION_WITH_FORM_TYPE));
    } else {
      return response;
    }
  }
}
