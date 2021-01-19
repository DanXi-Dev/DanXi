import 'dart:convert';

import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/uis_login_tool.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:intl/intl.dart';
import 'package:dan_xi/public_extension_methods.dart';

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
  PersonInfo _info;

  FudanDailyRepository._() {
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  static final _instance = FudanDailyRepository._();

  factory FudanDailyRepository.getInstance() => _instance;

  Future<dynamic> _getHistoryInfo(PersonInfo info, {int retryTimes = 5}) async {
    _info = info;
    for (int i = 0; i < retryTimes; i++) {
      await UISLoginTool.loginUIS(_dio, LOGIN_URL, _cookieJar, _info);
      var res = await _dio.get(GET_INFO_URL);
      try {
        return res.data['d'];
      } catch (e) {
        print(e);
      }
    }
    return null;
  }

  Future<bool> hasTick(PersonInfo info) async {
    _historyData = await _getHistoryInfo(info);
    print("Last Tick Date:${_historyData['info']['date']}");
    return _historyData['info']['date'] ==
        new DateFormat('yyyyMMdd').format(DateTime.now());
  }

  Future<void> tick(PersonInfo info) async {
    if (_historyData == null) {
      _historyData = await _getHistoryInfo(info);
    }
    var headers = {
      "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:83.0) Gecko/20100101 Firefox/83.0",
      "Origin": "https://zlapp.fudan.edu.cn",
      "Referer": "https://zlapp.fudan.edu.cn/site/ncov/fudanDaily?from=history"
    };
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

    await _dio.post(SAVE_URL,
        data: payload.encodeMap(),
        options: Options(
            headers: headers,
            contentType: Headers.formUrlEncodedContentType,
            followRedirects: false,
            validateStatus: (status) {
              return status < 400;
            }));
  }
}
