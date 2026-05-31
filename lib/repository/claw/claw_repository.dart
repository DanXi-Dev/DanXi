/*
 *     Copyright (C) 2025  DanXi-Dev
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

import 'package:dan_xi/model/claw/claw_message.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dio/dio.dart';
import 'package:dio5_log/interceptor/diox_log_interceptor.dart';

class ClawRepository {
  static const String _baseUrl = 'http://127.0.0.1:8000/api/claw';

  final Dio _dio;

  static final _instance = ClawRepository._();

  factory ClawRepository.getInstance() => _instance;

  ClawRepository._() : _dio = DioUtils.newDioWithProxy(track: true) {
    _dio.options = BaseOptions(
      receiveDataWhenStatusError: true,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 5),
    );
    DioLogInterceptor.enablePrintLog = true;
    _dio.interceptors.add(DioLogInterceptor());
  }

  Map<String, dynamic> get _headers {
    return {'Authorization': 'Bearer <ACCESS_TOKEN>'}; // TODO: Fill in it.
  }

  Future<List<ClawMessage>> getMessages({
    required int channelId,
    int offset = 0,
    String sort = 'desc',
    int size = 64,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '$_baseUrl/messages',
      queryParameters: {
        'channel_id': channelId,
        'offset': offset,
        'sort': sort,
        'size': size,
      },
      options: Options(headers: _headers),
    );

    return response.data
            ?.map((e) => ClawMessage.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
  }
}
