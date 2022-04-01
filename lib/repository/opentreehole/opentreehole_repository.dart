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

import 'package:asn1lib/asn1lib.dart';
import 'package:dan_xi/common/Secret.dart';
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/model/opentreehole/division.dart';
import 'package:dan_xi/model/opentreehole/floor.dart';
import 'package:dan_xi/model/opentreehole/hole.dart';
import 'package:dan_xi/model/opentreehole/message.dart';
import 'package:dan_xi/model/opentreehole/report.dart';
import 'package:dan_xi/model/opentreehole/tag.dart';
import 'package:dan_xi/model/opentreehole/user.dart';
import 'package:dan_xi/provider/fduhole_provider.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/util/opentreehole/fduhole_platform_bridge.dart';
import 'package:dan_xi/util/platform_universal.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class OpenTreeHoleRepository extends BaseRepositoryWithDio {
  static final _instance = OpenTreeHoleRepository._();

  factory OpenTreeHoleRepository.getInstance() => _instance;

  static const String _BASE_URL = "https://api.fduhole.com";

  static const String _IMAGE_BASE_URL = "https://pic.hath.top";

  late FDUHoleProvider provider;

  /// Cached floors, used by [mentions]
  List<OTFloor> _floorCache = [];

  /// Cached OTDivisions
  List<OTDivision> _divisionCache = [];

  /// Cached OTTags
  List<OTTag> _tagCache = [];

  /// Push Notification Registration Cache
  PushNotificationRegData? _pushNotificationRegData;

  String? lastUploadToken;

  static void init(FDUHoleProvider injectProvider) {
    OpenTreeHoleRepository.getInstance().provider = injectProvider;
  }

  Future<void> logout() async {
    if (!provider.isUserInitialized) {
      if (SettingsProvider.getInstance().fduholeToken == null) {
        return;
      } else {
        provider.token = SettingsProvider.getInstance().fduholeToken;
      }
      await deletePushNotificationToken(await PlatformX.getUniqueDeviceId());
    }
    clearCache();
    SettingsProvider.getInstance().deleteAllFduholeData();
  }

  void clearCache() {
    provider.token = null;
    provider.userInfo = null;
    _pushNotificationRegData = null;
    _floorCache = [];
    _divisionCache = [];
    _tagCache = [];
  }

  void cacheFloor(OTFloor floor) {
    _floorCache.remove(floor);
    _floorCache.add(floor);
    if (_floorCache.length > 200) {
      reduceFloorCache();
    }
  }

  void reduceFloorCache({int factor = 2}) {
    _floorCache = _floorCache.sublist(_floorCache.length ~/ factor);
  }

  OpenTreeHoleRepository._() {
    // Override the options set in parent class.
    dio!.options = BaseOptions(
      receiveDataWhenStatusError: true,
      validateStatus: (int? status) {
        if (status == 401) {
          // If token is invalid, clear the token.
          SettingsProvider.getInstance().fduholeToken = null;
        }
        return status != null && status >= 200 && status < 300;
      },
    );
  }

  void initializeToken() {
    if (SettingsProvider.getInstance().fduholeToken != null) {
      provider.token = SettingsProvider.getInstance().fduholeToken;
    } else {
      throw NotLoginError("No token");
    }
  }

  Future<void> initializeRepo() async {
    initializeToken();
    try {
      FDUHolePlatformBridge.registerRemoteNotification();
    } catch (_) {}

    if (provider.userInfo == null) await getUserProfile(forceUpdate: true);
    if (_divisionCache.isEmpty) await loadDivisions(useCache: false);
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
    final response = await secureDio.get(_BASE_URL + "/verify/apikey",
        queryParameters: {
          "apikey": Secret.generateOneTimeAPIKey(),
          "email": email,
          "check_register": 1,
        },
        options: Options(validateStatus: (code) => code! <= 409));
    return response.statusCode == 409;
  }

  Dio get secureDio {
    Dio secureDio = Dio();
    //Pin HTTPS cert
    (secureDio.httpClientAdapter as DefaultHttpClientAdapter)
        .onHttpClientCreate = (client) {
      final SecurityContext sc = SecurityContext(withTrustedRoots: false);
      HttpClient httpClient = HttpClient(context: sc);
      httpClient.badCertificateCallback =
          (X509Certificate certificate, String host, int port) {
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
    };
    return secureDio;
  }

  Future<String?> getVerifyCode(String email) async {
    Response<Map<String, dynamic>> response =
        await secureDio.get(_BASE_URL + "/verify/apikey",
            queryParameters: {
              "apikey": Secret.generateOneTimeAPIKey(),
              "email": email,
            },
            options: Options(validateStatus: (code) => code! < 300));
    return response.data?["code"].toString();
  }

  Future<void> requestEmailVerifyCode(String email) async {
    await dio!
        .get(_BASE_URL + "/verify/email", queryParameters: {"email": email});
  }

  Future<String?> register(
      String email, String password, String verifyCode) async {
    final Response<Map<String, dynamic>> response =
        await dio!.post(_BASE_URL + "/register", data: {
      "password": password,
      "email": email,
      "verification": int.parse(verifyCode),
    });
    return SettingsProvider.getInstance().fduholeToken =
        response.data!["token"];
  }

  Future<String?> loginWithUsernamePassword(
      String username, String password) async {
    final Response<Map<String, dynamic>> response =
        await dio!.post(_BASE_URL + "/login", data: {
      'email': username,
      'password': password,
    });
    return SettingsProvider.getInstance().fduholeToken =
        response.data!["token"];
  }

  Map<String, String> get _tokenHeader {
    if (provider.token == null) throw NotLoginError("Null Token");
    return {"Authorization": "Token " + provider.token!};
  }

  Future<List<OTDivision>?> loadDivisions({bool useCache = true}) async {
    if (_divisionCache.isNotEmpty && useCache) {
      return _divisionCache;
    }
    final Response<List<dynamic>> response = await dio!
        .get(_BASE_URL + "/divisions", options: Options(headers: _tokenHeader));
    _divisionCache =
        response.data?.map((e) => OTDivision.fromJson(e)).toList() ?? [];
    return _divisionCache;
  }

  List<OTHole> getPinned(int divisionId) {
    try {
      return _divisionCache
              .firstWhere((element) => element.division_id == divisionId)
              .pinned ??
          List<OTHole>.empty();
    } catch (ignored) {
      return List<OTHole>.empty();
    }
  }

  List<OTDivision> getDivisions() {
    return _divisionCache;
  }

  Future<OTDivision?> loadSpecificDivision(int divisionId,
      {bool useCache = true}) async {
    if (useCache) {
      try {
        final OTDivision cached =
            _divisionCache.firstWhere((e) => e.division_id == divisionId);
        return cached;
      } catch (_) {}
    }
    final Response<Map<String, dynamic>> response = await dio!.get(
        _BASE_URL + "/divisions/$divisionId",
        options: Options(headers: _tokenHeader));
    final newDivision = OTDivision.fromJson(response.data!);
    _divisionCache.removeWhere((element) => element.division_id == divisionId);
    _divisionCache.add(newDivision);
    return newDivision;
  }

  Future<List<OTHole>?> loadHoles(DateTime startTime, int divisionId,
      {int length = Constant.POST_COUNT_PER_PAGE,
      int prefetchLength = Constant.POST_COUNT_PER_PAGE,
      String? tag,
      SortOrder? sortOrder}) async {
    sortOrder ??= SortOrder.LAST_REPLIED;
    final Response<List<dynamic>> response =
        await dio!.get(_BASE_URL + "/holes",
            queryParameters: {
              "start_time": startTime.toIso8601String(),
              "division_id": divisionId,
              "length": length,
              "prefetch_length": prefetchLength,
              "tag": tag,
              "order": sortOrder.getInternalString()
            },
            options: Options(headers: _tokenHeader));
    return response.data?.map((e) => OTHole.fromJson(e)).toList();
  }

  Future<OTHole?> loadSpecificHole(int holeId) async {
    final Response<Map<String, dynamic>> response = await dio!.get(
        _BASE_URL + "/holes/$holeId",
        options: Options(headers: _tokenHeader));
    final hole = OTHole.fromJson(response.data!);
    for (var floor in hole.floors!.prefetch!) {
      cacheFloor(floor);
      floor.mention?.forEach((mention) {
        cacheFloor(mention);
      });
    }
    return hole;
  }

  Future<OTFloor?> loadSpecificFloor(int floorId) async {
    try {
      return _floorCache.lastWhere((element) => element.floor_id == floorId);
    } catch (ignored) {
      final Response<Map<String, dynamic>> response = await dio!.get(
          _BASE_URL + "/floors/$floorId",
          options: Options(headers: _tokenHeader));
      final floor = OTFloor.fromJson(response.data!);
      cacheFloor(floor);
      return floor;
    }
  }

  Future<List<OTFloor>?> loadFloors(OTHole post,
      {int startFloor = 0, int length = Constant.POST_COUNT_PER_PAGE}) async {
    final Response<List<dynamic>> response = await dio!.get(
        _BASE_URL + "/floors",
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
    final Response<List<dynamic>> response = await dio!.get(
        _BASE_URL + "/floors",
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
    final Response<List<dynamic>> response = await dio!
        .get(_BASE_URL + "/tags", options: Options(headers: _tokenHeader));
    return _tagCache = response.data!.map((e) => OTTag.fromJson(e)).toList();
  }

  Future<int?> newHole(int divisionId, String? content,
      {List<OTTag>? tags}) async {
    if (content == null) return -1;
    if (tags == null || tags.isEmpty) tags = [const OTTag(0, 0, "默认")];
    // Suppose user is logged in. He should be.
    final Response<dynamic> response = await dio!.post(_BASE_URL + "/holes",
        data: {
          "division_id": divisionId,
          "content": content,
          "tags": tags,
        },
        options: Options(headers: _tokenHeader));
    return response.statusCode;
  }

  Future<String?> uploadImage(File file) async {
    final RegExp tokenReg = RegExp(r'PF\.obj\.config\.auth_token = "(\w+)"');
    String path = file.absolute.path;
    String fileName = path.substring(path.lastIndexOf("/") + 1, path.length);
    Response<String> r = await dio!.get(_IMAGE_BASE_URL + "/upload");
    String? token = tokenReg.firstMatch(r.data!)?.group(1);
    Response<Map<String, dynamic>> response = await dio!
        .post<Map<String, dynamic>>(_IMAGE_BASE_URL + "/json",
            data: FormData.fromMap({
              "type": "file",
              "action": "upload",
              "auth_token": token!,
              "source": await MultipartFile.fromFile(path, filename: fileName)
            }),
            options: Options(headers: _tokenHeader))
        .onError(((error, stackTrace) {
      throw ImageUploadError();
    }));
    return response.data!['image']['display_url'];
  }

  String extractHighDefinitionImageUrl(String imageUrl) {
    if (imageUrl.contains(_IMAGE_BASE_URL) && imageUrl.contains(".md.")) {
      return imageUrl.replaceFirst(".md.", ".");
    }
    return imageUrl;
  }

  Future<int?> newFloor(int? discussionId, String content) async {
    final Response<dynamic> response = await dio!.post(_BASE_URL + "/floors",
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

  Future<OTFloor?> likeFloor(int floorId, bool like) async {
    final Response<Map<String, dynamic>> response =
        await dio!.put(_BASE_URL + "/floors/$floorId",
            data: {
              "like": like ? "add" : "cancel",
            },
            options: Options(headers: _tokenHeader));
    return OTFloor.fromJson(response.data!);
  }

  Future<int?> reportPost(int? postId, String reason) async {
    // Suppose user is logged in. He should be.
    final Response<dynamic> response = await dio!.post(_BASE_URL + "/reports",
        data: {"floor_id": postId, "reason": reason},
        options: Options(headers: _tokenHeader));
    return response.statusCode;
  }

  OTUser? get userInfo => provider.userInfo;

  set userInfo(OTUser? value) {
    provider.userInfo = value;
    updateUserProfile();
  }

  Future<OTUser?> getUserProfile({bool forceUpdate = false}) async {
    if (provider.userInfo == null || forceUpdate) {
      final Response<Map<String, dynamic>> response = await dio!
          .get(_BASE_URL + "/users", options: Options(headers: _tokenHeader));
      provider.userInfo = OTUser.fromJson(response.data!);
    }
    return provider.userInfo;
  }

  Future<OTUser?> updateUserProfile() async {
    final Response<Map<String, dynamic>> response = await dio!.put(
        _BASE_URL + "/users",
        data: provider.userInfo!.toJson(),
        options: Options(headers: _tokenHeader));
    return provider.userInfo = OTUser.fromJson(response.data!);
  }

  Future<void> updateHoleViewCount(int holeId) async {
    await dio!.patch(_BASE_URL + "/holes/$holeId",
        options: Options(headers: _tokenHeader));
  }

  Future<List<OTMessage>?> loadMessages(
      {bool unreadOnly = false, DateTime? startTime}) async {
    final Response<List<dynamic>> response =
        await dio!.get(_BASE_URL + "/messages",
            queryParameters: {
              "not_read": unreadOnly,
              "start_time": startTime?.toIso8601String(),
            },
            options: Options(headers: _tokenHeader));
    return response.data?.map((e) => OTMessage.fromJson(e)).toList();
  }

  Future<void> modifyMessage(OTMessage message) async {
    await dio!.put(_BASE_URL + "/messages/${message.message_id}",
        data: {
          "has_read": message.has_read,
        },
        options: Options(headers: _tokenHeader));
  }

  Future<void> clearMessages() async {
    await dio!.put(_BASE_URL + "/messages",
        data: {
          "clear_all": true,
        },
        options: Options(headers: _tokenHeader));
  }

  Future<bool?> isUserAdmin() async {
    return (await getUserProfile())!.is_admin;
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

  Future<List<int>?> getFavoriteHoleId({bool forceUpdate = false}) async {
    return (await getUserProfile(forceUpdate: forceUpdate))!.favorites!;
  }

  Future<List<OTHole>?> getFavoriteHoles({
    int length = Constant.POST_COUNT_PER_PAGE,
    int prefetchLength = Constant.POST_COUNT_PER_PAGE,
  }) async {
    final Response<List<dynamic>> response = await dio!.get(
        _BASE_URL + "/user/favorites",
        queryParameters: {"length": length, "prefetch_length": prefetchLength},
        options: Options(headers: _tokenHeader));
    return response.data?.map((e) => OTHole.fromJson(e)).toList();
  }

  Future<void> setFavorite(SetFavoriteMode mode, int? holeId) async {
    Response<dynamic> response;
    switch (mode) {
      case SetFavoriteMode.ADD:
        response = await dio!.post(_BASE_URL + "/user/favorites",
            data: {'hole_id': holeId}, options: Options(headers: _tokenHeader));
        break;
      case SetFavoriteMode.DELETE:
        response = await dio!.delete(_BASE_URL + "/user/favorites",
            data: {'hole_id': holeId}, options: Options(headers: _tokenHeader));
        break;
    }
    if (provider.userInfo?.favorites != null) {
      final Map<String, dynamic> result = response.data;
      provider.userInfo!.favorites = result["data"].cast<int>();
    }
  }

  /// Modify a floor
  Future<int?> modifyFloor(String content, int? floorId) async {
    return (await dio!.put(_BASE_URL + "/floors/$floorId",
            data: {
              "content": content,
              //"mention": findMention(content),
            },
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  /// Delete a floor
  Future<int?> deleteFloor(int? floorId) async {
    return (await dio!.delete(_BASE_URL + "/floors/$floorId",
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  /// Admin API below
  Future<List<OTReport>?> adminGetReports() async {
    final response = await dio!.get(_BASE_URL + "/reports",
        //queryParameters: {"category": page, "show_only_undealt": true},
        options: Options(headers: _tokenHeader));
    final result = response.data;
    return result.map<OTReport>((e) => OTReport.fromJson(e)).toList();
  }

  Future<int?> adminDeleteFloor(int? floorId, String? deleteReason) async {
    return (await dio!.delete(_BASE_URL + "/floors/$floorId",
            data: {
              if (deleteReason?.isNotEmpty == true)
                "delete_reason": deleteReason ?? ""
            },
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<int?> adminDeleteHole(int? holeId) async {
    return (await dio!.delete(_BASE_URL + "/holes/$holeId",
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<int?> adminAddPenalty(
      int? floorId, int penaltyLevel, int divisionId) async {
    return (await dio!.post(_BASE_URL + "/penalty/$floorId",
            data: jsonEncode(
                {"penalty_level": penaltyLevel, "division_id": divisionId}),
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<int?> adminModifyDivision(
      int id, String? name, String? description, List<int>? pinned) async {
    return (await dio!.put(_BASE_URL + "/divisions/$id",
            data: jsonEncode({
              if (name != null) "name": name,
              if (description != null) "description": description,
              if (pinned != null) "pinned": pinned,
            }),
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<int?> adminAddSpecialTag(String tag, int? floorId) async {
    return (await dio!.put(_BASE_URL + "/floors/$floorId",
            data: {
              "special_tag": tag,
            },
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<int?> adminUpdateTagAndDivision(
      List<OTTag> tag, int? holeId, int? divisionId) async {
    return (await dio!.put(_BASE_URL + "/holes/$holeId",
            data: {"tags": tag, "division_id": divisionId},
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<int?> adminFoldFloor(List<String> fold, int? floorId) async {
    return (await dio!.put(_BASE_URL + "/floors/$floorId",
            data: {"fold": fold}, options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<int?> adminChangePassword(String email, String password) async {
    return (await dio!.patch(_BASE_URL + "/register",
            data: {"email": email, "password": password},
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  Future<int?> adminSetReportDealt(int reportId) async {
    return (await dio!.delete(_BASE_URL + "/reports/$reportId",
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  /// Upload or update Push Notification token to server
  Future<void> updatePushNotificationToken(
      String token, String id, PushNotificationServiceType service) async {
    if (provider.isUserInitialized) {
      lastUploadToken = token;
      await dio!.put(_BASE_URL + "/users/push-tokens",
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
    await dio!.delete(_BASE_URL + "/users/push-tokens",
        data: {"device_id": deviceId}, options: Options(headers: _tokenHeader));
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

enum SetFavoriteMode { ADD, DELETE }

class NotLoginError implements FatalException {
  final String errorMessage;

  NotLoginError(this.errorMessage);
}

class LoginExpiredError implements Exception {}

class ImageUploadError implements Exception {}

class PushNotificationRegData {
  final String deviceId, token;
  final PushNotificationServiceType type;

  PushNotificationRegData(this.deviceId, this.token, this.type);
}
