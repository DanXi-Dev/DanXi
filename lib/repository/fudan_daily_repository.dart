import 'dart:convert';

import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/public_extension_methods.dart';
import 'package:dan_xi/repository/uis_login_tool.dart';
import 'package:dan_xi/util/dio_utils.dart';
import 'package:dan_xi/util/retryer.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'inpersistent_cookie_manager.dart';

class FudanDailyRepository {
  Dio _dio = Dio();
  dynamic _historyData;
  NonpersistentCookieJar _cookieJar = NonpersistentCookieJar();
  static const String LOGIN_URL =
      "http://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Fzlapp.fudan.edu.cn%2Fa_fudanzlapp%2Fapi%2Fsso%2Findex%3Fredirect%3Dhttps%253A%252F%252Fzlapp.fudan.edu.cn%252Fsite%252Fncov%252FfudanDaily%253Ffrom%253Dhistory%26from%3Dwap";
  static const String SAVE_URL =
      "https://zlapp.fudan.edu.cn/ncov/wap/fudan/save";
  static const String GET_INFO_URL =
      "https://zlapp.fudan.edu.cn/ncov/wap/fudan/get-info";
  static const String _KEY_PREF = "daily_payload_cache";
  PersonInfo _info;

  FudanDailyRepository._() {
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  static final _instance = FudanDailyRepository._();

  factory FudanDailyRepository.getInstance() => _instance;

  Future<dynamic> _getHistoryInfo(PersonInfo info) async {
    _info = info;
    await UISLoginTool.loginUIS(_dio, LOGIN_URL, _cookieJar, _info);
    var res = await _dio.get(GET_INFO_URL);
    try {
      return jsonDecode(res.data.toString())['d'];
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<bool> hasTick(PersonInfo info) async {
    _historyData = await Retryer.runAsyncWithRetry(() => _getHistoryInfo(info));
    return _historyData['info'] is! Map ||
        _historyData['info']['date'] ==
            new DateFormat('yyyyMMdd').format(DateTime.now());
  }

  Map _buildPayloadFromHistory() {
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
    return payload;
  }

  Future<void> tick(PersonInfo info) async {
    if (_historyData == null) {
      _historyData =
          await Retryer.runAsyncWithRetry(() => _getHistoryInfo(info));
    }
    var headers = {
      "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:83.0) Gecko/20100101 Firefox/83.0",
      "Origin": "https://zlapp.fudan.edu.cn",
      "Referer": "https://zlapp.fudan.edu.cn/site/ncov/fudanDaily?from=history"
    };
    Map payload;
    var pref = await SharedPreferences.getInstance();
    if (_historyData == null || _historyData['oldInfo'] is! Map) {
      if (pref.containsKey(_KEY_PREF)) {
        payload = jsonDecode(pref.getString(_KEY_PREF));
      } else {
        throw NotTickYesterdayException();
      }
    } else {
      payload = _buildPayloadFromHistory();
      await pref.setString(_KEY_PREF, jsonEncode(payload));
    }

    await _dio.post(SAVE_URL,
        data: payload.encodeMap(),
        options:
            DioUtils.NON_REDIRECT_OPTION_WITH_FORM_TYPE_AND_HEADER(headers));
  }
}

class NotTickYesterdayException implements Exception {}
