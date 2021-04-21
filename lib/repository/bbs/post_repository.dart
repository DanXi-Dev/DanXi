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

import 'dart:io';

import 'package:dan_xi/common/Secret.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/post.dart';
import 'package:dan_xi/model/reply.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

class PostRepository extends BaseRepositoryWithDio {
  static final _instance = PostRepository._();

  factory PostRepository.getInstance() => _instance;
  static const String _BASE_URL = "https://www.fduhole.tk/v1";

  // Dio secureDio = Dio();

  /// The token used for session authentication.
  ///
  /// It should always be kept secretly. When testing, initialize with your own token.
  String _token;

  PostRepository._() {
    initRepository();
  }

  requestToken(PersonInfo info) async {
    // Crash on dio ^4.0.0

    // //Pin HTTPS cert
    // ByteData certBytes = await rootBundle.load('assets/FDUHOLE_R3.cer');
    // //TODO: Let's Encrypt Certificates expire every 90 days. We should find a way to pin certificate CA only
    // (secureDio.httpClientAdapter as DefaultHttpClientAdapter)
    //     .onHttpClientCreate = (client) {
    //   SecurityContext sc = SecurityContext();
    //   sc.setTrustedCertificatesBytes(certBytes.buffer.asUint8List());
    //   HttpClient httpClient = HttpClient(context: sc);
    //   return httpClient;
    // };

    Response response = await dio.post(_BASE_URL + "/register/", data: {
      'api-key': Secret.FDUHOLE_API_KEY,
      'email': "${info.id}@fudan.edu.cn"
    });
    if (response.statusCode == 200)
      _token = response.data["token"];
    else {
      _token = null;
      print("failed to login to fduhole " + response.statusCode.toString() + response.toString());
      throw NotLoginError();
    }
  }

  Map<String, String> get _tokenHeader {
    return {"Authorization": "Token " + _token};
  }

  bool get isUserInitialized => _token == null ? false : true;

  Future<void> initializeUser(PersonInfo info) async{
    await requestToken(info);
  }

  Future<List<BBSPost>> loadPosts(int page) async {
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
