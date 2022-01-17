import 'dart:convert';
import 'dart:math';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import 'bmob.dart';

//    post or put:
//		md5(url + timeStamp + safeToken + noncestr+ body + sdkVersion)
//
//		get or delete:
//		md5(url + timeStamp + safeToken + noncestr+ sdkVersion)
class BmobDio {
  ///网络请求框架
  late Dio dio;

  ///网络请求元素
  BaseOptions? options;

  ///单例
  static BmobDio? instance;

  void setSessionToken(bmobSessionToken) {
    options!.headers["X-Bmob-Session-Token"] = bmobSessionToken;
  }

  ///无参构造方法
  BmobDio() {
    options = BaseOptions(
      //基地址
      baseUrl: Bmob.bmobHost,
      //连接服务器的超时时间，单位是毫秒。
      connectTimeout: 10000,
      //响应流上前后两次接受到数据的间隔，单位为毫秒。如果两次间隔超过[receiveTimeout]，将会抛出一个[DioErrorType.RECEIVE_TIMEOUT]的异常。
      receiveTimeout: 3000,
      //请求头部
//      headers: {
//        "Content-Type": "application/json",
//      },
    );

    dio = Dio(options);
  }

  ///获取16位随机字符串
  getNoncestrKey() {
    String alphabet = 'qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM';
    int length = 16;

    /// 生成的字符串固定长度
    String left = '';
    for (var i = 0; i < length; i++) {
      left = left + alphabet[Random().nextInt(alphabet.length)];
    }
    return left;
  }

  ///md5(url(域名之外的url) + timeStamp + safeToken(后台设置) + noncestr(随机值)+ body(body json) + sdkVersion)
  getSafeSign(path, nonceStrKey, safeTimeStamp, data) {
    var origin = path +
        safeTimeStamp +
        Bmob.bmobApiSafe +
        nonceStrKey +
        data.toString() +
        Bmob.bmobSDKVersion;
    var md5 = generateMd5(origin);
    return md5;
  }

  ///md5编码
  String generateMd5(String origin) {
    var content = const Utf8Encoder().convert(origin);
    var digest = md5.convert(content);
    return hex.encode(digest.bytes);
  }

  ///获取时间戳 秒
  getSafeTimestamp() {
    int second = (DateTime.now().millisecondsSinceEpoch) ~/ 1000;
    return second.toString();
  }

  ///单例模式
  static BmobDio? getInstance() {
    instance ??= BmobDio();
    return instance;
  }

  ///GET请求
  Future<dynamic> get(path, {data, cancelToken}) async {
    options!.headers.addAll(getHeaders(path, ""));

    var requestUrl = options!.baseUrl + path;
    Response response = await dio.get(
      requestUrl,
      queryParameters: data,
      cancelToken: cancelToken,
    );

    return response.data;
  }

  ///POST请求
  Future<dynamic> upload(path,
      {required Future<List<int>> data, cancelToken}) async {
    options!.headers.addAll(getHeaders(path, data));

    var requestUrl = options!.baseUrl + path;
    Response response = await dio.post(
      requestUrl,
      data: Stream.fromFuture(data),
      cancelToken: cancelToken,
    );

    return response.data;
  }

  ///POST请求
  Future<dynamic> post(path, {data, cancelToken}) async {
    options!.headers.addAll(getHeaders(path, data));

    var requestUrl = options!.baseUrl + path;
    Response response = await dio.post(
      requestUrl,
      data: data,
      cancelToken: cancelToken,
    );
    return response.data;
  }

  ///Delete请求
  Future<dynamic> delete(
    path, {
    data,
    cancelToken,
  }) async {
    options!.headers.addAll(getHeaders(path, ""));

    var requestUrl = options!.baseUrl + path;
    Response response =
        await dio.delete(requestUrl, data: data, cancelToken: cancelToken);
    return response.data;
  }

  ///Put请求
  Future<dynamic> put(path, {data, cancelToken}) async {
    options!.headers.addAll(getHeaders(path, data));

    var requestUrl = options!.baseUrl + path;
    Response response =
        await dio.put(requestUrl, data: data, cancelToken: cancelToken);
    return response.data;
  }

  ///GET请求，自带请求路径，数据监听
  Future<dynamic> getByUrl(requestUrl, {data, cancelToken}) async {
    options!.headers.addAll(getHeaders(requestUrl, data));

    Response response = await dio.get(
      requestUrl,
      queryParameters: data,
      cancelToken: cancelToken,
    );
    return response.data;
  }

  ///获取请求头
  getHeaders(path, data) {
    Map<String, dynamic> map = {};

    if (Bmob.bmobAppId.isNotEmpty) {
      //没有加密
      map["X-Bmob-Application-Id"] = Bmob.bmobAppId;
      map["X-Bmob-REST-API-Key"] = Bmob.bmobRestApiKey;
    } else if (Bmob.bmobSecretKey.isNotEmpty) {
      //加密
      int? indexQuestion = path.indexOf("?");

      if (indexQuestion != -1) {
        path = path.substring(0, indexQuestion);
      }
      var nonceStrKey = getNoncestrKey();
      var safeTimeStamp = getSafeTimestamp();

      map["X-Bmob-SDK-Type"] = Bmob.bmobSDKType;
      map["X-Bmob-SDK-Version"] = Bmob.bmobSDKVersion;
      map["X-Bmob-Secret-Key"] = Bmob.bmobSecretKey;
      map["X-Bmob-Safe-Timestamp"] = safeTimeStamp;
      map["X-Bmob-Noncestr-Key"] = nonceStrKey;
      map["X-Bmob-Safe-Sign"] =
          getSafeSign(path, nonceStrKey, safeTimeStamp, data);
    } else {
      //没有初始化
      debugPrint("请先进行SDK的初始化，再进行网络请求。");
    }

    map["Content-Type"] = "application/json";

    if (Bmob.bmobMasterKey.isNotEmpty) {
      map["X-Bmob-Master-Key"] = Bmob.bmobMasterKey;
    }

    return map;
  }
}
