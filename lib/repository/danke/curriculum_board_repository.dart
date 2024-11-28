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
import 'package:dan_xi/model/danke/course_group.dart';
import 'package:dan_xi/model/danke/course_review.dart';
import 'package:dan_xi/model/danke/search_results.dart';
import 'package:dan_xi/page/danke/course_review_editor.dart';
import 'package:dan_xi/provider/forum_provider.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/forum/forum_repository.dart';
import 'package:dan_xi/util/io/user_agent_interceptor.dart';
import 'package:dan_xi/util/forum/jwt_interceptor.dart';
import 'package:dan_xi/util/webvpn_proxy.dart';
import 'package:dio/dio.dart';

class CurriculumBoardRepository extends BaseRepositoryWithDio {
  static final String _BASE_URL = SettingsProvider.getInstance().dankeBaseUrl;
  static final String _BASE_AUTH_URL =
      SettingsProvider.getInstance().authBaseUrl;

  CurriculumBoardRepository._() {
    dio.interceptors.add(JWTInterceptor(
        "$_BASE_AUTH_URL/refresh",
        () => provider.token,
        (token) => provider.token =
            SettingsProvider.getInstance().forumToken = token));
    dio.interceptors.add(
        UserAgentInterceptor(userAgent: Uri.encodeComponent(Constant.version)));

    // First fetch of the course list is VERY SLOW
    dio.options = BaseOptions(
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 5));
  }

  /// Short name for the provider singleton
  ForumProvider get provider => ForumProvider.getInstance();

  Map<String, String> get _tokenHeader {
    if (provider.token == null || !provider.token!.isValid) {
      throw NotLoginError("Null Token");
    }
    return {"Authorization": "Bearer ${provider.token!.access!}"};
  }

  static final _instance = CurriculumBoardRepository._();

  factory CurriculumBoardRepository.getInstance() => _instance;

  // Return raw json string
  Future<CourseSearchResults?> searchCourseGroups(String keyword,
      {int? page, int pageLength = Constant.SEARCH_COUNT_PER_PAGE}) async {
    final options = RequestOptions(
        path: "$_BASE_URL/v3/course_groups/search",
        method: "GET",
        queryParameters: {
          'query': keyword,
          'page': page ?? 1,
          'page_size': pageLength
        },
        headers: _tokenHeader);
    Response<Map<String, dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return CourseSearchResults.fromJson(response.data!);
  }

  Future<CourseGroup?> getCourseGroup(int groupId) async {
    final options = RequestOptions(
        path: "$_BASE_URL/v3/course_groups/$groupId",
        method: "GET",
        headers: _tokenHeader);
    Response<Map<String, dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return CourseGroup.fromJson(response.data!);
  }

  Future<CourseReview?> addReview(CourseReviewEditorText review) async {
    final options = RequestOptions(
        path: "$_BASE_URL/courses/${review.courseId}/reviews",
        method: "POST",
        data: {
          'title': review.title,
          'content': review.content,
          'rank': review.grade
        },
        headers: _tokenHeader);
    Response<Map<String, dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return CourseReview.fromJson(response.data!);
  }

  Future<int?> removeReview(int reviewId) async {
    final options = RequestOptions(
        path: "$_BASE_URL/reviews/$reviewId",
        method: "DELETE",
        headers: _tokenHeader);
    Response<String> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return response.statusCode;
  }

  Future<int?> modifyReview(
      int reviewId, CourseReviewEditorText updatedReview) async {
    final options = RequestOptions(
        path: "$_BASE_URL/reviews/$reviewId/_webvpn",
        method: "PATCH",
        data: {
          'title': updatedReview.title,
          'content': updatedReview.content,
          'rank': updatedReview.grade
        },
        headers: _tokenHeader);
    Response<String> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return response.statusCode;
  }

  Future<CourseReview> voteReview(int reviewId, bool upVote) async {
    final options = RequestOptions(
        path: "$_BASE_URL/reviews/$reviewId",
        method: "PATCH",
        data: {
          'upvote': upVote,
        },
        headers: _tokenHeader);
    Response<dynamic> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return CourseReview.fromJson(response.data ?? "");
  }

  Future<List<CourseReview>?> getReviews(String courseId) async {
    final options = RequestOptions(
        path: "$_BASE_URL/courses/$courseId/reviews",
        method: "GET",
        headers: _tokenHeader);
    Response<List<dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return response.data?.map((e) => CourseReview.fromJson(e)).toList();
  }

  Future<CourseReview?> getRandomReview() async {
    final options = RequestOptions(
        path: "$_BASE_URL/reviews/random",
        method: "GET",
        headers: _tokenHeader);
    // debugPrint(SettingsProvider.getInstance().forumToken!.access!);
    Response<dynamic> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return CourseReview.fromJson(response.data ?? "");
  }

  @override
  String get linkHost => 'danke.fduhole.com';

  @override
  bool get isWebvpnApplicable => true;
}
