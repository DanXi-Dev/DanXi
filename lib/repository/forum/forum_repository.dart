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
import 'dart:io';

import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/model/forum/audit.dart';
import 'package:dan_xi/model/forum/division.dart';
import 'package:dan_xi/model/forum/floor.dart';
import 'package:dan_xi/model/forum/history.dart';
import 'package:dan_xi/model/forum/hole.dart';
import 'package:dan_xi/model/forum/jwt.dart';
import 'package:dan_xi/model/forum/message.dart';
import 'package:dan_xi/model/forum/punishment.dart';
import 'package:dan_xi/model/forum/quiz_answer.dart';
import 'package:dan_xi/model/forum/quiz_question.dart';
import 'package:dan_xi/model/forum/report.dart';
import 'package:dan_xi/model/forum/tag.dart';
import 'package:dan_xi/model/forum/user.dart';
import 'package:dan_xi/page/subpage_forum.dart';
import 'package:dan_xi/provider/forum_provider.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/util/forum/fduhole_platform_bridge.dart';
import 'package:dan_xi/util/forum/jwt_interceptor.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dan_xi/util/io/user_agent_interceptor.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dio/dio.dart';

/// The repository for forum.
///
/// # State
/// During to some history reasons, this repository's state can be complex.
/// Please read the method comments carefully before using them.
///
/// All states have been moved to [ForumProvider], which is a [ChangeNotifier];
/// any field in this class should be considered as temporary variables, e.g. caches.
class ForumRepository extends BaseRepositoryWithDio {
  static final _instance = ForumRepository._();

  factory ForumRepository.getInstance() => _instance;

  static final String _BASE_URL = SettingsProvider.getInstance().forumBaseUrl;
  static final String _BASE_AUTH_URL =
      SettingsProvider.getInstance().authBaseUrl;
  static final String _IMAGE_BASE_URL =
      SettingsProvider.getInstance().imageBaseUrl;

  /// Cached floors, used by [mentions].
  final Map<int, OTFloor> _floorCache = {};

  /// Cached OTTags.
  List<OTTag> _tagCache = [];

  /// Push notification registration cache.
  PushNotificationRegData? _pushNotificationRegData;

  /// Store the last upload push token, used for debug purpose only.
  String? lastUploadToken;

  /// Short aliases.
  ForumProvider get provider => ForumProvider.getInstance();

  /// Logout, removing all cached data, tokens, on-disk local settings, etc.
  ///
  /// It also unregisters the push notification token.
  Future<void> logout() async {
    if (!provider.isUserInitialized) {
      if (SettingsProvider.getInstance().forumToken == null) {
        return;
      } else {
        provider.token = SettingsProvider.getInstance().forumToken;
      }
    }
    await deletePushNotificationToken(await PlatformX.getUniqueDeviceId());
    clearCache();
    SettingsProvider.getInstance().deleteAllForumData();
  }

  /// Clear all cached data and in-memory states (i.e. token and user info that have been loaded).
  ///
  /// Next time, you have to call [initializeToken] or [initializeRepo] again.
  void clearCache() {
    provider.token = null;
    provider.userInfo = null;
    provider.divisionCache = [];
    _pushNotificationRegData = null;
    _floorCache.clear();
    _tagCache.clear();
  }

  /// Cache a floor for future reuse.
  void cacheFloor(OTFloor floor) {
    if (floor.floor_id == null) return;
    _floorCache[floor.floor_id!] = floor;
    if (_floorCache.length > 200) {
      reduceFloorCache();
    }
  }

  /// Reduce the floor cache by a factor.
  void reduceFloorCache({int factor = 2}) {
    _floorCache.removeWhere((key, value) => key % factor == 0);
  }

  void invalidateFloorCache(int floorId) {
    _floorCache.remove(floorId);
  }

