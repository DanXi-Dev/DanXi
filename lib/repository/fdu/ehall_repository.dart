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
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/uis_login_tool.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dan_xi/util/retrier.dart';
import 'package:dan_xi/util/webvpn_proxy.dart';
import 'package:dio/dio.dart';

class FudanEhallRepository extends BaseRepositoryWithDio {
  static const String _INFO_URL = "https://ehall.fudan.edu.cn/";
  static const String _UIS_LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Fid.fudan.edu.cn%2Fidp%2FthirdAuth%2Fcas";
  static const String _ID_REQUEST_URL =
      "https://id.fudan.edu.cn/idp/authCenter/authenticate?service=https%3A%2F%2Fehall.fudan.edu.cn%2Fmanage%2Fcommon%2Fcas_login%2F30001%3Fredirect%3Dhttps%253A%252F%252Fehall.fudan.edu.cn";
  static const String _LOGIN_URL =
      "https://ehall.fudan.edu.cn/manage/common/cas_login/30001";
  static Future<void>? loginSession;

  FudanEhallRepository._();

  static final _instance = FudanEhallRepository._();

  factory FudanEhallRepository.getInstance() => _instance;

  /// fixme: This method is essentially the same as the one in [WebvpnProxy._authenticateWebVPN].
  ///
  /// We should consider refactoring this to avoid code duplication.
  Future<void> _authenticateEhall(PersonInfo info) async {
    Response<dynamic>? res = await dio.get(_ID_REQUEST_URL,
        options: DioUtils.NON_REDIRECT_OPTION_WITH_FORM_TYPE);
    if (DioUtils.getRedirectLocation(res) != null) {
      // if we are redirected to UIS, we need to login to UIS first
      await DioUtils.processRedirect(dio, res);
      res = await UISLoginTool.loginUIS(dio, _UIS_LOGIN_URL, cookieJar!, info);
      if (res == null) throw Exception("UIS login failed");
    }
    final ticket = WebvpnProxy.retrieveTicket(res);

    Map<String, dynamic> queryParams = {
      'redirect': 'https://ehall.fudan.edu.cn',
      'ticket': ticket,
    };

    final response = await dio.get(_LOGIN_URL,
        queryParameters: queryParams,
        options: DioUtils.NON_REDIRECT_OPTION_WITH_FORM_TYPE);
    await DioUtils.processRedirect(dio, response);
  }

  Future<void> loginEhall(PersonInfo info) async {
    if (loginSession != null) {
      await loginSession;
    } else {
      loginSession = _authenticateEhall(info);
      await loginSession!;
      loginSession = null;
    }
  }

  Future<StudentInfo> getStudentInfo(PersonInfo info) async =>
      Retrier.tryAsyncWithFix(
        () async => await _getStudentInfo(info),
        (_) async => await loginEhall(info),
        retryTimes: 3,
      );

  Future<StudentInfo> _getStudentInfo(PersonInfo info) async {
    Response<dynamic> res = await dio.get(_INFO_URL,
        options: DioUtils.NON_REDIRECT_OPTION_WITH_FORM_TYPE);
    res = await DioUtils.processRedirect(dio, res);
    final htmlStr = res.data.toString();
    RegExp userInfoMatcher = RegExp(
        r'window\.userInfoDSL\s*=\s*({[\s\S]*?})(?=\s*\n|$)',
        dotAll: true);
    final match = userInfoMatcher.firstMatch(htmlStr);
    if (match == null) {
      throw Exception("Failed to parse user info");
    }
    final jsonStr = match.group(1)!;
    Map<String, dynamic> userInfo = jsonDecode(jsonStr);
    if (userInfo.isEmpty) {
      throw Exception("Empty user info");
    }
    return StudentInfo(
        userInfo['name'], userInfo['identity'], userInfo['depart']);
  }

  @override
  String get linkHost => "ehall.fudan.edu.cn";
}

class StudentInfo {
  final String? name;
  final String? userTypeName;
  final String? userDepartment;

  StudentInfo(this.name, this.userTypeName, this.userDepartment);
}
