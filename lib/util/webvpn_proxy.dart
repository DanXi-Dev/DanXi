import 'dart:io';
import 'dart:convert';

import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/uis_login_tool.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mutex/mutex.dart';

class WebVpnLoginException implements Exception {
  final String? message;

  WebVpnLoginException([this.message]);

  @override
  String toString() {
    if (message == null) return "Login to WebVPN has failed";
    return "Login to WebVPN has failed: $message";
  }
}

class WebvpnProxy {
  // Mutex used to guarantee that only one concurrent request performs the login action
  static Future<void>? loginSession;
  static bool isLoggedIn = false;
  static bool directLinkFailed = false;

  static const String WEBVPN_LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Fwebvpn.fudan.edu.cn%2Flogin%3Fcas_login%3Dtrue";

  static final Map<String, String> _vpnPrefix = {
    "www.fduhole.com":
        "https://webvpn.fudan.edu.cn/https/77726476706e69737468656265737421e7e056d221347d5871048ce29b5a2e",
    "auth.fduhole.com":
        "https://webvpn.fudan.edu.cn/https/77726476706e69737468656265737421f1e2559469366c45760785a9d6562c38",
    "danke.fduhole.com":
        "https://webvpn.fudan.edu.cn/https/77726476706e69737468656265737421f4f64f97227e6e546b0086a09d1b203a73",
    "forum.fduhole.com":
        "https://webvpn.fudan.edu.cn/https/77726476706e69737468656265737421f6f853892a7e6e546b0086a09d1b203a46",
    "image.fduhole.com":
        "https://webvpn.fudan.edu.cn/https/77726476706e69737468656265737421f9fa409b227e6e546b0086a09d1b203ab8"
  };

  static String getWebVpnUri(String uri) {
    Uri? u = Uri.tryParse(uri);
    if (u == null) {
      return uri;
    }

    if (_vpnPrefix.containsKey(u.host)) {
      String prefix = "https://${u.host}";
      String proxiedUri = uri;
      if (uri.startsWith(prefix)) {
        proxiedUri = _vpnPrefix[u.host]! + uri.substring(prefix.length);
      }

      return proxiedUri;
    } else {
      return uri;
    }
  }

  // Check if we have logged in to WebVPN, returns false if we haven't
  static bool checkResponse(Response<dynamic> response) {
    // When 302 is raised when the method is `POST`, it means that we haven't logged in
    if (response.requestOptions.method == "POST" &&
        response.statusCode == 302 &&
        response.headers['location'] != null &&
        response.headers['location']!.isNotEmpty) {
      return false;
    }

    if (response.realUri
        .toString()
        .startsWith("https://webvpn.fudan.edu.cn/login")) {
      return false;
    }

    return true;
  }

  /// Guard after
  static Future<void> loginWebVpn(Dio dio) async {
    if (!isLoggedIn) {
      // Another concurrent task is running
      if (loginSession != null) {
        await loginSession;
        return;
      }

      debugPrint("Logging into WebVPN");
      loginSession = UISLoginTool.loginUIS(
          dio,
          WebvpnProxy.WEBVPN_LOGIN_URL,
          BaseRepositoryWithDio.globalCookieJar,
          StateProvider.personInfo.value,
          false);
      await loginSession;
      loginSession = null;
      isLoggedIn = true;
    }
  }

  static Future<T> requestWithProxy<T>(Dio dio, RequestOptions options) async {
    // Try direct link once
    if (!directLinkFailed || !SettingsProvider.getInstance().useWebVpn) {
      try {
        final response = await dio.fetch(options);
        return jsonDecode(response.data!);
      } on DioException catch (e) {
        debugPrint(
            "Direct connection failed, trying to connect through proxy: $e");
        // Throw immediately if `useProxy` is false
        if (!SettingsProvider.getInstance().useWebVpn) {
          rethrow;
        }
      } catch (e) {
        debugPrint("Connection failed with unknown exception: $e");
        rethrow;
      }
    }

    // Turn to the proxy
    directLinkFailed = true;
    // Replace path with translated path
    options.path = WebvpnProxy.getWebVpnUri(options.path);

    if (options.method == "POST") {
      // Protect `POST` against 302 exceptions
      options.validateStatus = (status) {
        return status != null && status < 400;
      };
    }

    // Login if first attempt failed
    await loginWebVpn(dio);

    // First attempt
    Response<dynamic> response = await dio.fetch(options);
    if (checkResponse(response)) {
      return jsonDecode(response.data!);
    }

    // Reauth
    isLoggedIn = false;
    await loginWebVpn(dio);

    response = await dio.fetch(options);
    if (checkResponse(response)) {
      return jsonDecode(response.data!);
    }

    throw WebVpnLoginException(options.method);
  }
}