  ForumRepository._() {
    // Override the options set in parent class.
    dio.options = BaseOptions(
      receiveDataWhenStatusError: true,
      validateStatus: (int? status) {
        return status != null && status >= 200 && status < 300;
      },
    );
    dio.interceptors.add(JWTInterceptor(
        "$_BASE_AUTH_URL/refresh",
        () => provider.token,
        (token) => provider.token =
            SettingsProvider.getInstance().forumToken = token));
    dio.interceptors.add(
        UserAgentInterceptor(userAgent: Uri.encodeComponent(Constant.version)));
  }

  /// A "minimal" initialization of the provider.
  ///
  /// It loads the token from disk to the provider.
  ///
  /// If the token is not valid, it will throw a [NotLoginError].
  void initializeToken() {
    if (SettingsProvider.getInstance().forumToken != null) {
      provider.token = SettingsProvider.getInstance().forumToken;
    } else {
      throw NotLoginError("No token");
    }
  }

  /// A full initialization of the user data.
  ///
  /// It loads the token and user info which are shared across forum and danke.
  ///
  /// It is used to provide user data for sections apart from forum (specifically danke for now).
  Future<void> initializeUser() async {
    initializeToken();
    if (provider.userInfo == null) await getUserProfile(forceUpdate: true);
  }

  /// A "complete" initialization of the repository and provider.
  ///
  /// It loads the token, user info, divisions, and register the push notification token eagerly.
  ///
  /// Mostly, it is used to reduce a feeling of "progressive loading" when the user opens the app.
  ///
  /// We cache them all, so that one loading, everything done.
  Future<void> initializeRepo() async {
    initializeUser();

    try {
      FDUHolePlatformBridge.registerRemoteNotification();
    } catch (_) {}

    if (provider.divisionCache.isEmpty) await loadDivisions(useCache: false);
    if (_pushNotificationRegData != null) {
      // No need for [await] here, we can do this in the background
      updatePushNotificationToken(
              _pushNotificationRegData!.token,
              _pushNotificationRegData!.deviceId,
              _pushNotificationRegData!.type)
          .catchError((ignored) {});
    }
  }

  Future<bool?> checkRegisterStatus(String email) async {
    final Response<Map<String, dynamic>> response = await dio.get(
        "$_BASE_AUTH_URL/verify/email",
        queryParameters: {"email": email, "check": true},
        options: Options(
            validateStatus: (status) => status != null && status <= 400));
    if (response.data!.containsKey("registered")) {
      return response.data!["registered"];
    } else {
      throw (response.data!["message"]);
    }
  }

  /// FIXME: we used to use a pinned cert to prevent HTTPS traffic sniffing. But now we do not need it anymore.
  Dio get secureDio {
    Dio secureDio = DioUtils.newDioWithProxy();
    // Pin HTTPS cert
    /*(secureDio.httpClientAdapter as DefaultHttpClientAdapter)
        .onHttpClientCreate = (client) {
      final SecurityContext sc = SecurityContext(withTrustedRoots: false);
      HttpClient httpClient = HttpClient(context: sc);
      httpClient.badCertificateCallback =
          (X509Certificate certificate, String host, int port) {
        return true;
        // This badCertificateCallback will always be called since we have no trusted certificate.
        final ASN1Parser p = ASN1Parser(certificate.der);
        final ASN1Sequence signedCert = p.nextObject() as ASN1Sequence;
        final ASN1Sequence cert = signedCert.elements[0] as ASN1Sequence;
        final ASN1Sequence pubKeyElement = cert.elements[6] as ASN1Sequence;
        final ASN1BitString pubKeyBits =
            pubKeyElement.elements[1] as ASN1BitString;
        if (listEquals(
            pubKeyBits.stringValue, SecureConstant.PINNED_CERTIFICATE)) {
          return true;
        }
        // Allow connection when public key matches
        throw NotLoginError("Invalid HTTPS Certificate");
      };
      return httpClient;
    };*/
    return secureDio;
  }

