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

import 'dart:io';

import 'package:asn1lib/asn1lib.dart';
import 'package:dan_xi/common/Secret.dart';
import 'package:dan_xi/model/fduhole_profile.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/post.dart';
import 'package:dan_xi/model/post_tag.dart';
import 'package:dan_xi/model/reply.dart';
import 'package:dan_xi/model/report.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/util/platform_bridge.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class PostRepository extends BaseRepositoryWithDio {
  static final _instance = PostRepository._();

  factory PostRepository.getInstance() => _instance;
  static const String _BASE_URL = "https://www.fduhole.com/v1";
  static const List<int> PINNED_CERTIFICATE = [
    48,
    130,
    2,
    10,
    2,
    130,
    2,
    1,
    0,
    128,
    18,
    101,
    23,
    54,
    14,
    195,
    219,
    8,
    179,
    208,
    172,
    87,
    13,
    118,
    237,
    205,
    39,
    211,
    76,
    173,
    80,
    131,
    97,
    226,
    170,
    32,
    77,
    9,
    45,
    100,
    9,
    220,
    206,
    137,
    159,
    204,
    61,
    169,
    236,
    246,
    207,
    193,
    220,
    241,
    211,
    177,
    214,
    123,
    55,
    40,
    17,
    43,
    71,
    218,
    57,
    198,
    188,
    58,
    25,
    180,
    95,
    166,
    189,
    125,
    157,
    163,
    99,
    66,
    182,
    118,
    242,
    169,
    59,
    43,
    145,
    248,
    226,
    111,
    208,
    236,
    22,
    32,
    144,
    9,
    62,
    226,
    232,
    116,
    201,
    24,
    180,
    145,
    212,
    98,
    100,
    219,
    127,
    163,
    6,
    241,
    136,
    24,
    106,
    144,
    34,
    60,
    188,
    254,
    19,
    240,
    135,
    20,
    123,
    246,
    228,
    31,
    142,
    212,
    228,
    81,
    198,
    17,
    103,
    70,
    8,
    81,
    203,
    134,
    20,
    84,
    63,
    188,
    51,
    254,
    126,
    108,
    156,
    255,
    22,
    157,
    24,
    189,
    81,
    142,
    53,
    166,
    167,
    102,
    200,
    114,
    103,
    219,
    33,
    102,
    177,
    212,
    155,
    120,
    3,
    192,
    80,
    58,
    232,
    204,
    240,
    220,
    188,
    158,
    76,
    254,
    175,
    5,
    150,
    53,
    31,
    87,
    90,
    183,
    255,
    206,
    249,
    61,
    183,
    44,
    182,
    246,
    84,
    221,
    200,
    231,
    18,
    58,
    77,
    174,
    76,
    138,
    183,
    92,
    154,
    180,
    183,
    32,
    61,
    202,
    127,
    34,
    52,
    174,
    126,
    59,
    104,
    102,
    1,
    68,
    231,
    1,
    78,
    70,
    83,
    155,
    51,
    96,
    247,
    148,
    190,
    83,
    55,
    144,
    115,
    67,
    243,
    50,
    195,
    83,
    239,
    219,
    170,
    254,
    116,
    78,
    105,
    199,
    107,
    140,
    96,
    147,
    222,
    196,
    199,
    12,
    223,
    225,
    50,
    174,
    204,
    147,
    59,
    81,
    120,
    149,
    103,
    139,
    238,
    61,
    86,
    254,
    12,
    208,
    105,
    15,
    27,
    15,
    243,
    37,
    38,
    107,
    51,
    109,
    247,
    110,
    71,
    250,
    115,
    67,
    229,
    126,
    14,
    165,
    102,
    177,
    41,
    124,
    50,
    132,
    99,
    85,
    137,
    196,
    13,
    193,
    147,
    84,
    48,
    25,
    19,
    172,
    211,
    125,
    55,
    167,
    235,
    93,
    58,
    108,
    53,
    92,
    219,
    65,
    215,
    18,
    218,
    169,
    73,
    11,
    223,
    216,
    128,
    138,
    9,
    147,
    98,
    142,
    181,
    102,
    207,
    37,
    136,
    205,
    132,
    184,
    177,
    63,
    164,
    57,
    15,
    217,
    2,
    158,
    235,
    18,
    76,
    149,
    124,
    243,
    107,
    5,
    169,
    94,
    22,
    131,
    204,
    184,
    103,
    226,
    232,
    19,
    157,
    204,
    91,
    130,
    211,
    76,
    179,
    237,
    91,
    255,
    222,
    229,
    115,
    172,
    35,
    59,
    45,
    0,
    191,
    53,
    85,
    116,
    9,
    73,
    216,
    73,
    88,
    26,
    127,
    146,
    54,
    230,
    81,
    146,
    14,
    243,
    38,
    125,
    28,
    77,
    23,
    188,
    201,
    236,
    67,
    38,
    208,
    191,
    65,
    95,
    64,
    169,
    68,
    68,
    244,
    153,
    231,
    87,
    135,
    158,
    80,
    31,
    87,
    84,
    168,
    62,
    253,
    116,
    99,
    47,
    177,
    80,
    101,
    9,
    230,
    88,
    66,
    46,
    67,
    26,
    76,
    180,
    240,
    37,
    71,
    89,
    250,
    4,
    30,
    147,
    212,
    38,
    70,
    74,
    80,
    129,
    178,
    222,
    190,
    120,
    183,
    252,
    103,
    21,
    225,
    201,
    87,
    132,
    30,
    15,
    99,
    214,
    233,
    98,
    186,
    214,
    95,
    85,
    46,
    234,
    92,
    198,
    40,
    8,
    4,
    37,
    57,
    184,
    14,
    43,
    169,
    242,
    76,
    151,
    28,
    7,
    63,
    13,
    82,
    245,
    237,
    239,
    47,
    130,
    15,
    2,
    3,
    1,
    0,
    1
  ];

  /// The token used for session authentication.
  String? _token;

  /// Current user profile, stored as cache by the repository
  FduholeProfile? _profile;

  /// Push Notification Registeration Cache
  String? _deviceId, _pushNotificationToken;
  PushNotificationServiceType? _pushNotificationService;

  clearCache() {
    _token = null;
    _profile = null;
    _deviceId = null;
    _pushNotificationService = null;
    _pushNotificationToken = null;
  }

  PostRepository._() {
    // Override the options set in parent class.
    dio!.options = BaseOptions(receiveDataWhenStatusError: true);
  }

  initializeUser(PersonInfo? info) async {
    try {
      PlatformBridge.requestNotificationPermission();
    } catch (ignored) {}
    if (SettingsProvider.getInstance().fduholeToken != null) {
      _token = SettingsProvider.getInstance().fduholeToken;
    } else {
      _token = await requestToken(info!);
      updatePushNotificationToken();
    }
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
        // This badCertificateCallback will always be called since we have no trusted certificate.
        final ASN1Parser p = ASN1Parser(certificate.der);
        final ASN1Sequence signedCert = p.nextObject() as ASN1Sequence;
        final ASN1Sequence cert = signedCert.elements[0] as ASN1Sequence;
        final ASN1Sequence pubKeyElement = cert.elements[6] as ASN1Sequence;
        final ASN1BitString pubKeyBits =
            pubKeyElement.elements[1] as ASN1BitString;

        if (listEquals(pubKeyBits.stringValue, PINNED_CERTIFICATE)) {
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
      'api-key': Secret.FDUHOLE_API_KEY,
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

  Future<List<BBSPost>> loadDiscussions(int page, SortOrder? sortBy) async {
    final Response response = await dio!.get(_BASE_URL + "/discussions/",
        queryParameters: {"page": page, "order": sortBy.getInternalString()},
        options: Options(headers: _tokenHeader));
    final List result = response.data;
    return result.map((e) => BBSPost.fromJson(e)).toList();
  }

  Future<BBSPost> loadSpecificDiscussion(int? discussionId) async {
    Response response = await dio!.get(_BASE_URL + "/discussions/",
        queryParameters: {"discussion_id": discussionId.toString()},
        options: Options(headers: _tokenHeader));
    return BBSPost.fromJson(response.data);
  }

  Future<List<BBSPost>> loadTagFilteredDiscussions(
      String tag, SortOrder sortBy, int page) async {
    try {
      final response = await dio!.get(_BASE_URL + "/discussions/",
          queryParameters: {
            "order": sortBy.getInternalString(),
            "tag_name": tag,
            "page": page,
          },
          options: Options(headers: _tokenHeader));
      final List result = response.data;
      return result.map((e) => BBSPost.fromJson(e)).toList();
    } catch (error) {
      if (error is DioError && error.response?.statusCode == 401) {
        _token = null;
        throw LoginExpiredError;
      }
      rethrow;
    }
  }

  Future<List<Reply>> loadReplies(BBSPost post, int page) async {
    final Response response = await dio!
        .get(_BASE_URL + "/posts/",
            queryParameters: {"page": page, "id": post.id},
            options: Options(headers: _tokenHeader))
        .onError((dynamic error, stackTrace) {
      return Future.error(error);
    });
    final List result = response.data;
    return result.map((e) => Reply.fromJson(e)).toList();
  }

  Future<List<Reply>> loadSearchResults(String? searchString, int page) async {
    // Search results only have a single page.
    // Return nothing if [page] > 1.
    if (page > 1) return Future.value([]);
    final Response response = await dio!.get(_BASE_URL + "/posts/",
        queryParameters: {"search": searchString, "page": page},
        options: Options(headers: _tokenHeader));
    final List result = response.data;
    return result.map((e) => Reply.fromJson(e)).toList();
  }

  Future<List<PostTag>> loadTags() async {
    final Response response = await dio!
        .get(_BASE_URL + "/tags/", options: Options(headers: _tokenHeader));
    final List result = response.data;
    return result.map((e) => PostTag.fromJson(e)).toList();
  }

  Future<int?> newPost(String? content, {List<PostTag>? tags}) async {
    if (content == null) return 0;
    if (tags == null) tags = [];
    // Suppose user is logged in. He should be.
    final Response response = await dio!.post(_BASE_URL + "/discussions/",
        data: {
          "content": content,
          "tags": tags.map((e) => e.toJson()).toList()
        },
        options: Options(headers: _tokenHeader));
    return response.statusCode;
  }

  Future<String?> uploadImage(File file) async {
    String path = file.absolute.path;
    String fileName = path.substring(path.lastIndexOf("/") + 1, path.length);
    Response response = await dio!
        .post(_BASE_URL + "/images/",
            data: FormData.fromMap({
              "img": await MultipartFile.fromFile(path, filename: fileName)
            }),
            options: Options(headers: _tokenHeader))
        .onError(((dynamic error, stackTrace) => throw ImageUploadError()));
    return response.data['url'];
  }

  Future<int?> newReply(int? discussionId, int? postId, String content) async {
    // Suppose user is logged in. He should be.
    final Response response = await dio!.post(_BASE_URL + "/posts/",
        data: {
          "content": content,
          "discussion_id": discussionId,
          "post_id": postId
        },
        options: Options(headers: _tokenHeader));
    return response.statusCode;
  }

  Future<int?> reportPost(int? postId, String reason) async {
    // Suppose user is logged in. He should be.
    final Response response = await dio!.post(_BASE_URL + "/reports/",
        data: {"post_id": postId, "reason": reason},
        options: Options(headers: _tokenHeader));
    return response.statusCode;
  }

  Future<FduholeProfile?> getUserProfile({bool forceUpdate = false}) async {
    if (_profile == null || forceUpdate) {
      final Response response = await dio!.get(_BASE_URL + "/profile/",
          options: Options(headers: _tokenHeader));
      _profile = FduholeProfile.fromJson(response.data);
    }
    return _profile;
  }

  Future<bool?> isUserAdmin() async {
    return (await getUserProfile())!.user!.is_staff;
  }

  /// Non-async version of [isUserAdmin], will return false if data is not yet ready
  bool isUserAdminNonAsync() {
    return _profile?.user?.is_staff ?? false;
  }

  Future<List<BBSPost>> getFavoredDiscussions(
      {bool forceUpdate = false}) async {
    return (await getUserProfile(forceUpdate: forceUpdate))!
        .favored_discussion!;
  }

  Future<void> setFavoredDiscussion(
      SetFavoredDiscussionMode mode, int? discussionId) async {
    final Response response = await dio!.put(_BASE_URL + "/profile/",
        data: {
          'mode': mode.getInternalString(),
          'favoredDiscussion': discussionId
        },
        options: Options(headers: _tokenHeader));
    _profile = FduholeProfile.fromJson(response.data);
  }

  /// Modify a post, requires Admin privilege
  /// Throws on failure.
  Future<void> adminModifyPost(
      String content, int? discussionId, int? postId) async {
    await dio!.post(_BASE_URL + "/admin/",
        data: {
          "content": content,
          "operation": "modify",
          "discussion_id": discussionId,
          "post_id": postId,
        },
        options: Options(headers: _tokenHeader));
  }

  /// Disable a post, requires Admin privilege
  /// Throws on failure.
  Future<void> adminDisablePost(int? discussionId, int? postId) async {
    await dio!.post(_BASE_URL + "/admin/",
        data: {
          "operation": "disable",
          "discussion_id": discussionId,
          "post_id": postId,
        },
        options: Options(headers: _tokenHeader));
  }

  /// Disable a discussion, requires Admin privilege
  /// Throws on failure.
  Future<void> adminDisableDiscussion(int? discussionId) async {
    await dio!.post(_BASE_URL + "/admin/",
        data: {
          "operation": "disable_discussion",
          "discussion_id": discussionId,
        },
        options: Options(headers: _tokenHeader));
  }

  /// Get sender username of a post, requires Admin privilege
  Future<String> adminGetUser(int? discussionId, int? postId) async {
    final response = await dio!.post(_BASE_URL + "/admin/",
        data: {
          "operation": "get_user",
          "discussion_id": discussionId,
          "post_id": postId,
        },
        options: Options(headers: _tokenHeader));
    return response.data.toString();
  }

  Future<List<Report>> adminGetReports(int page) async {
    final response = await dio!.get(_BASE_URL + "/admin/",
        queryParameters: {"page": page, "show_only_undealt": true},
        options: Options(headers: _tokenHeader));
    final result = response.data;
    return result.map<Report>((e) => Report.fromJson(e)).toList();
  }

  Future<String> adminSetReportDealt(int? reportId) async {
    final response = await dio!.post(_BASE_URL + "/admin/",
        data: {
          "operation": "set_report_dealed",
          "report_id": reportId,
        },
        options: Options(headers: _tokenHeader));
    return response.data.toString();
  }

  /* BEGIN v2 API */

  /// Upload or update Push Notification token to server
  /// API Version: v2
  Future<void> updatePushNotificationToken(
      [String? token, String? id, PushNotificationServiceType? service]) async {
    if (isUserInitialized) {
      await dio!.post(_BASE_URL + "/users",
          data: {
            "service":
                (service ?? _pushNotificationService).toStringRepresentation(),
            "device_id": id ?? _deviceId,
            "token": token ?? _pushNotificationToken,
          },
          options: Options(headers: _tokenHeader));
    } else {
      _deviceId = id;
      _pushNotificationToken = token;
      _pushNotificationService = service;
    }
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

enum SetFavoredDiscussionMode { ADD, DELETE }

extension FavoredDiscussionEx on SetFavoredDiscussionMode {
  String? getInternalString() {
    switch (this) {
      case SetFavoredDiscussionMode.ADD:
        return "addFavoredDiscussion";
      case SetFavoredDiscussionMode.DELETE:
        return "deleteFavoredDiscussion";
    }
  }
}

class NotLoginError implements Exception {
  final String errorMessage;

  NotLoginError(this.errorMessage);
}

class LoginExpiredError implements Exception {}

class ImageUploadError implements Exception {}
