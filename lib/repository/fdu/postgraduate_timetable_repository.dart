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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/time_table.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/postgraduate_des.dart';
import 'package:dan_xi/repository/fdu/time_table_repository.dart';
import 'package:dan_xi/util/io/cache.dart';
import 'package:dan_xi/util/public_extension_methods.dart';
import 'package:dan_xi/util/retrier.dart';
import 'package:dan_xi/util/shared_preferences.dart';
import 'package:dio/dio.dart';

class PostgraduateTimetableRepository extends BaseRepositoryWithDio {
  static const String TIME_TABLE_UG_URL =
      'http://yjsxk.fudan.sh.cn/yjsxkapp/sys/xsxkappfudan/xsxkCourse/loadKbxx.do?_=';
  static const String HOMEPAGE_URL =
      "http://yjsxk.fudan.sh.cn/yjsxkapp/sys/xsxkappfudan/*default/index.do";
  static const String GET_TOKEN_URL =
      "http://yjsxk.fudan.sh.cn/yjsxkapp/sys/xsxkappfudan/login/4/vcode.do?";
  static const String GET_CAPTCHA_URL =
      "http://yjsxk.fudan.sh.cn/yjsxkapp/sys/xsxkappfudan/login/vcode/image.do?vtoken=";
  static const String LOGIN_URL =
      "http://yjsxk.fudan.sh.cn/yjsxkapp/sys/xsxkappfudan/login/check/login.do?";

  PostgraduateTimetableRepository._();

  static final _instance = PostgraduateTimetableRepository._();

  factory PostgraduateTimetableRepository.getInstance() => _instance;

  Future<String> _loadToken() async {
    Response<dynamic> tokenData = await dio.get(GET_TOKEN_URL);
    var temp = tokenData.data is Map
        ? tokenData.data
        : jsonDecode(tokenData.data.toString());
    return temp['data']['token'];
  }

  Future<void> _requestLogin(
      String id, String pwd, String yzm, String token) async {
    await dio.post(LOGIN_URL,
        data: {
          "loginName": id,
          "loginPwd": pwd,
          "verifyCode": yzm,
          "vtoken": token
        }.encodeMap(),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ));
  }

  Future<void> _login(PersonInfo ug, OnCaptchaCallback callback) async {
    String yzmToken = await _loadToken();
    String yzm = await callback(GET_CAPTCHA_URL + yzmToken);
    await _requestLogin(ug.id!, PostgraduateDES.encrypt(ug.password!), yzm, yzmToken);
  }

  Future<TimeTable?> loadTimeTableRemotely(
      PersonInfo info, OnCaptchaCallback callback,
      {DateTime? startTime}) {
    return Retrier.tryAsyncWithFix(
        () => _loadTimeTableRemotely(callback, startTime: startTime),
        (exception) => _login(info, callback));
  }

  Future<TimeTable?> _loadTimeTableRemotely(OnCaptchaCallback callback,
      {DateTime? startTime}) async {
    Response<dynamic> coursePage = await dio.get(
        TIME_TABLE_UG_URL + DateTime.now().millisecondsSinceEpoch.toString(),
        options: Options());
    return TimeTable.fromPGJson(
        startTime ??
            DateTime.tryParse(
                SettingsProvider.getInstance().thisSemesterStartDate ?? "") ??
            Constant.DEFAULT_SEMESTER_START_DATE,
        coursePage.data is Map
            ? coursePage.data
            : jsonDecode(coursePage.data.toString()));
  }

  Future<TimeTable?> loadTimeTable(PersonInfo info, OnCaptchaCallback callback,
      {DateTime? startTime, bool forceLoadFromRemote = false}) async {
    startTime ??= TimeTable.defaultStartDate;
    if (forceLoadFromRemote) {
      TimeTable? result = (await Cache.getRemotely<TimeTable>(
          TimeTableRepository.KEY_TIMETABLE_CACHE,
          () async => (await loadTimeTableRemotely(info, callback,
              startTime: startTime))!,
          (cachedValue) => TimeTable.fromJson(jsonDecode(cachedValue!)),
          (object) => jsonEncode(object.toJson())));
      SettingsProvider.getInstance().timetableLastUpdated = DateTime.now();
      return result;
    } else {
      return Cache.get<TimeTable>(
          TimeTableRepository.KEY_TIMETABLE_CACHE,
          () async => (await loadTimeTableRemotely(info, callback,
              startTime: startTime))!,
          (cachedValue) => TimeTable.fromJson(jsonDecode(cachedValue!)),
          (object) => jsonEncode(object.toJson()));
    }
  }

  TimeTable loadTimeTableLocally() {
    // FIXME: Do not read this should-be-private field everywhere!
    XSharedPreferences preferences =
        SettingsProvider.getInstance().preferences!;
    if (preferences.containsKey(TimeTableRepository.KEY_TIMETABLE_CACHE)) {
      return TimeTable.fromJson(jsonDecode(
          preferences.getString(TimeTableRepository.KEY_TIMETABLE_CACHE)!));
    } else {
      throw StateError("No local timetable now");
    }
  }

  @override
  String get linkHost => "fudan.edu.cn";
}

typedef OnCaptchaCallback = Future<String> Function(String imageUrl);