  Future<void> requestEmailVerifyCode(String email) async {
    await dio
        .get("$_BASE_AUTH_URL/verify/email", queryParameters: {"email": email});
  }

  Future<JWToken?> register(
      String email, String password, String verifyCode) async {
    final Response<Map<String, dynamic>> response =
        await dio.post("$_BASE_AUTH_URL/register", data: {
      "password": password,
      "email": email,
      "verification": int.parse(verifyCode),
    });
    return SettingsProvider.getInstance().forumToken =
        JWToken.fromJsonWithVerification(response.data!);
  }

  Future<JWToken?> loginWithUsernamePassword(
      String username, String password) async {
    final Response<Map<String, dynamic>> response =
        await dio.post("$_BASE_AUTH_URL/login", data: {
      'email': username,
      'password': password,
    });
    return SettingsProvider.getInstance().forumToken =
        JWToken.fromJsonWithVerification(response.data!);
  }

  Map<String, String> get _tokenHeader {
    if (provider.token == null || !provider.token!.isValid) {
      throw NotLoginError("Null Token");
    }
    return {"Authorization": "Bearer ${provider.token!.access!}"};
  }

  Future<List<OTDivision>?> loadDivisions({bool useCache = true}) async {
    if (provider.divisionCache.isNotEmpty && useCache) {
      return provider.divisionCache;
    }
    final Response<List<dynamic>> response = await dio
        .get("$_BASE_URL/divisions", options: Options(headers: _tokenHeader));
    final result = response.data?.map((e) => OTDivision.fromJson(e)).toList();
    if (result != null) {
      provider.divisionCache = result;
    }
    return provider.divisionCache.isNotEmpty ? provider.divisionCache : null;
  }

  List<OTHole> getPinned(int divisionId) {
    try {
      return provider.divisionCache
              .firstWhere((element) => element.division_id == divisionId)
              .pinned ??
          [];
    } catch (ignored) {
      return [];
    }
  }

  List<OTDivision> getDivisions() => provider.divisionCache;

  Future<OTDivision?> loadSpecificDivision(int divisionId,
      {bool useCache = true}) async {
    if (useCache) {
      try {
        final OTDivision cached = provider.divisionCache
            .firstWhere((e) => e.division_id == divisionId);
        return cached;
      } catch (_) {}
    }
    final Response<Map<String, dynamic>> response = await dio.get(
        "$_BASE_URL/divisions/$divisionId",
        options: Options(headers: _tokenHeader));
    final newDivision = OTDivision.fromJson(response.data!);
    var newList = provider.divisionCache.toList();
    newList.removeWhere((element) => element.division_id == divisionId);
    newList.add(newDivision);
    provider.divisionCache = newList;
    return newDivision;
  }

  Future<List<OTHole>?> loadHoles(DateTime startTime, int divisionId,
      {int length = Constant.POST_COUNT_PER_PAGE,
      String? tag,
      SortOrder? sortOrder}) async {
    sortOrder ??= SortOrder.LAST_REPLIED;
    final Response<List<dynamic>> response = await dio.get("$_BASE_URL/holes",
        queryParameters: {
          "start_time": startTime.toUtc().toIso8601String(),
          "division_id": divisionId,
          "length": length,
          "tag": tag,
          "order": sortOrder.getInternalString()
        },
        options: Options(headers: _tokenHeader));
    return response.data?.map((e) => OTHole.fromJson(e)).toList();
  }

  Future<List<OTHole>?> loadUserHoles(DateTime startTime,
      {int length = Constant.POST_COUNT_PER_PAGE, SortOrder? sortOrder}) async {
    sortOrder ??= SortOrder.LAST_REPLIED;
    final Response<List<dynamic>> response =
        await dio.get("$_BASE_URL/users/me/holes",
            queryParameters: {
              "offset": startTime.toUtc().toIso8601String(),
              "size": length,
              "order": sortOrder.getInternalString()
            },
            options: Options(headers: _tokenHeader));
    return response.data?.map((e) => OTHole.fromJson(e)).toList();
  }

