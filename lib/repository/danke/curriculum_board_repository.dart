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

import 'package:dan_xi/model/danke/course.dart';
import 'package:dan_xi/model/danke/course_group.dart';
import 'package:dan_xi/model/danke/review.dart';
import 'package:dan_xi/model/opentreehole/jwt.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dio/dio.dart';

class CurriculumBoardRepository extends BaseRepositoryWithDio {
  static const String _BASE_URL = "http://127.0.0.1:8000";

  CurriculumBoardRepository._();

  static final _instance = CurriculumBoardRepository._();

  factory CurriculumBoardRepository.getInstance() => _instance;

  Map<String, String> _tokenHeader(JWToken fduHoleToken) {
    return {"Authorization": "Bearer ${fduHoleToken.access!}"};
  }

  Future<List<CourseGroup>?> getCourseGroups(JWToken fduHoleToken) async {
    Response<List<dynamic>> response = await dio.get("$_BASE_URL/courses",
        options: Options(headers: _tokenHeader(fduHoleToken)));
    return response.data?.map((e) => CourseGroup.fromJson(e)).toList();
  }

  Future<Course?> getCourse(JWToken fduHoleToken, String courseId) async {
    Response<Map<String, dynamic>> response = await dio.get(
        "$_BASE_URL/courses/$courseId",
        options: Options(headers: _tokenHeader(fduHoleToken)));
    return Course.fromJson(response.data!);
  }

  Future<CourseReview?> addReview(
      JWToken fduHoleToken, String courseId, CourseReview newReview) async {
    Response<Map<String, dynamic>> response =
        await dio.post("$_BASE_URL/courses/$courseId/reviews",
            data: {
              'title': newReview.title,
              'content': newReview.content,
              'rank': newReview.course_grade,
              'remark': newReview.like
            },
            options: Options(headers: _tokenHeader(fduHoleToken)));
    return CourseReview.fromJson(response.data!);
  }

  Future<int?> removeReview(
      JWToken fduHoleToken, String reviewId, CourseReview newReview) async {
    Response<String> response = await dio.delete("$_BASE_URL/reviews/$reviewId",
        options: Options(headers: _tokenHeader(fduHoleToken)));
    return response.statusCode;
  }

  Future<int?> modifyReview(
      JWToken fduHoleToken, String reviewId, CourseReview updatedReview) async {
    Response<String> response = await dio.put("$_BASE_URL/reviews/$reviewId",
        data: {
          'title': updatedReview.title,
          'content': updatedReview.content,
          'rank': updatedReview.course_grade,
          'remark': updatedReview.like
        },
        options: Options(headers: _tokenHeader(fduHoleToken)));
    return response.statusCode;
  }

  Future<List<CourseReview>?> getReviews(
      JWToken fduHoleToken, String courseId) async {
    Response<List<dynamic>> response = await dio.get(
        "$_BASE_URL/courses/$courseId/reviews",
        options: Options(headers: _tokenHeader(fduHoleToken)));
    return response.data?.map((e) => CourseReview.fromJson(e)).toList();
  }

  @override
  String get linkHost => '127.0.0.1:8000';
}
