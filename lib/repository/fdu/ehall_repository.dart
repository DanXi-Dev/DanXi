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
import 'package:dan_xi/repository/fdu/neo_login_tool.dart';
import 'package:dio/dio.dart';

class FudanEhallRepository extends BaseRepositoryWithDio {
  static const String _INFO_URL = "https://ehall.fudan.edu.cn/";

  static final Uri _LOGIN_URL = Uri.parse(
      "https://ehall.fudan.edu.cn/manage/common/cas_login/30001?redirect=https%3A%2F%2Fehall.fudan.edu.cn");

  static Future<void>? loginSession;

  FudanEhallRepository._();

  static final _instance = FudanEhallRepository._();

  factory FudanEhallRepository.getInstance() => _instance;

  Future<StudentInfo> getStudentInfo(PersonInfo info) async {
    final options = RequestOptions(
      method: "GET",
      path: _INFO_URL,
      responseType: ResponseType.plain,
    );

    final userInfoMatcher = RegExp(
        r'window\.userInfoDSL\s*=\s*({[\s\S]*?})(?=\s*\n|$)',
        dotAll: true);
    return FudanSession.request(
      options,
      (req) {
        final htmlStr = req.data.toString();
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
      },
      manualLoginUrl: _LOGIN_URL,
      info: info,
      type: FudanLoginType.UISNeo,
    );
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