  // NEVER USED
  Future<OTHole?> loadSpecificHole(int holeId) async {
    final Response<Map<String, dynamic>> response = await dio.get(
        "$_BASE_URL/holes/$holeId",
        options: Options(headers: _tokenHeader));
    final hole = OTHole.fromJson(response.data!);
    return hole;
  }

  Future<OTFloor?> loadSpecificFloor(int floorId) async {
    final result = _floorCache[floorId];
    if (result != null) {
      return result;
    }

    final Response<Map<String, dynamic>> response = await dio.get(
        "$_BASE_URL/floors/$floorId",
        options: Options(headers: _tokenHeader));
    final floor = OTFloor.fromJson(response.data!);
    cacheFloor(floor);
    return floor;
  }

  Future<List<OTFloor>?> loadFloors(OTHole post,
      {int startFloor = 0, int length = Constant.POST_COUNT_PER_PAGE}) async {
    final Response<List<dynamic>> response = await dio.get("$_BASE_URL/floors",
        queryParameters: {
          "start_floor": startFloor,
          "hole_id": post.hole_id,
          "length": length
        },
        options: Options(headers: _tokenHeader));
    final floors = response.data?.map((e) => OTFloor.fromJson(e)).toList();
    for (var element in floors!) {
      cacheFloor(element);
      element.mention?.forEach((mention) {
        cacheFloor(mention);
      });
    }
    return floors;
  }

  Future<List<OTFloor>?> loadSearchResults(String? searchString,
      {int? startFloor, int length = Constant.POST_COUNT_PER_PAGE}) async {
    final Response<List<dynamic>> response = await dio.get("$_BASE_URL/floors",
        //queryParameters: {"start_floor": 0, "s": searchString, "length": 0},
        queryParameters: {
          "start_floor": startFloor,
          "s": searchString,
          "length": length,
        },
        options: Options(headers: _tokenHeader));
    return response.data?.map((e) => OTFloor.fromJson(e)).toList();
  }

  Future<List<OTTag>?> loadTags({bool useCache = true}) async {
    if (useCache && _tagCache.isNotEmpty) {
      return _tagCache;
    }
    final Response<List<dynamic>> response = await dio.get("$_BASE_URL/tags",
        options: Options(headers: _tokenHeader));
    return _tagCache = response.data!.map((e) => OTTag.fromJson(e)).toList();
  }

  Future<int?> newHole(int divisionId, String? content,
      {List<OTTag>? tags}) async {
    if (content == null) return -1;
    if (tags == null || tags.isEmpty) tags = [const OTTag(0, 0, KEY_NO_TAG)];
    // Suppose user is logged in. He should be.
    final Response<dynamic> response = await dio.post("$_BASE_URL/holes",
        data: {
          "division_id": divisionId,
          "content": content,
          "tags": tags,
        },
        options: Options(headers: _tokenHeader));
    return response.statusCode;
  }

  Future<String?> uploadImage(File file) async {
    String path = file.absolute.path;
    String fileName = path.substring(path.lastIndexOf("/") + 1, path.length);
    Response<Map<String, dynamic>> response =
        await dio.post<Map<String, dynamic>>("$_IMAGE_BASE_URL/json",
            data: FormData.fromMap({
              "source": await MultipartFile.fromFile(path, filename: fileName)
            }),
            options: Options(headers: _tokenHeader));
    return response.data!['image']['display_url'];
  }

  String extractHighDefinitionImageUrl(String imageUrl) {
    if (imageUrl.contains(_IMAGE_BASE_URL) && imageUrl.contains(".md.")) {
      return imageUrl.replaceFirst(".md.", ".");
    }
    return imageUrl;
  }

