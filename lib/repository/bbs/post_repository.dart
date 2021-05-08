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
import 'package:dan_xi/common/constant.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/model/post.dart';
import 'package:dan_xi/model/post_tag.dart';
import 'package:dan_xi/model/reply.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:rsa_encrypt/rsa_encrypt.dart';
import 'package:pointycastle/api.dart' as crypto;

class PostRepository extends BaseRepositoryWithDio {
  static final _instance = PostRepository._();

  factory PostRepository.getInstance() => _instance;
  static const String _BASE_URL = "https://www.fduhole.tk/v1";
  static const List<int> PINNED_CERTIFICATE = [
    48,
    130,
    1,
    10,
    2,
    130,
    1,
    1,
    0,
    187,
    2,
    21,
    40,
    204,
    246,
    160,
    148,
    211,
    15,
    18,
    236,
    141,
    85,
    146,
    195,
    248,
    130,
    241,
    153,
    166,
    122,
    66,
    136,
    167,
    93,
    38,
    170,
    181,
    43,
    185,
    197,
    76,
    177,
    175,
    142,
    107,
    249,
    117,
    200,
    163,
    215,
    15,
    71,
    148,
    20,
    85,
    53,
    87,
    140,
    158,
    168,
    162,
    57,
    25,
    245,
    130,
    60,
    66,
    169,
    78,
    110,
    245,
    59,
    195,
    46,
    219,
    141,
    192,
    176,
    92,
    243,
    89,
    56,
    231,
    237,
    207,
    105,
    240,
    90,
    11,
    27,
    190,
    192,
    148,
    36,
    37,
    135,
    250,
    55,
    113,
    179,
    19,
    231,
    28,
    172,
    225,
    155,
    239,
    219,
    228,
    59,
    69,
    82,
    69,
    150,
    169,
    193,
    83,
    206,
    52,
    200,
    82,
    238,
    181,
    174,
    237,
    143,
    222,
    96,
    112,
    226,
    165,
    84,
    171,
    182,
    109,
    14,
    151,
    165,
    64,
    52,
    107,
    43,
    211,
    188,
    102,
    235,
    102,
    52,
    124,
    250,
    107,
    139,
    143,
    87,
    41,
    153,
    248,
    48,
    23,
    93,
    186,
    114,
    111,
    251,
    129,
    197,
    173,
    210,
    134,
    88,
    61,
    23,
    199,
    231,
    9,
    187,
    241,
    43,
    247,
    134,
    220,
    193,
    218,
    113,
    93,
    212,
    70,
    227,
    204,
    173,
    37,
    193,
    136,
    188,
    96,
    103,
    117,
    102,
    179,
    241,
    24,
    247,
    162,
    92,
    230,
    83,
    255,
    58,
    136,
    182,
    71,
    165,
    255,
    19,
    24,
    234,
    152,
    9,
    119,
    63,
    157,
    83,
    249,
    207,
    1,
    229,
    245,
    166,
    112,
    23,
    20,
    175,
    99,
    164,
    255,
    153,
    179,
    147,
    157,
    220,
    83,
    167,
    6,
    254,
    72,
    133,
    29,
    161,
    105,
    174,
    37,
    117,
    187,
    19,
    204,
    82,
    3,
    245,
    237,
    81,
    161,
    139,
    219,
    21,
    2,
    3,
    1,
    0,
    1
  ];

  Dio secureDio = Dio();

  /// The token used for session authentication.
  String _token;

  PostRepository._() {
    initRepository();
  }

  Future<void> requestToken(PersonInfo info) async {
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

        if (listEquals(pubKeyBits.stringValue, PINNED_CERTIFICATE))
          return true; // Allow connection when public key matches
        throw NotLoginError("Invalid HTTPS Certificate");
      };
      return httpClient;
    };

    crypto.PublicKey publicKey = RsaKeyHelper().parsePublicKeyFromPem(Secret.RSA_PUBLIC_KEY);

    Response response = await secureDio.post(_BASE_URL + "/register/", data: {
      'api-key': Secret.FDUHOLE_API_KEY,
      'email': "${info.id}@fudan.edu.cn",
      'id': encrypt(info.id, publicKey)
    }).onError((error, stackTrace) => throw NotLoginError(error.toString()));
    try {
      _token = response.data["token"];
    } catch (e, stackTrace) {
      _token = null;
      throw NotLoginError(e.toString());
    }
  }

  Map<String, String> get _tokenHeader {
    return {"Authorization": "Token " + _token};
  }

  bool get isUserInitialized => _token == null ? false : true;

  Future<List<BBSPost>> loadPosts(int page, SortOrder sortBy) async {
    print(_token);
    Map<String, dynamic> qp;
    switch (sortBy) {
      case SortOrder.LAST_CREATED:
        qp = {"page": page, "order": "last_created"};
        break;
      case SortOrder.LAST_REPLIED:
        qp = {"page": page};
        break;
    }
    Response response = await dio.get(_BASE_URL + "/discussions/",
        queryParameters: qp, options: Options(headers: _tokenHeader));
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

  Future<List<BBSPost>> loadSearchResults(String searchString) async {
    Response response = await dio.get(_BASE_URL + "/posts/",
        queryParameters: {"search": searchString},
        options: Options(headers: _tokenHeader));
    List result = response.data;
    return result.map((e) => BBSPost.fromJson(e)).toList();
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
    Response response = await dio.post(_BASE_URL + "/images/",
        data: FormData.fromMap(
            {"img": await MultipartFile.fromFile(path, filename: fileName)}),
        options: Options(headers: _tokenHeader));
    return response.data['url'];
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
}

class NotLoginError implements Exception {
  String errorMessage;
  NotLoginError(this.errorMessage);
}
