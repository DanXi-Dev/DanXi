/*
 *     Copyright (C) 2021  w568w
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

import 'package:dan_xi/common/Secret.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/post.dart';
import 'package:dan_xi/model/reply.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:data_plugin/bmob/response/bmob_registered.dart';
import 'package:data_plugin/bmob/table/bmob_user.dart';
import 'package:dio/dio.dart';

class PostRepository extends BaseRepositoryWithDio {
  static final _instance = PostRepository._();

  factory PostRepository.getInstance() => _instance;
  static const String _BASE_URL = "https://www.fduhole.tk/v1";

  PersonInfo _info;

  /// The token used for session authentication.
  ///
  /// It should always be kept secretly. When testing, initialize with your own token.
  String _token;

  PostRepository._() {
    initRepository();
  }

  Future<BmobUser> login(PersonInfo personInfo) async {
    BmobUser user = BmobUser();
    user.username = personInfo.name;
    user.email = personInfo.id;
    user.password = personInfo.password;
    return await user.login();
  }

  Future<BmobRegistered> register(PersonInfo personInfo) async {
    var user = BmobUser();
    user
      ..username = personInfo.name
      ..email = "${personInfo.id}@fudan.edu.cn"
      ..password = personInfo.password;
    return await user.register();
  }

  requestToken() async {
    Response response = await dio.post(_BASE_URL + "/register/", data: {'api-key': Secret.FDUHOLE_API_KEY, 'email': "${_info.id}@fudan.edu.cn", "password": "APP_GENERATED_TEST_PASSWORD"});
    if(response.statusCode == 200) _token = response.data["token"];
    else {
      _token = null;
      print("failed " + response.statusCode.toString() + response.toString());
      throw NotLoginError();
    }
  }

  Map<String, String> get _tokenHeader {
    requestToken();
    return {"Authorization": "Token " + _token};
  }

  void initializeUser(PersonInfo info) {
    _info = info; //TODO: Ensure [_info] is set before loading anything
  }

  Future<List<BBSPost>> loadPosts(int page, PersonInfo personInfo) async {
    Response response = await dio.get(_BASE_URL + "/discussions/",
        queryParameters: {"page": page},
        options: Options(headers: _tokenHeader));
    List result = response.data;
    return result.map((e) => BBSPost.fromJson(e)).toList();
  }

  Future<List<Reply>> loadReplies(BBSPost post, int page) async {
    Response response = await dio.get(_BASE_URL + "/posts/",
        queryParameters: {"page": page, "id": post.id},
        options: Options(headers: _tokenHeader));
    List result = response.data;
    return result.map((e) => Reply.fromJson(e)).toList();
  }
}

class NotLoginError implements Exception {}