  Future<int?> newFloor(int? discussionId, String content) async {
    final Response<dynamic> response = await dio.post("$_BASE_URL/floors",
        data: {
          "content": content,
          "hole_id": discussionId,
          //"mention": findMention(content)
        },
        options: Options(headers: _tokenHeader));
    return response.statusCode;
  }

  /*List<int?> findMention(String content) {
    final matches =
        RegExp(MENTION_REGEX_STRING, multiLine: true).allMatches(content);
    final result = matches.map((e) => int.tryParse(e.group(1) ?? ""));
    return result.where((element) => element != null).toList();
  }*/

  Future<OTFloor?> likeFloor(int floorId, int like) async {
    final Response<Map<String, dynamic>> response = await dio.post(
        "$_BASE_URL/floors/$floorId/like/$like",
        options: Options(headers: _tokenHeader));
    return OTFloor.fromJson(response.data!);
  }

  Future<int?> reportPost(int? postId, String reason) async {
    final Response<dynamic> response = await dio.post("$_BASE_URL/reports",
        data: {"floor_id": postId, "reason": reason},
        options: Options(headers: _tokenHeader));
    return response.statusCode;
  }

  /// Note: this method should return a mutable reference to the provider's user info.
  /// i.e. [provider.userInfo].
  Future<OTUser?> getUserProfile({bool forceUpdate = false}) async {
    if (provider.userInfo == null || forceUpdate) {
      final Response<Map<String, dynamic>> response = await dio
          .get("$_BASE_URL/users", options: Options(headers: _tokenHeader));
      provider.userInfo = OTUser.fromJson(response.data!);
      provider.userInfo?.favorites = null;
      provider.userInfo?.subscriptions = null;
    }
    return provider.userInfo;
  }

  Future<OTUser?> updateUserProfile() async {
    final Response<Map<String, dynamic>> response = await dio.put(
        "$_BASE_URL/users/${provider.userInfo!.user_id}",
        data: provider.userInfo!.toJson(),
        options: Options(headers: _tokenHeader));
    provider.userInfo = OTUser.fromJson(response.data!);
    provider.userInfo?.favorites = null;
    provider.userInfo?.subscriptions = null;
    return provider.userInfo;
  }

  Future<void> updateHoleViewCount(int holeId) async {
    await dio.patch("$_BASE_URL/holes/$holeId",
        options: Options(headers: _tokenHeader));
  }

  Future<List<OTMessage>?> loadMessages(
      {bool unreadOnly = false, DateTime? startTime}) async {
    final Response<List<dynamic>> response =
        await dio.get("$_BASE_URL/messages",
            queryParameters: {
              "not_read": unreadOnly,
              "start_time": startTime?.toUtc().toIso8601String(),
            },
            options: Options(headers: _tokenHeader));
    return response.data?.map((e) => OTMessage.fromJson(e)).toList();
  }

  Future<void> modifyMessage(OTMessage message) async {
    await dio.delete("$_BASE_URL/messages/${message.message_id}",
        data: {
          "has_read": message.has_read,
        },
        options: Options(headers: _tokenHeader));
  }

  Future<void> clearMessages() async {
    await dio.put("$_BASE_URL/messages",
        data: {
          "clear_all": true,
        },
        options: Options(headers: _tokenHeader));
  }

  Future<bool?> isUserAdmin() async {
    return (await getUserProfile())!.is_admin;
  }

  Future<bool?> hasAnsweredQuestions() async {
    return (await getUserProfile())!.has_answered_questions;
  }

  /// Get silence date for division, return [null] if not silenced or not initialized
  DateTime? getSilenceDateForDivision(int divisionId) {
    return DateTime.tryParse(
        provider.userInfo?.permission?.silent?[divisionId] ?? "");
  }

  /// Non-async version of [isUserAdmin], will return false if data is not yet ready
  bool get isAdmin {
    return provider.userInfo?.is_admin ?? false;
  }

