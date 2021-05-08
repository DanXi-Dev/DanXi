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

import 'dart:convert';

import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/uis_login_tool.dart';
import 'package:dan_xi/util/cache.dart';
import 'package:dan_xi/util/dio_utils.dart';
import 'package:dan_xi/util/retryer.dart';
import 'package:intl/intl.dart';

class FudanDailyRepository extends BaseRepositoryWithDio {
  dynamic _historyData;

  static const String LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Fzlapp.fudan.edu.cn%2Fa_fudanzlapp%2Fapi%2Fsso%2Findex%3Fredirect%3Dhttps%253A%252F%252Fzlapp.fudan.edu.cn%252Fsite%252Fncov%252FfudanDaily%253Ffrom%253Dhistory%26from%3Dwap";
  static const String SAVE_URL =
      "https://zlapp.fudan.edu.cn/ncov/wap/fudan/save";
  static const String GET_INFO_URL =
      "https://zlapp.fudan.edu.cn/ncov/wap/fudan/get-info";
  static const String _KEY_PREF = "daily_payload_cache";
  PersonInfo _info;

  FudanDailyRepository._() {
    initRepository();
  }

  static final _instance = FudanDailyRepository._();

  factory FudanDailyRepository.getInstance() => _instance;

  Future<dynamic> _getHistoryInfo(PersonInfo info) async {
    _info = info;
    await UISLoginTool.loginUIS(dio, LOGIN_URL, cookieJar, _info);
    var res = await dio.get(GET_INFO_URL);
    try {
      return res.data is Map
          ? res.data['d']
          : jsonDecode(res.data.toString())['d'];
    } catch (ignored) {}
    return null;
  }

  Future<bool> hasTick(PersonInfo info) async {
    _historyData = await Retrier.runAsyncWithRetry(() => _getHistoryInfo(info));
    if (_historyData['info'] is! Map) {
      return false;
    }
    return _historyData['info']['date'] ==
        new DateFormat('yyyyMMdd').format(DateTime.now());
  }

  /// Build a payload from [_historyData].
  ///
  /// If failed, return null.
  Map _buildPayloadFromHistory() {
    if (_historyData == null || _historyData['oldInfo'] is! Map) {
      return null;
    }
    Map payload = _historyData['info'];
    payload['ismoved'] = 0;
    payload['number'] = _historyData['uinfo']['role']['number'];
    payload['realname'] = _historyData['uinfo']['realname'];
    payload['area'] = _historyData['oldInfo']['area'];
    payload['city'] = _historyData['oldInfo']['city'];
    payload['province'] = _historyData['oldInfo']['province'];
    payload['sffsksfl'] = 0;
    payload['sfjcgrq'] = 0;
    payload['sfjcwhry'] = 0;
    payload['sfjchbry'] = 0;
    payload['sfcyglq'] = 0;
    payload['sfzx'] = 1;
    payload['sfcxzysx'] = 0;
    payload['sfyyjc'] = 0;
    payload['jcjgqr'] = 0;
    payload['sfwztl'] = 0;
    payload['sftztl'] = 0;
    // Copy vaccine injection's report data
    (_historyData['oldInfo'] as Map).forEach((key, value) {
      if ((key as String).startsWith('xs_')) {
        payload[key] = value;
      }
    });
    return payload;
  }

  Future<void> tick(PersonInfo info) async {
    if (_historyData == null) {
      _historyData =
          await Retrier.runAsyncWithRetry(() => _getHistoryInfo(info));
    }
    Map<String, String> headers = {
      "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:83.0) Gecko/20100101 Firefox/83.0",
      "Origin": "https://zlapp.fudan.edu.cn",
      "Referer": "https://zlapp.fudan.edu.cn/site/ncov/fudanDaily?from=history"
    };
    Map payload = await Cache.getRemotely<Map>(
        _KEY_PREF,
        () async => _buildPayloadFromHistory(),
        (cachedValue) => jsonDecode(cachedValue),
        (object) => jsonEncode(object));
    if (payload == null) {
      throw NotTickYesterdayException();
    }
    await dio.post(SAVE_URL,
        data: payload.encodeMap(),
        options:
            DioUtils.NON_REDIRECT_OPTION_WITH_FORM_TYPE_AND_HEADER(headers));
  }
}

class NotTickYesterdayException implements Exception {}
