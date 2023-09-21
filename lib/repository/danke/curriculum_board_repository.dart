/*
 *     Copyright (C) 2022  DanXi-Dev
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

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/model/danke/course.dart';
import 'package:dan_xi/model/danke/course_group.dart';
import 'package:dan_xi/model/danke/course_review.dart';
import 'package:dan_xi/model/opentreehole/jwt.dart';
import 'package:dan_xi/page/danke/course_review_editor.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/opentreehole/opentreehole_repository.dart';
import 'package:dan_xi/util/io/user_agent_interceptor.dart';
import 'package:dan_xi/util/opentreehole/jwt_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

class CurriculumBoardRepository extends BaseRepositoryWithDio {
  static const String _BASE_URL = "https://auth.fduhole.com/api";
  static const String _BASE_AUTH_URL = "https://danke.fduhole.com/api";

  JWToken? _token;

  CurriculumBoardRepository._(){
    dio.interceptors.add(JWTInterceptor(
        "$_BASE_AUTH_URL/refresh",
        () => _token,
        (token) => _token =
            SettingsProvider.getInstance().fduholeToken = token));
    dio.interceptors.add(
        UserAgentInterceptor(userAgent: Uri.encodeComponent(Constant.version)));
  }

  static final _instance = CurriculumBoardRepository._();

  factory CurriculumBoardRepository.getInstance() => _instance;

  Map<String, String> _tokenHeader() {
    if (_token == null || !_token!.isValid) {
      throw NotLoginError("Null Token");
    }
    return {"Authorization": "Bearer ${_token!.access!}"};
  }

  Future<List<CourseGroup>?> getCourseGroups() async {
    Response<List<dynamic>> response = await dio.get("$_BASE_URL/courses",
        options: Options(headers: _tokenHeader()));
    return response.data?.map((e) => CourseGroup.fromJson(e)).toList();
  }

  Future<Course?> getCourse(String courseId) async {
    Response<Map<String, dynamic>> response = await dio.get(
        "$_BASE_URL/courses/$courseId",
        options: Options(headers: _tokenHeader()));
    return Course.fromJson(response.data!);
  }

  Future<CourseReview?> addReview(
      int courseId, CourseReviewEditorText review) async {
    Response<Map<String, dynamic>> response =
        await dio.post("$_BASE_URL/courses/$courseId/reviews",
            data: {
              'title': review.title,
              'content': review.content,
              'rank': review.ratings.grade
            },
            options: Options(headers: _tokenHeader()));
    return CourseReview.fromJson(response.data!);
  }

  Future<int?> removeReview(String reviewId, CourseReview newReview) async {
    Response<String> response = await dio.delete("$_BASE_URL/reviews/$reviewId",
        options: Options(headers: _tokenHeader()));
    return response.statusCode;
  }

  Future<int?> modifyReview(String reviewId, CourseReview updatedReview) async {
    Response<String> response = await dio.put("$_BASE_URL/reviews/$reviewId",
        data: {
          'title': updatedReview.title,
          'content': updatedReview.content,
          'rank': updatedReview.courseGrade
        },
        options: Options(headers: _tokenHeader()));
    return response.statusCode;
  }

  Future<List<CourseReview>?> getReviews(String courseId) async {
    Response<List<dynamic>> response = await dio.get(
        "$_BASE_URL/courses/$courseId/reviews",
        options: Options(headers: _tokenHeader()));
    return response.data?.map((e) => CourseReview.fromJson(e)).toList();
  }

  Future<String> getRandomReview() async {
    debugPrint(SettingsProvider.getInstance().fduholeToken!.access!);
    Response<List<dynamic>> response = await dio.get(
        "$_BASE_URL/reviews/random",
        options: Options(headers: _tokenHeader()));
    return response.data!.first.toString();
  }

  @override
  String get linkHost => '127.0.0.1:8000';
}