  Future<List<int>?> getFavoriteHoleId() async {
    if (provider.userInfo?.favorites != null) {
      return provider.userInfo?.favorites;
    }
    final Response<Map<String, dynamic>> response = await dio.get(
        "$_BASE_URL/user/favorites",
        queryParameters: {"plain": true},
        options: Options(headers: _tokenHeader));

    var results = response.data?['data']?.cast<int>() ?? [];
    // when setting fields, we must make sure that the user info is initialized.
    // Otherwise, this line has no effect at all, and we will save nothing.
    // And [getUserProfile] will do this.
    (await getUserProfile())?.favorites = results;
    return results;
  }

  Future<List<int>?> getSubscribedHoleId() async {
    if (provider.userInfo?.subscriptions != null) {
      return provider.userInfo?.subscriptions;
    }
    final Response<Map<String, dynamic>> response = await dio.get(
        "$_BASE_URL/users/subscriptions",
        queryParameters: {"plain": true},
        options: Options(headers: _tokenHeader));
    var results = response.data?['data']?.cast<int>();
    (await getUserProfile())?.subscriptions =
        response.data?['data']?.cast<int>();
    return results;
  }

  Future<List<OTHole>?> getFavoriteHoles({
    int length = Constant.POST_COUNT_PER_PAGE,
    int prefetchLength = Constant.POST_COUNT_PER_PAGE,
  }) async {
    final Response<List<dynamic>> response = await dio.get(
        "$_BASE_URL/user/favorites",
        queryParameters: {"length": length, "prefetch_length": prefetchLength},
        options: Options(headers: _tokenHeader));
    return response.data?.map((e) => OTHole.fromJson(e)).toList();
  }

  Future<List<OTHole>?> getSubscribedHoles({
    int length = Constant.POST_COUNT_PER_PAGE,
    int prefetchLength = Constant.POST_COUNT_PER_PAGE,
  }) async {
    final Response<List<dynamic>> response = await dio.get(
        "$_BASE_URL/users/subscriptions",
        queryParameters: {"length": length, "prefetch_length": prefetchLength},
        options: Options(headers: _tokenHeader));
    return response.data?.map((e) => OTHole.fromJson(e)).toList();
  }

  Future<void> setFavorite(SetStatusMode mode, int? holeId) async {
    Response<dynamic> response;
    switch (mode) {
      case SetStatusMode.ADD:
        response = await dio.post("$_BASE_URL/user/favorites",
            data: {'hole_id': holeId}, options: Options(headers: _tokenHeader));
        break;
      case SetStatusMode.DELETE:
        response = await dio.delete("$_BASE_URL/user/favorites",
            data: {'hole_id': holeId}, options: Options(headers: _tokenHeader));
        break;
    }
    final Map<String, dynamic> result = response.data;
    (await getUserProfile())?.favorites = result["data"]?.cast<int>();
  }

  Future<void> setSubscription(SetStatusMode mode, int? holeId) async {
    Response<dynamic> response;
    switch (mode) {
      case SetStatusMode.ADD:
        response = await dio.post("$_BASE_URL/users/subscriptions",
            data: {'hole_id': holeId}, options: Options(headers: _tokenHeader));
        break;
      case SetStatusMode.DELETE:
        response = await dio.delete("$_BASE_URL/users/subscription",
            data: {'hole_id': holeId}, options: Options(headers: _tokenHeader));
        break;
    }
    final Map<String, dynamic> result = response.data;
    (await getUserProfile())?.subscriptions = result["data"]?.cast<int>();
  }

