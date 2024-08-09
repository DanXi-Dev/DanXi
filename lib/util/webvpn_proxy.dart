import 'dart:io';
import 'dart:convert';

import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/provider/state_provider.dart';
import 'package:dan_xi/repository/base_repository.dart';
import 'package:dan_xi/repository/fdu/uis_login_tool.dart';
import 'package:dio/dio.dart';
import 'package:dio5_log/dio_log.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:mutex/mutex.dart';

class WebvpnProxy {
  // Mutex used to guarantee that only one concurrent request performs the login action
  static Mutex loginMutex = Mutex();
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
    Response<dynamic> response = await dio.fetch(options);

    // If not redirected to login, then return
    if (!response.realUri
        .toString()
        .startsWith("https://webvpn.fudan.edu.cn/login")) {
      return jsonDecode(response.data!);
    }

    // Login and retry
    await loginMutex.acquire();
    if (!isLoggedIn) {
      // Though [loginUIS] itself is protected by a mutex, we still wrap it in an additional mutex to avoid undue calling
      await UISLoginTool.loginUIS(
          dio,
          WebvpnProxy.WEBVPN_LOGIN_URL,
          BaseRepositoryWithDio.globalCookieJar,
          StateProvider.personInfo.value,
          false);
      isLoggedIn = true;
    }
    loginMutex.release();

    response = await dio.fetch(options);
    if (response.realUri
        .toString()
        .startsWith("https://webvpn.fudan.edu.cn/login")) {
      // Mark that the webvpn login session has expired, it will be renewed in new request
      isLoggedIn = false;
    }

    return jsonDecode(response.data!);
  }
}
