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


import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/uis_login_tool.dart';
import 'package:dio/dio.dart';

class FudanEhallRepository extends BaseRepositoryWithDio {
  static const String _INFO_URL =
      "https://ehall.fudan.edu.cn/jsonp/ywtb/info/getUserInfoAndSchoolInfo.json";
  static const String _LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=http%3A%2F%2Fehall.fudan.edu.cn%2Flogin%3Fservice%3Dhttp%3A%2F%2Fehall.fudan.edu.cn%2Fywtb-portal%2Ffudan%2Findex.html";

  FudanEhallRepository._();

  static final _instance = FudanEhallRepository._();

  factory FudanEhallRepository.getInstance() => _instance;

  Future<StudentInfo> getStudentInfo(PersonInfo info) async {
    await UISLoginTool.loginUIS(dio, _LOGIN_URL, cookieJar!, info);
    return _getStudentInfo();
  }

  Future<StudentInfo> _getStudentInfo() async {
    Response<Map<String, dynamic>> rep = await dio.get(_INFO_URL);
    Map<String, dynamic> rawJson = rep.data!;
    if (rawJson['data']['userName'] == null) {
      throw GeneralLoginFailedException();
    }
    return StudentInfo(rawJson['data']['userName'],
        rawJson['data']['userTypeName'], rawJson['data']['userDepartment']);
  }

  @override
  String get linkHost => "fudan.edu.cn";
}

class StudentInfo {
  final String? name;
  final String? userTypeName;
  final String? userDepartment;

  StudentInfo(this.name, this.userTypeName, this.userDepartment);
}