  /// Modify a floor
  Future<int?> modifyFloor(String content, int? floorId) async {
    return (await dio.put("$_BASE_URL/floors/$floorId",
            data: {
              "content": content,
              //"mention": findMention(content),
            },
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  /// Delete a floor
  Future<int?> deleteFloor(int? floorId) async {
    return (await dio.delete("$_BASE_URL/floors/$floorId",
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  /// Get user's punishment history
  Future<List<OTPunishment>?> getPunishmentHistory() async {
    final Response<List<dynamic>> response = await dio.get(
        "$_BASE_URL/users/me/punishments",
        options: Options(headers: _tokenHeader));
    return response.data?.map((e) => OTPunishment.fromJson(e)).toList();
  }

  /// Admin API below
  Future<List<OTReport>?> adminGetReports(int startReport,
      [int length = 10]) async {
    final response = await dio.get("$_BASE_URL/reports",
        queryParameters: {"offset": startReport, "size": length},
        options: Options(headers: _tokenHeader));
    final result = response.data;
    return result.map<OTReport>((e) => OTReport.fromJson(e)).toList();
  }

  Future<List<OTAudit>?> adminGetAuditFloors(DateTime startTime, bool open,
      [int length = 10]) async {
    final response = await dio.get("$_BASE_URL/floors/_sensitive",
        queryParameters: {
          "offset": startTime.toUtc().toIso8601String(),
          "size": length,
          "all": false,
          "open": open,
          "order_by": "time_created"
        },
        options: Options(headers: _tokenHeader));
    final result = response.data;
    return result.map<OTAudit>((e) => OTAudit.fromJson(e)).toList();
  }

  Future<int?> adminSetAuditFloor(int floorId, bool isActualSensitive) async {
    return (await dio.put("$_BASE_URL/floors/$floorId/_sensitive",
            data: {"is_actual_sensitive": isActualSensitive},
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<int?> adminDeleteFloor(int? floorId, String? deleteReason) async {
    return (await dio.delete("$_BASE_URL/floors/$floorId",
            data: {
              if (deleteReason?.isNotEmpty == true)
                "delete_reason": deleteReason ?? ""
            },
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<List<OTHistory>?> getHistory(int? floorId) async {
    final Response<List<dynamic>> response = await dio.get(
        "$_BASE_URL/floors/$floorId/history",
        options: Options(headers: _tokenHeader));
    return response.data?.map((e) => OTHistory.fromJson(e)).toList();
  }

  Future<int?> adminDeleteHole(int? holeId) async {
    return (await dio.delete("$_BASE_URL/holes/$holeId",
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<int?> adminLockHole(int? holeId, bool lock) async {
    return (await dio.put("$_BASE_URL/holes/$holeId",
            data: {"lock": lock}, options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<int?> adminUndeleteHole(int? holeId) async {
    return (await dio.put("$_BASE_URL/holes/$holeId",
            data: {"unhidden": true}, options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  @Deprecated("Use adminAddPenaltyDays instead")
  Future<int?> adminAddPenalty(int? floorId, int penaltyLevel) async {
    return (await dio.post("$_BASE_URL/penalty/$floorId",
            data: jsonEncode({"penalty_level": penaltyLevel}),
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<int?> adminAddPenaltyDays(int? floorId, int penaltyDays) async {
    return (await dio.post("$_BASE_URL/penalty/$floorId",
            data: jsonEncode({"days": penaltyDays}),
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<int?> adminModifyDivision(
      int id, String? name, String? description, List<int>? pinned) async {
    return (await dio.put("$_BASE_URL/divisions/$id",
            data: jsonEncode({
              if (name != null) "name": name,
              if (description != null) "description": description,
              if (pinned != null) "pinned": pinned,
            }),
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<int?> adminAddSpecialTag(String tag, int? floorId) async {
    return (await dio.put("$_BASE_URL/floors/$floorId",
            data: {
              "special_tag": tag,
            },
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<int?> adminUpdateTagAndDivision(
      List<OTTag> tag, int? holeId, int? divisionId) async {
    return (await dio.put("$_BASE_URL/holes/$holeId",
            data: {"tags": tag, "division_id": divisionId},
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<int?> adminFoldFloor(List<String> fold, int? floorId) async {
    return (await dio.put("$_BASE_URL/floors/$floorId",
            data: {"fold": fold}, options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<int?> adminChangePassword(String email, String password) async {
    return (await dio.patch("$_BASE_URL/register",
            data: {"email": email, "password": password},
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<int?> adminSendMessage(String message, List<int> ids) async {
    return (await dio.post("$_BASE_URL/messages",
            data: {"description": message, "recipients": ids},
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<int?> adminSetReportDealt(int reportId) async {
    return (await dio.delete("$_BASE_URL/reports/$reportId",
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<List<String>?> adminGetPunishmentHistory(int floorId) async {
    final Response<List<dynamic>> response = await dio.get(
        "$_BASE_URL/floors/$floorId/punishment",
        options: Options(headers: _tokenHeader));
    return response.data?.map((e) => e as String).toList();
  }

  /// Upload or update Push Notification token to server
  Future<void> updatePushNotificationToken(
      String token, String id, PushNotificationServiceType service) async {
    if (provider.isUserInitialized) {
      lastUploadToken = token;
      await dio.put("$_BASE_URL/users/push-tokens",
          data: {
            "service": service.toStringRepresentation(),
            "device_id": id,
            "token": token,
          },
          options: Options(headers: _tokenHeader));
    } else {
      _pushNotificationRegData = PushNotificationRegData(id, token, service);
    }
  }

  Future<void> deletePushNotificationToken(String deviceId) async {
    await dio.delete("$_BASE_URL/users/push-tokens",
        data: {"device_id": deviceId}, options: Options(headers: _tokenHeader));
  }

  Future<int?> deleteAllPushNotificationToken() async {
    final resp = await dio.delete("$_BASE_URL/users/push-tokens/_all",
        options: Options(headers: _tokenHeader));
    return resp.statusCode;
  }

  Future<(List<QuizQuestion>?, int)> getPostRegisterQuestions() async {
    final Response<Map<String, dynamic>> response = await dio.get(
        "$_BASE_AUTH_URL/register/questions",
        options: Options(headers: _tokenHeader));
    final List<QuizQuestion>? questionList = response.data?["questions"]
        .map((e) => QuizQuestion.fromJson(e))
        .toList()
        .cast<QuizQuestion>();
    final int version = response.data?["version"];
    return (questionList, version);
  }

  // Empty list means all-correct
  Future<List<int>?> submitAnswers(
      List<QuizAnswer> answers, int version) async {
    final Response<Map<String, dynamic>> response = await dio.post(
        "$_BASE_AUTH_URL/register/questions/_answer",
        data: {
          "answers": answers.map((e) => e.toJson()).toList(),
          "version": version
        },
        options: Options(headers: _tokenHeader));

    if (response.data?["correct"]) {
      provider.token = SettingsProvider.getInstance().forumToken =
          JWToken.fromJson(response.data!);
      return [];
    }

    return response.data?["wrong_question_ids"].cast<int>();
  }

  @override
  String get linkHost => "api.fduhole.com";
}

enum PushNotificationServiceType { APNS, MIPUSH }

extension StringRepresentation on PushNotificationServiceType? {
  String? toStringRepresentation() {
    switch (this) {
      case PushNotificationServiceType.APNS:
        return 'apns';
      case PushNotificationServiceType.MIPUSH:
        return 'mipush';
      case null:
        return null;
    }
  }
}

enum SetStatusMode { ADD, DELETE }

class NotLoginError implements FatalException {
  final String errorMessage;

  NotLoginError(this.errorMessage);
}

class QuizUnansweredError implements FatalException {
  final String errorMessage;

  QuizUnansweredError(this.errorMessage);
}

class LoginExpiredError implements Exception {}

class PushNotificationRegData {
  final String deviceId, token;
  final PushNotificationServiceType type;

  PushNotificationRegData(this.deviceId, this.token, this.type);
}
