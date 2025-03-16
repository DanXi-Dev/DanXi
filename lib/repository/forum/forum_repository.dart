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
import 'package:dan_xi/util/webvpn_proxy.dart';
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
    await initializeUser();

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
    final options = RequestOptions(
        path: "$_BASE_AUTH_URL/verify/email",
        method: "GET",
        queryParameters: {"email": email, "check": true},
        validateStatus: (status) => status != null && status <= 400);
    final Response<Map<String, dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
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
    final options = RequestOptions(
        path: "$_BASE_AUTH_URL/verify/email",
        method: "GET",
        queryParameters: {"email": email});
    await WebvpnProxy.requestWithProxy(dio, options);
  }

  Future<JWToken?> register(
      String email, String password, String verifyCode) async {
    final options =
        RequestOptions(path: "$_BASE_AUTH_URL/register", method: "POST", data: {
      "password": password,
      "email": email,
      "verification": int.parse(verifyCode),
    });
    final Response<Map<String, dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return SettingsProvider.getInstance().forumToken =
        JWToken.fromJsonWithVerification(response.data!);
  }

  Future<JWToken?> loginWithUsernamePassword(
      String username, String password) async {
    final options =
        RequestOptions(path: "$_BASE_AUTH_URL/login", method: "POST", data: {
      'email': username,
      'password': password,
    });
    final Response<Map<String, dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
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
    final options = RequestOptions(
        path: "$_BASE_URL/divisions", method: "GET", headers: _tokenHeader);
    final Response<List<dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
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
    final options = RequestOptions(
        path: "$_BASE_URL/divisions/$divisionId",
        method: "GET",
        headers: _tokenHeader);
    final Response<Map<String, dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
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
    final options = RequestOptions(
        path: "$_BASE_URL/holes",
        method: "GET",
        queryParameters: {
          "start_time": startTime.toUtc().toIso8601String(),
          "division_id": divisionId,
          "length": length,
          "tag": tag,
          "order": sortOrder.getInternalString()
        },
        headers: _tokenHeader);

    final Response<List<dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return response.data?.map((e) => OTHole.fromJson(e)).toList();
  }

  Future<List<OTHole>?> loadUserHoles(DateTime startTime,
      {int length = Constant.POST_COUNT_PER_PAGE, SortOrder? sortOrder}) async {
    sortOrder ??= SortOrder.LAST_REPLIED;

    final options = RequestOptions(
        path: "$_BASE_URL/users/me/holes",
        method: "GET",
        queryParameters: {
          "offset": startTime.toUtc().toIso8601String(),
          "size": length,
          "order": sortOrder.getInternalString()
        },
        headers: _tokenHeader);
    final Response<List<dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return response.data?.map((e) => OTHole.fromJson(e)).toList();
  }

  // NEVER USED
  Future<OTHole?> loadHoleById(int holeId) async {
    final options = RequestOptions(
        path: "$_BASE_URL/holes/$holeId", method: "GET", headers: _tokenHeader);
    final Response<Map<String, dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    final hole = OTHole.fromJson(response.data!);
    return hole;
  }

  Future<List<OTHole>?> loadHolesById(Iterable<int> holeIds) async {
    // We can only do this without a new upstream API
    List<OTHole> result = [];
    for (var holeId in holeIds) {
      try {
        OTHole? hole = await loadHoleById(holeId);
        if (hole == null) {
          throw NotNullableError("Hole shouldn't be null");
        }
        result.add(hole);
      } catch (e) {
        return null;
      }
    }

    assert(result.length == holeIds.length);
    return result;
  }

  Future<OTFloor?> loadFloorById(int floorId) async {
    final result = _floorCache[floorId];
    if (result != null) {
      return result;
    }

    final options = RequestOptions(
        path: "$_BASE_URL/floors/$floorId",
        method: "GET",
        headers: _tokenHeader);
    final Response<Map<String, dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    final floor = OTFloor.fromJson(response.data!);
    cacheFloor(floor);
    return floor;
  }

  Future<List<OTFloor>?> loadFloors(OTHole post,
      {int startFloor = 0, int length = Constant.POST_COUNT_PER_PAGE}) async {
    final options = RequestOptions(
        path: "$_BASE_URL/floors",
        method: "GET",
        queryParameters: {
          "start_floor": startFloor,
          "hole_id": post.hole_id,
          "length": length
        },
        headers: _tokenHeader);
    final Response<List<dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    final floors = response.data?.map((e) => OTFloor.fromJson(e)).toList();
    for (var element in floors!) {
      cacheFloor(element);
      element.mention?.forEach((mention) {
        cacheFloor(mention);
      });
    }
    return floors;
  }

  Future<List<OTFloor>?> loadUserFloors(
      {int startFloor = 0, int length = Constant.POST_COUNT_PER_PAGE}) async {
    final options = RequestOptions(
        path: "$_BASE_URL/users/me/floors",
        method: "GET",
        queryParameters: {"offset": startFloor, "size": length},
        headers: _tokenHeader);
    final Response<List<dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return response.data?.map((e) => OTFloor.fromJson(e)).toList();
  }

  Future<List<OTFloor>?> loadSearchResults(String? searchString,
      {int? startFloor, int length = Constant.POST_COUNT_PER_PAGE}) async {
    final options = RequestOptions(
        path: "$_BASE_URL/floors",
        method: "GET",
        queryParameters: {
          "start_floor": startFloor,
          "s": searchString,
          "length": length,
        },
        headers: _tokenHeader);
    final Response<List<dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return response.data?.map((e) => OTFloor.fromJson(e)).toList();
  }

  Future<List<OTTag>?> loadTags({bool useCache = true}) async {
    if (useCache && _tagCache.isNotEmpty) {
      return _tagCache;
    }
    final options = RequestOptions(
        path: "$_BASE_URL/tags", method: "GET", headers: _tokenHeader);
    final Response<List<dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return _tagCache = response.data!.map((e) => OTTag.fromJson(e)).toList();
  }

  Future<int?> newHole(int divisionId, String? content,
      {List<OTTag>? tags}) async {
    if (content == null) return -1;
    if (tags == null || tags.isEmpty) tags = [const OTTag(0, 0, KEY_NO_TAG)];
    // Suppose user is logged in. He should be.
    final options = RequestOptions(
        path: "$_BASE_URL/holes",
        method: "POST",
        data: {
          "division_id": divisionId,
          "content": content,
          "tags": tags,
        },
        headers: _tokenHeader);
    final Response<dynamic> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return response.statusCode;
  }

  Future<String?> uploadImage(File file) async {
    String path = file.absolute.path;
    String fileName = path.substring(path.lastIndexOf("/") + 1, path.length);
    final options = RequestOptions(
        path: "$_IMAGE_BASE_URL/json",
        method: "POST",
        data: FormData.fromMap(
            {"source": await MultipartFile.fromFile(path, filename: fileName)}),
        headers: _tokenHeader);
    Response<Map<String, dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return response.data!['image']['display_url'];
  }

  String extractHighDefinitionImageUrl(String imageUrl) {
    if (imageUrl.contains(_IMAGE_BASE_URL) && imageUrl.contains(".md.")) {
      return imageUrl.replaceFirst(".md.", ".");
    }
    return imageUrl;
  }

  Future<int?> newFloor(int? discussionId, String content) async {
    final options = RequestOptions(
        path: "$_BASE_URL/floors",
        method: "POST",
        data: {
          "content": content,
          "hole_id": discussionId,
          //"mention": findMention(content)
        },
        headers: _tokenHeader);
    final Response<dynamic> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return response.statusCode;
  }

  /*List<int?> findMention(String content) {
    final matches =
        RegExp(MENTION_REGEX_STRING, multiLine: true).allMatches(content);
    final result = matches.map((e) => int.tryParse(e.group(1) ?? ""));
    return result.where((element) => element != null).toList();
  }*/

  Future<OTFloor?> likeFloor(int floorId, int like) async {
    final options = RequestOptions(
        path: "$_BASE_URL/floors/$floorId/like/$like",
        method: "POST",
        headers: _tokenHeader);
    final Response<Map<String, dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return OTFloor.fromJson(response.data!);
  }

  Future<int?> reportPost(int? postId, String reason) async {
    final options = RequestOptions(
        path: "$_BASE_URL/reports",
        method: "POST",
        data: {"floor_id": postId, "reason": reason},
        headers: _tokenHeader);
    final Response<dynamic> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return response.statusCode;
  }

  /// Note: this method should return a mutable reference to the provider's user info.
  /// i.e. [provider.userInfo].
  Future<OTUser?> getUserProfile({bool forceUpdate = false}) async {
    if (provider.userInfo == null || forceUpdate) {
      final options = RequestOptions(
          path: "$_BASE_URL/users/me", method: "GET", headers: _tokenHeader);
      final Response<Map<String, dynamic>> response =
          await WebvpnProxy.requestWithProxy(dio, options);
      provider.userInfo = OTUser.fromJson(response.data!);
      provider.userInfo?.favorites = null;
      provider.userInfo?.subscriptions = null;
    }
    return provider.userInfo;
  }

  Future<OTUser?> updateUserProfile() async {
    final options = RequestOptions(
        path: "$_BASE_URL/users/${provider.userInfo!.user_id}/_webvpn",
        method: "PATCH",
        data: provider.userInfo!.toJson(),
        headers: _tokenHeader);
    final Response<Map<String, dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    provider.userInfo = OTUser.fromJson(response.data!);
    provider.userInfo?.favorites = null;
    provider.userInfo?.subscriptions = null;
    return provider.userInfo;
  }

  Future<void> updateHoleViewCount(int holeId) async {
    final options = RequestOptions(
        path: "$_BASE_URL/holes/$holeId",
        method: "PATCH",
        headers: _tokenHeader);
    await WebvpnProxy.requestWithProxy(dio, options);
  }

  Future<List<OTMessage>?> loadMessages(
      {bool unreadOnly = false, DateTime? startTime}) async {
    final options = RequestOptions(
        path: "$_BASE_URL/messages",
        method: "GET",
        queryParameters: {
          "not_read": unreadOnly,
          "start_time": startTime?.toUtc().toIso8601String(),
        },
        headers: _tokenHeader);
    final Response<List<dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return response.data?.map((e) => OTMessage.fromJson(e)).toList();
  }

  Future<void> modifyMessage(OTMessage message) async {
    final options = RequestOptions(
        path: "$_BASE_URL/messages/${message.message_id}",
        method: "DELETE",
        data: {
          "has_read": message.has_read,
        },
        headers: _tokenHeader);
    await WebvpnProxy.requestWithProxy(dio, options);
  }

  Future<void> clearMessages() async {
    final options = RequestOptions(
        path: "$_BASE_URL/messages/_webvpn",
        method: "PATCH",
        data: {
          "clear_all": true,
        },
        headers: _tokenHeader);
    await WebvpnProxy.requestWithProxy(dio, options);
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
    final options = RequestOptions(
        path: "$_BASE_URL/user/favorites",
        method: "GET",
        queryParameters: {"plain": true},
        headers: _tokenHeader);
    final Response<Map<String, dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);

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
    final options = RequestOptions(
        path: "$_BASE_URL/users/subscriptions",
        method: "GET",
        queryParameters: {"plain": true},
        headers: _tokenHeader);
    final Response<Map<String, dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    var results = response.data?['data']?.cast<int>();
    (await getUserProfile())?.subscriptions =
        response.data?['data']?.cast<int>();
    return results;
  }

  Future<List<OTHole>?> getFavoriteHoles({
    int length = Constant.POST_COUNT_PER_PAGE,
    int prefetchLength = Constant.POST_COUNT_PER_PAGE,
  }) async {
    final options = RequestOptions(
        path: "$_BASE_URL/user/favorites",
        method: "GET",
        queryParameters: {"length": length, "prefetch_length": prefetchLength},
        headers: _tokenHeader);
    final Response<List<dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return response.data?.map((e) => OTHole.fromJson(e)).toList();
  }

  Future<List<OTHole>?> getSubscribedHoles({
    int length = Constant.POST_COUNT_PER_PAGE,
    int prefetchLength = Constant.POST_COUNT_PER_PAGE,
  }) async {
    final options = RequestOptions(
        path: "$_BASE_URL/users/subscriptions",
        method: "GET",
        queryParameters: {"length": length, "prefetch_length": prefetchLength},
        headers: _tokenHeader);
    final Response<List<dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return response.data?.map((e) => OTHole.fromJson(e)).toList();
  }

  Future<void> setFavorite(SetStatusMode mode, int? holeId) async {
    Response<dynamic> response;
    RequestOptions options;
    switch (mode) {
      case SetStatusMode.ADD:
        options = RequestOptions(
            path: "$_BASE_URL/user/favorites",
            method: "POST",
            data: {'hole_id': holeId},
            headers: _tokenHeader);
        response = await WebvpnProxy.requestWithProxy(dio, options);
        break;
      case SetStatusMode.DELETE:
        options = RequestOptions(
            path: "$_BASE_URL/user/favorites",
            method: "DELETE",
            data: {'hole_id': holeId},
            headers: _tokenHeader);
        response = await WebvpnProxy.requestWithProxy(dio, options);
        break;
    }
    final Map<String, dynamic> result = response.data;
    (await getUserProfile())?.favorites = result["data"]?.cast<int>();
  }

  Future<void> setSubscription(SetStatusMode mode, int? holeId) async {
    Response<dynamic> response;
    RequestOptions options;
    switch (mode) {
      case SetStatusMode.ADD:
        options = RequestOptions(
            path: "$_BASE_URL/users/subscriptions",
            method: "POST",
            data: {'hole_id': holeId},
            headers: _tokenHeader);
        response = await WebvpnProxy.requestWithProxy(dio, options);
        break;
      case SetStatusMode.DELETE:
        options = RequestOptions(
            path: "$_BASE_URL/users/subscriptions",
            method: "DELETE",
            data: {'hole_id': holeId},
            headers: _tokenHeader);
        response = await WebvpnProxy.requestWithProxy(dio, options);
        break;
    }
    final Map<String, dynamic> result = response.data;
    (await getUserProfile())?.subscriptions = result["data"]?.cast<int>();
  }

  /// Modify a floor
  Future<int?> modifyFloor(String content, int? floorId) async {
    final options = RequestOptions(
        path: "$_BASE_URL/floors/$floorId/_webvpn",
        method: "PATCH",
        data: {
          "content": content,
          //"mention": findMention(content),
        },
        headers: _tokenHeader);
    return (await WebvpnProxy.requestWithProxy(dio, options)).statusCode;
  }

  /// Delete a floor
  Future<int?> deleteFloor(int? floorId) async {
    final options = RequestOptions(
        path: "$_BASE_URL/floors/$floorId",
        method: "DELETE",
        headers: _tokenHeader);
    return (await WebvpnProxy.requestWithProxy(dio, options)).statusCode;
  }

  /// Get user's punishment history
  Future<List<OTPunishment>?> getPunishmentHistory() async {
    final options = RequestOptions(
        path: "$_BASE_URL/users/me/punishments",
        method: "GET",
        headers: _tokenHeader);
    final Response<List<dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return response.data?.map((e) => OTPunishment.fromJson(e)).toList();
  }

  /// Admin API below
  Future<List<OTReport>?> adminGetReports(int startReport,
      [int length = 10]) async {
    final options = RequestOptions(
        path: "$_BASE_URL/reports",
        method: "GET",
        queryParameters: {"offset": startReport, "size": length},
        headers: _tokenHeader);
    final response = await WebvpnProxy.requestWithProxy(dio, options);
    final result = response.data;
    return result.map<OTReport>((e) => OTReport.fromJson(e)).toList();
  }

  Future<List<OTAudit>?> adminGetAuditFloors(DateTime startTime, bool open,
      [int length = 10]) async {
    final options = RequestOptions(
        path: "$_BASE_URL/floors/_sensitive",
        method: "GET",
        queryParameters: {
          "offset": startTime.toUtc().toIso8601String(),
          "size": length,
          "all": false,
          "open": open,
          "order_by": "time_created"
        },
        headers: _tokenHeader);
    final response = await WebvpnProxy.requestWithProxy(dio, options);
    final result = response.data;
    return result.map<OTAudit>((e) => OTAudit.fromJson(e)).toList();
  }

  Future<int?> adminSetAuditFloor(int floorId, bool isActualSensitive) async {
    final options = RequestOptions(
        path: "$_BASE_URL/floors/$floorId/_sensitive/_webvpn",
        method: "PATCH",
        data: {"is_actual_sensitive": isActualSensitive},
        headers: _tokenHeader);
    return (await WebvpnProxy.requestWithProxy(dio, options)).statusCode;
  }

  Future<int?> adminDeleteFloor(int? floorId, String? deleteReason) async {
    final options = RequestOptions(
        path: "$_BASE_URL/floors/$floorId",
        method: "DELETE",
        data: {
          if (deleteReason?.isNotEmpty == true)
            "delete_reason": deleteReason ?? ""
        },
        headers: _tokenHeader);
    return (await WebvpnProxy.requestWithProxy(dio, options)).statusCode;
  }

  Future<List<OTHistory>?> getHistory(int? floorId) async {
    final options = RequestOptions(
        path: "$_BASE_URL/floors/$floorId/history",
        method: "GET",
        headers: _tokenHeader);
    final Response<List<dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return response.data?.map((e) => OTHistory.fromJson(e)).toList();
  }

  Future<int?> adminDeleteHole(int? holeId) async {
    final options = RequestOptions(
        path: "$_BASE_URL/holes/$holeId",
        method: "DELETE",
        headers: _tokenHeader);
    return (await WebvpnProxy.requestWithProxy(dio, options)).statusCode;
  }

  Future<int?> adminLockHole(int? holeId, bool lock) async {
    final options = RequestOptions(
        path: "$_BASE_URL/holes/$holeId/_webvpn",
        method: "PATCH",
        data: {"lock": lock},
        headers: _tokenHeader);
    return (await WebvpnProxy.requestWithProxy(dio, options)).statusCode;
  }

  Future<int?> adminUndeleteHole(int? holeId) async {
    final options = RequestOptions(
        path: "$_BASE_URL/holes/$holeId/_webvpn",
        method: "PATCH",
        data: {"unhidden": true},
        headers: _tokenHeader);
    return (await WebvpnProxy.requestWithProxy(dio, options)).statusCode;
  }

  @Deprecated("Use adminAddPenaltyDays instead")
  Future<int?> adminAddPenalty(int? floorId, int penaltyLevel) async {
    final options = RequestOptions(
        path: "$_BASE_URL/penalty/$floorId",
        method: "POST",
        data: jsonEncode({"penalty_level": penaltyLevel}),
        headers: _tokenHeader);
    return (await WebvpnProxy.requestWithProxy(dio, options)).statusCode;
  }

  Future<int?> adminAddPenaltyDays(int? floorId, int penaltyDays) async {
    final options = RequestOptions(
        path: "$_BASE_URL/penalty/$floorId",
        method: "POST",
        data: jsonEncode({"days": penaltyDays}),
        headers: _tokenHeader);
    return (await WebvpnProxy.requestWithProxy(dio, options)).statusCode;
  }

  Future<int?> adminModifyDivision(
      int id, String? name, String? description, List<int>? pinned) async {
    final options = RequestOptions(
        path: "$_BASE_URL/divisions/$id/_webvpn",
        method: "PATCH",
        data: jsonEncode({
          if (name != null) "name": name,
          if (description != null) "description": description,
          if (pinned != null) "pinned": pinned,
        }),
        headers: _tokenHeader);
    return (await WebvpnProxy.requestWithProxy(dio, options)).statusCode;
  }

  Future<int?> adminAddSpecialTag(String tag, int? floorId) async {
    final options = RequestOptions(
        path: "$_BASE_URL/floors/$floorId/_webvpn",
        method: "PATCH",
        data: {
          "special_tag": tag,
        },
        headers: _tokenHeader);
    return (await WebvpnProxy.requestWithProxy(dio, options)).statusCode;
  }

  Future<int?> adminUpdateTagAndDivision(
      List<OTTag> tag, int? holeId, int? divisionId) async {
    final options = RequestOptions(
        path: "$_BASE_URL/holes/$holeId/_webvpn",
        method: "PATCH",
        data: {"tags": tag, "division_id": divisionId},
        headers: _tokenHeader);
    return (await WebvpnProxy.requestWithProxy(dio, options)).statusCode;
  }

  Future<int?> adminFoldFloor(List<String> fold, int? floorId) async {
    final options = RequestOptions(
        path: "$_BASE_URL/floors/$floorId/_webvpn",
        method: "PATCH",
        data: {"fold": fold},
        headers: _tokenHeader);
    return (await WebvpnProxy.requestWithProxy(dio, options)).statusCode;
  }

  Future<int?> adminChangePassword(String email, String password) async {
    final options = RequestOptions(
        path: "$_BASE_URL/register",
        method: "PATCH",
        data: {"email": email, "password": password},
        headers: _tokenHeader);
    return (await WebvpnProxy.requestWithProxy(dio, options)).statusCode;
  }

  Future<int?> adminSendMessage(String message, List<int> ids) async {
    final options = RequestOptions(
        path: "$_BASE_URL/messages",
        method: "POST",
        data: {"description": message, "recipients": ids},
        headers: _tokenHeader);
    return (await WebvpnProxy.requestWithProxy(dio, options)).statusCode;
  }

  Future<int?> adminSetReportDealt(int reportId) async {
    final options = RequestOptions(
        path: "$_BASE_URL/reports/$reportId",
        method: "DELETE",
        headers: _tokenHeader);
    return (await WebvpnProxy.requestWithProxy(dio, options)).statusCode;
  }

  Future<List<String>?> adminGetPunishmentHistory(int floorId) async {
    final options = RequestOptions(
        path: "$_BASE_URL/floors/$floorId/punishment",
        method: "GET",
        headers: _tokenHeader);
    final Response<List<dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
    return response.data?.map((e) => e as String).toList();
  }

  /// Upload or update Push Notification token to server
  Future<void> updatePushNotificationToken(
      String token, String id, PushNotificationServiceType service) async {
    if (provider.isUserInitialized) {
      lastUploadToken = token;
      final options = RequestOptions(
          path: "$_BASE_URL/users/push-tokens/_webvpn",
          method: "PATCH",
          data: {
            "service": service.toStringRepresentation(),
            "device_id": id,
            "token": token,
          },
          headers: _tokenHeader);
      await WebvpnProxy.requestWithProxy(dio, options);
    } else {
      _pushNotificationRegData = PushNotificationRegData(id, token, service);
    }
  }

  Future<void> deletePushNotificationToken(String deviceId) async {
    final options = RequestOptions(
        path: "$_BASE_URL/users/push-tokens",
        method: "DELETE",
        data: {"device_id": deviceId},
        headers: _tokenHeader);
    await WebvpnProxy.requestWithProxy(dio, options);
  }

  Future<int?> deleteAllPushNotificationToken() async {
    final options = RequestOptions(
        path: "$_BASE_URL/users/push-tokens/_all",
        method: "DELETE",
        headers: _tokenHeader);
    final resp = await WebvpnProxy.requestWithProxy(dio, options);
    return resp.statusCode;
  }

  Future<(List<QuizQuestion>?, int)> getPostRegisterQuestions() async {
    final options = RequestOptions(
        path: "$_BASE_AUTH_URL/register/questions",
        method: "GET",
        headers: _tokenHeader);
    final Response<Map<String, dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);
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
    final options = RequestOptions(
        path: "$_BASE_AUTH_URL/register/questions/_answer",
        method: "POST",
        data: {
          "answers": answers.map((e) => e.toJson()).toList(),
          "version": version
        },
        headers: _tokenHeader);
    final Response<Map<String, dynamic>> response =
        await WebvpnProxy.requestWithProxy(dio, options);

    if (response.data?["correct"]) {
      provider.token = SettingsProvider.getInstance().forumToken =
          JWToken.fromJson(response.data!);
      return [];
    }

    return response.data?["wrong_question_ids"].cast<int>();
  }

  @override
  String get linkHost => "api.fduhole.com";

  @override
  bool get isWebvpnApplicable => true;
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
