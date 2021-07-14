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
import 'package:dan_xi/main.dart';
import 'package:dan_xi/model/fduhole_profile.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/post.dart';
import 'package:dan_xi/model/post_tag.dart';
import 'package:dan_xi/model/reply.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tagging/flutter_tagging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostRepository extends BaseRepositoryWithDio {
  static final _instance = PostRepository._();

  factory PostRepository.getInstance() => _instance;
  static const String _BASE_URL = "https://www.fduhole.tk/v1";
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
    173,
    232,
    36,
    115,
    244,
    20,
    55,
    243,
    155,
    158,
    43,
    87,
    40,
    28,
    135,
    190,
    220,
    183,
    223,
    56,
    144,
    140,
    110,
    60,
    230,
    87,
    160,
    120,
    247,
    117,
    194,
    162,
    254,
    245,
    106,
    110,
    246,
    0,
    79,
    40,
    219,
    222,
    104,
    134,
    108,
    68,
    147,
    182,
    177,
    99,
    253,
    20,
    18,
    107,
    191,
    31,
    210,
    234,
    49,
    155,
    33,
    126,
    209,
    51,
    60,
    186,
    72,
    245,
    221,
    121,
    223,
    179,
    184,
    255,
    18,
    241,
    33,
    154,
    75,
    193,
    138,
    134,
    113,
    105,
    74,
    102,
    102,
    108,
    143,
    126,
    60,
    112,
    191,
    173,
    41,
    34,
    6,
    243,
    228,
    192,
    230,
    128,
    174,
    226,
    75,
    143,
    183,
    153,
    126,
    148,
    3,
    159,
    211,
    71,
    151,
    124,
    153,
    72,
    35,
    83,
    232,
    56,
    174,
    79,
    10,
    111,
    131,
    46,
    209,
    73,
    87,
    140,
    128,
    116,
    182,
    218,
    47,
    208,
    56,
    141,
    123,
    3,
    112,
    33,
    27,
    117,
    242,
    48,
    60,
    250,
    143,
    174,
    221,
    218,
    99,
    171,
    235,
    22,
    79,
    194,
    142,
    17,
    75,
    126,
    207,
    11,
    232,
    255,
    181,
    119,
    46,
    244,
    178,
    123,
    74,
    224,
    76,
    18,
    37,
    12,
    112,
    141,
    3,
    41,
    160,
    225,
    83,
    36,
    236,
    19,
    217,
    238,
    25,
    191,
    16,
    179,
    74,
    140,
    63,
    137,
    163,
    97,
    81,
    222,
    172,
    135,
    7,
    148,
    244,
    99,
    113,
    236,
    46,
    226,
    111,
    91,
    152,
    129,
    225,
    137,
    92,
    52,
    121,
    108,
    118,
    239,
    59,
    144,
    98,
    121,
    230,
    219,
    164,
    154,
    47,
    38,
    197,
    208,
    16,
    225,
    14,
    222,
    217,
    16,
    142,
    22,
    251,
    183,
    247,
    168,
    247,
    199,
    229,
    2,
    7,
    152,
    143,
    54,
    8,
    149,
    231,
    226,
    55,
    150,
    13,
    54,
    117,
    158,
    251,
    14,
    114,
    177,
    29,
    155,
    188,
    3,
    249,
    73,
    5,
    216,
    129,
    221,
    5,
    180,
    42,
    214,
    65,
    233,
    172,
    1,
    118,
    149,
    10,
    15,
    216,
    223,
    213,
    189,
    18,
    31,
    53,
    47,
    40,
    23,
    108,
    210,
    152,
    193,
    168,
    9,
    100,
    119,
    110,
    71,
    55,
    186,
    206,
    172,
    89,
    94,
    104,
    157,
    127,
    114,
    214,
    137,
    197,
    6,
    65,
    41,
    62,
    89,
    62,
    221,
    38,
    245,
    36,
    201,
    17,
    167,
    90,
    163,
    76,
    64,
    31,
    70,
    161,
    153,
    181,
    167,
    58,
    81,
    110,
    134,
    59,
    158,
    125,
    114,
    167,
    18,
    5,
    120,
    89,
    237,
    62,
    81,
    120,
    21,
    11,
    3,
    143,
    141,
    208,
    47,
    5,
    178,
    62,
    123,
    74,
    28,
    75,
    115,
    5,
    18,
    252,
    198,
    234,
    224,
    80,
    19,
    124,
    67,
    147,
    116,
    179,
    202,
    116,
    231,
    142,
    31,
    1,
    8,
    208,
    48,
    212,
    91,
    113,
    54,
    180,
    7,
    186,
    193,
    48,
    48,
    92,
    72,
    183,
    130,
    59,
    152,
    166,
    125,
    96,
    138,
    162,
    163,
    41,
    130,
    204,
    186,
    189,
    131,
    4,
    27,
    162,
    131,
    3,
    65,
    161,
    214,
    5,
    241,
    27,
    194,
    182,
    240,
    168,
    124,
    134,
    59,
    70,
    168,
    72,
    42,
    136,
    220,
    118,
    154,
    118,
    191,
    31,
    106,
    165,
    61,
    25,
    143,
    235,
    56,
    243,
    100,
    222,
    200,
    43,
    13,
    10,
    40,
    255,
    247,
    219,
    226,
    21,
    66,
    212,
    34,
    208,
    39,
    93,
    225,
    121,
    254,
    24,
    231,
    112,
    136,
    173,
    78,
    230,
    217,
    139,
    58,
    198,
    221,
    39,
    81,
    110,
    255,
    188,
    100,
    245,
    51,
    67,
    79,
    2,
    3,
    1,
    0,
    1
  ];

  Dio secureDio = Dio();

  /// The token used for session authentication.
  String _token;

  PostRepository._();

  initializeUser(PersonInfo info, SharedPreferences _preferences) async {
    _token = SettingsProvider.of(_preferences).fduholeToken ??
        await requestToken(info, _preferences);
  }

  Future<String> requestToken(
      PersonInfo info, SharedPreferences _preferences) async {
    //Pin HTTPS cert
    (secureDio.httpClientAdapter as DefaultHttpClientAdapter)
        .onHttpClientCreate = (client) {
      SecurityContext sc = SecurityContext(withTrustedRoots: false);
      HttpClient httpClient = HttpClient(context: sc);
      httpClient.badCertificateCallback =
          (X509Certificate certificate, String host, int port) {
        // This badCertificateCallback will always be called since we have no trusted certificate.
        ASN1Parser p = ASN1Parser(certificate.der);
        ASN1Sequence signedCert = p.nextObject() as ASN1Sequence;
        ASN1Sequence cert = signedCert.elements[0] as ASN1Sequence;
        ASN1Sequence pubKeyElement = cert.elements[6] as ASN1Sequence;
        ASN1BitString pubKeyBits = pubKeyElement.elements[1] as ASN1BitString;

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

    Response response = await secureDio.post(_BASE_URL + "/register/", data: {
      'api-key': Secret.FDUHOLE_API_KEY,
      'email': "${info.id}@fudan.edu.cn",
      // Temporarily disable v2 API until the protocol is ready.
      //'ID': base64.encode(utf8.encode(encrypt(info.id, publicKey)))
    }).onError((error, stackTrace) {
      if (error is DioError && error.error is NotLoginError)
        throw NotLoginError((error.error.errorMessage));
      throw NotLoginError(error.toString());
    });
    try {
      return SettingsProvider.of(_preferences).fduholeToken =
          response.data["token"];
    } catch (e) {
      throw NotLoginError(e.toString());
    }
  }

  Map<String, String> get _tokenHeader {
    return {"Authorization": "Token " + _token};
  }

  bool get isUserInitialized => _token != null;

  Future<List<BBSPost>> loadPosts(int page, SortOrder sortBy) async {
    Response response = await dio
        .get(_BASE_URL + "/discussions/",
            queryParameters: {
              "page": page,
              "order": sortBy.getInternalString()
            },
            options: Options(headers: _tokenHeader))
        .onError((error, stackTrace) {
      if (error.response?.statusCode == 401) {
        _token = null;
        throw LoginExpiredError;
      }
      throw error;
    });
    List result = response.data;
    return result.map((e) => BBSPost.fromJson(e)).toList();
  }

  Future<BBSPost> loadSpecificPost(int disscussionId) async {
    Response response = await dio.get(_BASE_URL + "/discussions/",
        queryParameters: {"discussion_id": disscussionId.toString()},
        options: Options(headers: _tokenHeader));
    return BBSPost.fromJson(response.data);
  }

  Future<List<BBSPost>> loadTagFilteredPosts(
      String tag, SortOrder sortBy) async {
    Response response = await dio
        .get(_BASE_URL + "/discussions/",
            queryParameters: {
              "order": sortBy.getInternalString(),
              "tag_name": tag
            },
            options: Options(headers: _tokenHeader))
        .onError((error, stackTrace) {
      if (error.response?.statusCode == 401) {
        _token = null;
        throw LoginExpiredError;
      }
      throw error;
    });
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

  Future<List<Reply>> loadSearchResults(String searchString) async {
    Response response = await dio.get(_BASE_URL + "/posts/",
        queryParameters: {"search": searchString},
        options: Options(headers: _tokenHeader));
    List result = response.data;
    return result.map((e) => Reply.fromJson(e)).toList();
  }

  Future<List<PostTag>> loadTags() async {
    Response response = await dio.get(_BASE_URL + "/tags/",
        options: Options(headers: _tokenHeader));
    List result = response.data;
    return result.map((e) => PostTag.fromJson(e)).toList();
  }

  Future<int> newPost(String content, {List<PostTag> tags}) async {
    if (content == null) return 0;
    if (tags == null) tags = [];
    // Suppose user is logged in. He should be.
    Response response = await dio.post(_BASE_URL + "/discussions/",
        data: {
          "content": content,
          "tags": tags.map((e) => e.toJson()).toList()
        },
        options: Options(headers: _tokenHeader));
    return response.statusCode;
  }

  Future<String> uploadImage(File file) async {
    String path = file.absolute.path;
    String fileName = path.substring(path.lastIndexOf("/") + 1, path.length);
    Response response = await dio
        .post(_BASE_URL + "/images/",
            data: FormData.fromMap({
              "img": await MultipartFile.fromFile(path, filename: fileName)
            }),
            options: Options(headers: _tokenHeader))
        .onError((error, stackTrace) => throw ImageUploadError());
    return response?.data['url'];
  }

  Future<int> newReply(int discussionId, int postId, String content) async {
    // Suppose user is logged in. He should be.
    Response response = await dio.post(_BASE_URL + "/posts/",
        data: {
          "content": content,
          "discussion_id": discussionId,
          "post_id": postId
        },
        options: Options(headers: _tokenHeader));
    return response.statusCode;
  }

  Future<int> reportPost(int postId, String reason) async {
    // Suppose user is logged in. He should be.
    Response response = await dio.post(_BASE_URL + "/reports/",
        data: {"post_id": postId, "reason": reason},
        options: Options(headers: _tokenHeader));
    return response.statusCode;
  }

  Future<FduholeProfile> getUserProfile() async {
    Response response = await dio.get(_BASE_URL + "/profile/",
        options: Options(headers: _tokenHeader));
    return FduholeProfile.fromJson(response.data);
  }

  Future<List<BBSPost>> getFavoredDiscussions() async {
    return (await getUserProfile()).favored_discussion;
  }

  Future<FduholeProfile> setFavoredDiscussion(
      SetFavoredDiscussionMode mode, int discussionId) async {
    Response response = await dio.put(_BASE_URL + "/profile/",
        data: {
          'mode': mode.getInternalString(),
          'favoredDiscussion': discussionId
        },
        options: Options(headers: _tokenHeader));
    return FduholeProfile.fromJson(response.data);
  }

  @override
  String get linkHost => "www.fduhole.tk";
}

enum SetFavoredDiscussionMode { ADD, DELETE }

extension FavoredDiscussionEx on SetFavoredDiscussionMode {
  String getInternalString() {
    switch (this) {
      case SetFavoredDiscussionMode.ADD:
        return "addFavoredDiscussion";
      case SetFavoredDiscussionMode.DELETE:
        return "deleteFavoredDiscussion";
    }
    return null;
  }
}

class NotLoginError implements Exception {
  String errorMessage;

  NotLoginError(this.errorMessage);
}

class LoginExpiredError implements Exception {}

class ImageUploadError implements Exception {}
