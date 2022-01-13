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
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/util/platform_bridge.dart';
import 'package:dan_xi/widget/libraries/paged_listview.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class OpenTreeHoleRepository extends BaseRepositoryWithDio {
  static final _instance = OpenTreeHoleRepository._();

  factory OpenTreeHoleRepository.getInstance() => _instance;

  static const String _BASE_URL = "https://hole.hath.top";

  /// The token used for session authentication.
  String? _token;

  /// Current user profile, stored as cache by the repository
  OTUser? _userInfo;

  /// Cached floors, used by [mentions]
  List<OTFloor> _floorCache = [];
  void cacheFloor(OTFloor floor) {
    _floorCache.remove(floor);
    _floorCache.add(floor);
  }

  /// Cached divisions
  List<OTDivision> _divisionCache = [];

  /// Push Notification Registration Cache
  PushNotificationRegData? _pushNotificationRegData;

  Future<void> logout() async {
    if (SettingsProvider.getInstance().lastPushToken != null) {
      if (!isUserInitialized) {
        if (SettingsProvider.getInstance().fduholeToken == null) {
          return;
        } else {
          _token = SettingsProvider.getInstance().fduholeToken;
        }
      }
      await deletePushNotificationToken(
          SettingsProvider.getInstance().lastPushToken!);
    }
    clearCache();
    SettingsProvider.getInstance().deleteAllFduholeData();
  }

  void clearCache() {
    _token = null;
    _userInfo = null;
    _pushNotificationRegData = null;
    _floorCache = [];
    _divisionCache = [];
  }

  OpenTreeHoleRepository._() {
    // Override the options set in parent class.
    dio!.options = BaseOptions(receiveDataWhenStatusError: true);
  }

  Future<void> initializeRepo() async {
    debugPrint(
        "WARNING: Certificate Pinning Disabled. Do not use for production builds.");
    if (SettingsProvider.getInstance().fduholeToken != null) {
      _token = SettingsProvider.getInstance().fduholeToken;
    } else {
      throw NotLoginError("No token");
    }

    try {
      PlatformBridge.registerRemoteNotification();
    } catch (ignored) {}

    if (_userInfo == null) await getUserProfile(forceUpdate: true);
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

  Future<bool> checkRegisterStatus(String email) async {
    Response response = await dio!.get(_BASE_URL + "/verify/apikey",
        queryParameters: {
          "apikey": Secret.generateOneTimeAPIKey(),
          "email": email,
          "check_register": 1,
        },
        options: Options(validateStatus: (code) => code! <= 409));
    return response.statusCode == 409;
  }

  Future<String?> getVerifyCode(String email) async {
    Response response = await dio!.get(_BASE_URL + "/verify/apikey",
        queryParameters: {
          "apikey": Secret.generateOneTimeAPIKey(),
          "email": email,
        },
        options: Options(validateStatus: (code) => code! < 300));
    final json =
        response.data is Map ? response.data : jsonDecode(response.data);
    return json["code"]?.toString();
  }

  Future<void> requestEmailVerifyCode(String email) async {
    await dio!
        .get(_BASE_URL + "/verify/email", queryParameters: {"email": email});
  }

  Future<String?> register(
      String email, String password, String verifyCode) async {
    final Response response = await dio!.post(_BASE_URL + "/register", data: {
      "password": password,
      "email": email,
      "verification": int.parse(verifyCode),
    });
    return SettingsProvider.getInstance().fduholeToken = response.data["token"];
  }

  Future<String> loginWithUsernamePassword(
      String username, String password) async {
    final Response response = await dio!.post(_BASE_URL + "/login", data: {
      'email': username,
      'password': password,
    });
    return SettingsProvider.getInstance().fduholeToken = response.data["token"];
  }

  Future<String?> requestToken(PersonInfo info) async {
    Dio secureDio = Dio();
    //Pin HTTPS cert
    (secureDio.httpClientAdapter as DefaultHttpClientAdapter)
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
    };
    //
    // crypto.PublicKey publicKey =
    //     RsaKeyHelper().parsePublicKeyFromPem(Secret.RSA_PUBLIC_KEY);

    final Response response =
        await secureDio.post(_BASE_URL + "/register/", data: {
      'api-key': Secret.generateOneTimeAPIKey(),
      'email': "${info.id}@fudan.edu.cn",
      // Temporarily disable v2 API until the protocol is ready.
      //'ID': base64.encode(utf8.encode(encrypt(info.id, publicKey)))
    }).onError((dynamic error, stackTrace) {
      return Future.error(error);
    });
    try {
      return SettingsProvider.getInstance().fduholeToken =
          response.data["token"];
    } catch (e) {
      return Future.error(e);
    }
  }

  Map<String, String> get _tokenHeader {
    if (_token == null) throw NotLoginError("Null Token");
    return {"Authorization": "Token " + _token!};
  }

  bool get isUserInitialized => _token != null;

  Future<List<OTDivision>> loadDivisions({bool useCache = true}) async {
    if (_divisionCache.isNotEmpty && useCache) {
      return _divisionCache;
    }
    final Response response = await dio!
        .get(_BASE_URL + "/divisions", options: Options(headers: _tokenHeader));
    final List result = response.data;
    _divisionCache = result.map((e) => OTDivision.fromJson(e)).toList();
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

  Future<OTDivision> loadSpecificDivision(int divisionId,
      {bool useCache = true}) async {
    if (useCache) {
      try {
        final OTDivision cached =
            _divisionCache.firstWhere((e) => e.division_id == divisionId);
        return cached;
      } catch (ignored) {}
    }
    final Response response = await dio!.get(
        _BASE_URL + "/divisions/$divisionId",
        options: Options(headers: _tokenHeader));
    final result = response.data;
    final newDivision = OTDivision.fromJson(result);
    _divisionCache.removeWhere((element) => element.division_id == divisionId);
    _divisionCache.add(newDivision);
    return newDivision;
  }

  Future<List<OTHole>> loadHoles(DateTime startTime, int divisionId,
      {int length = 10, int prefetchLength = 10, String? tag}) async {
    final Response response = await dio!.get(_BASE_URL + "/holes",
        queryParameters: {
          "start_time": startTime.toIso8601String(),
          "division_id": divisionId,
          "length": length,
          "prefetch_length": prefetchLength,
          "tag": tag,
        },
        options: Options(headers: _tokenHeader));
    final List result = response.data;
    return result.map((e) => OTHole.fromJson(e)).toList();
  }

  // Migrated
  Future<OTHole> loadSpecificHole(int holeId) async {
    final Response response = await dio!.get(_BASE_URL + "/holes/$holeId",
        options: Options(headers: _tokenHeader));
    final hole = OTHole.fromJson(response.data);
    for (var floor in hole.floors!.prefetch!) {
      floor.mention?.forEach((mention) {
        _floorCache
            .removeWhere((element) => element.floor_id == mention.floor_id);
        _floorCache.add(mention);
      });
    }
    return hole;
  }

  // Migrated
  Future<OTFloor> loadSpecificFloor(int floorId) async {
    try {
      return _floorCache.lastWhere((element) => element.floor_id == floorId);
    } catch (ignored) {
      final Response response = await dio!.get(_BASE_URL + "/floors/$floorId",
          options: Options(headers: _tokenHeader));
      final floor = OTFloor.fromJson(response.data);
      _floorCache.removeWhere((element) => element.floor_id == floor.floor_id);
      _floorCache.add(floor);
      return floor;
    }
  }

  // Migrated
  Future<List<OTFloor>> loadFloors(OTHole post,
      {int? startFloor, int length = 10}) async {
    final Response response = await dio!.get(_BASE_URL + "/floors",
        queryParameters: {
          "start_floor": startFloor,
          "hole_id": post.hole_id,
          "length": length
        },
        options: Options(headers: _tokenHeader));
    final List result = response.data;
    final floors = result.map((e) => OTFloor.fromJson(e)).toList();
    for (var element in floors) {
      element.mention?.forEach((mention) {
        cacheFloor(mention);
      });
    }
    return floors;
  }

  // Migrated
  Future<List<OTFloor>> loadSearchResults(String? searchString,
      {int? startFloor, int length = 10}) async {
    final Response response = await dio!.get(_BASE_URL + "/floors",
        //queryParameters: {"start_floor": 0, "s": searchString, "length": 0},
        queryParameters: {
          "start_floor": startFloor,
          "s": searchString,
          "length": length,
        },
        options: Options(headers: _tokenHeader));
    final List result = response.data;
    return result.map((e) => OTFloor.fromJson(e)).toList();
  }

  // Migrated
  Future<List<OTTag>> loadTags() async {
    final Response response = await dio!
        .get(_BASE_URL + "/tags", options: Options(headers: _tokenHeader));
    final List result = response.data;
    return result.map((e) => OTTag.fromJson(e)).toList();
  }

  // Migrated
  Future<int?> newHole(int divisionId, String? content,
      {List<OTTag>? tags}) async {
    if (content == null) return -1;
    if (tags == null || tags.isEmpty) tags = [const OTTag(0, 0, "默认")];
    // Suppose user is logged in. He should be.
    final Response response = await dio!.post(_BASE_URL + "/holes",
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
    Response response = await dio!
        .post(_BASE_URL + "/images",
            data: FormData.fromMap({
              "image": await MultipartFile.fromFile(path, filename: fileName)
            }),
            options: Options(headers: _tokenHeader))
        .onError(((error, stackTrace) {
      throw ImageUploadError();
    }));
    return response.data['url'];
  }

  // Migrated
  Future<int?> newFloor(int? discussionId, String content) async {
    final Response response = await dio!.post(_BASE_URL + "/floors",
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

  // Migrated
  Future<OTFloor> likeFloor(int floorId, bool like) async {
    final Response response = await dio!.put(_BASE_URL + "/floors/$floorId",
        data: {
          "like": like ? "add" : "cancel",
        },
        options: Options(headers: _tokenHeader));
    return OTFloor.fromJson(response.data);
  }

  // Migrated
  Future<int?> reportPost(int? postId, String reason) async {
    // Suppose user is logged in. He should be.
    final Response response = await dio!.post(_BASE_URL + "/reports",
        data: {"floor_id": postId, "reason": reason},
        options: Options(headers: _tokenHeader));
    return response.statusCode;
  }

  OTUser? get userInfo => _userInfo;
  set userInfo(OTUser? value) {
    _userInfo = value;
    updateUserProfile();
  }

  // Migrated
  Future<OTUser?> getUserProfile({bool forceUpdate = false}) async {
    if (_userInfo == null || forceUpdate) {
      final Response response = await dio!
          .get(_BASE_URL + "/users", options: Options(headers: _tokenHeader));
      _userInfo = OTUser.fromJson(response.data);
    }
    return _userInfo;
  }

  Future<OTUser?> updateUserProfile() async {
    final Response response = await dio!.put(_BASE_URL + "/users",
        data: _userInfo!.toJson(), options: Options(headers: _tokenHeader));
    _userInfo = OTUser.fromJson(response.data);
    return _userInfo;
  }

  Future<List<OTMessage>> loadMessages(
      {bool unreadOnly = true, DateTime? startTime}) async {
    final Response response = await dio!.get(_BASE_URL + "/messages",
        queryParameters: {
          "not_read": unreadOnly,
          "start_time": startTime?.toIso8601String(),
        },
        options: Options(headers: _tokenHeader));
    final List result = response.data;
    return result.map((e) => OTMessage.fromJson(e)).toList();
  }

  // Migrated
  Future<bool?> isUserAdmin() async {
    return (await getUserProfile())!.is_admin;
  }

  /// Get silence date for division, return [null] if not silenced or not initialized
  DateTime? getSilenceDateForDivision(int divisionId) {
    return DateTime.tryParse(_userInfo?.permission?.silent?[divisionId] ?? "");
  }

  /// Non-async version of [isUserAdmin], will return false if data is not yet ready
  bool get isAdmin {
    return _userInfo?.is_admin ?? false;
  }

  // Migrated
  Future<List<int>> getFavoriteHoleId({bool forceUpdate = false}) async {
    return (await getUserProfile(forceUpdate: forceUpdate))!.favorites!;
  }

  // Migrated
  Future<List<OTHole>> getFavoriteHoles({
    int length = 10,
    int prefetchLength = 10,
  }) async {
    final Response response = await dio!.get(_BASE_URL + "/user/favorites",
        queryParameters: {"length": length, "prefetch_length": prefetchLength},
        options: Options(headers: _tokenHeader));
    final List result = response.data;
    return result.map((e) => OTHole.fromJson(e)).toList();
  }

  // Migrated
  Future<void> setFavorite(SetFavoriteMode mode, int? holeId) async {
    Response response;
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
    if (_userInfo?.favorites != null) {
      final Map<String, dynamic> result = response.data;
      _userInfo!.favorites = result["data"].cast<int>();
    }
  }

  // Migrated
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

  // Migrated
  /// Delete a floor
  Future<int?> deleteFloor(int? floorId) async {
    return (await dio!.delete(_BASE_URL + "/floors/$floorId",
            options: Options(headers: _tokenHeader)))
        .statusCode;
  }

  /// Get sender username of a post, requires Admin privilege
  /*Future<String> adminGetUser(int? discussionId, int? postId) async {
    throw UnimplementedError();
    final response = await dio!.post(_BASE_URL + "/admin/",
        data: {
          "operation": "get_user",
          "discussion_id": discussionId,
          "post_id": postId,
        },
        options: Options(headers: _tokenHeader));
    return response.data.toString();
  }*/

  Future<List<OTReport>> adminGetReports() async {
    final response = await dio!.get(_BASE_URL + "/reports",
        //queryParameters: {"category": page, "show_only_undealt": true},
        options: Options(headers: _tokenHeader));
    final result = response.data;
    return result.map<OTReport>((e) => OTReport.fromJson(e)).toList();
  }

  /*Future<String> adminSetReportDealt(int? reportId) async {
    throw UnimplementedError();
    final response = await dio!.post(_BASE_URL + "/admin/",
        data: {
          "operation": "set_report_dealed",
          "report_id": reportId,
        },
        options: Options(headers: _tokenHeader));
    return response.data.toString();
  }*/

  // Migrated
  /// Upload or update Push Notification token to server
  Future<void> updatePushNotificationToken(
      String token, String id, PushNotificationServiceType service) async {
    if (isUserInitialized) {
      await dio!.post(_BASE_URL + "/users",
          data: {
            "service": service.toStringRepresentation(),
            "device_id": id,
            "token": token,
          },
          options: Options(
            headers: _tokenHeader,
            validateStatus: (status) => status == 200,
          ));
    } else {
      _pushNotificationRegData = PushNotificationRegData(id, token, service);
    }
  }

  Future<void> deletePushNotificationToken(String token) async {
    throw UnimplementedError(
        "delete push notification token function has not yet been implemented, awaiting API negotiation.");
    /*await dio!.delete(_BASE_URL + "/users",
        data: {
          "service": service.toStringRepresentation(),
          "device_id": id,
          "token": token,
        },
        options: Options(
          headers: _tokenHeader,
          validateStatus: (status) => status == 200,
        ));*/
  }

  @override
  String get linkHost => "www.fduhole.com";
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
