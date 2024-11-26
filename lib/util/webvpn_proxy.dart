import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/fdu/uis_login_tool.dart';
import 'package:dan_xi/repository/independent_cookie_jar.dart';
import 'package:dan_xi/repository/readonly_cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class WebvpnRequestException implements Exception {
  final String? message;

  WebvpnRequestException([this.message]);

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

  // Cookies related with webvpn
  static final ReadonlyCookieJar webvpnCookieJar = ReadonlyCookieJar();

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

  static PersonInfo? _personInfo;

  /// Keep track with the previous listener added so that it won't be lost
  static VoidCallback? _prevListener;

  static String getWebvpnUri(String uri) {
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

  /// Bind WebVPN proxy to a person info so that it updates automatically when [personInfo] changes.
  /// If you want to unbind, call this function with set [unbind] set to true.
  static void bindPersonInfo(ValueNotifier<PersonInfo?> personInfo) async {
    // Remove any previously added listener to avoid having more than one listener at a time
    if (_prevListener != null) {
      personInfo.removeListener(_prevListener!);
    }

    // Listener that enforces webvpn to re-login when UIS info changes
    _prevListener = () {
      isLoggedIn = false;
      _personInfo = personInfo.value;
    };

    personInfo.addListener(_prevListener!);
  }

  static Future<void> loginWebvpn(Dio dio) async {
    if (!isLoggedIn) {
      // Another concurrent task is running
      if (loginSession != null) {
        await loginSession;
        return;
      }

      debugPrint("Logging into WebVPN");

      // Temporary cookie jar
      IndependentCookieJar workJar = IndependentCookieJar();
      loginSession =
          UISLoginTool.loginUIS(dio, WEBVPN_LOGIN_URL, workJar, _personInfo);
      await loginSession;

      // Clone from temp jar to our dedicated webvpn jar
      webvpnCookieJar.cloneFrom(workJar);
      loginSession = null;
      isLoggedIn = true;
    }
  }

  static Future<Response<T>> requestWithProxy<T>(
      Dio dio, RequestOptions options) async {
    // If we haven't tried direct link, or webvpn is not enabled in settings, or UIS isn't logged in,
    // we should try to request directly.
    if (!directLinkFailed ||
        !SettingsProvider.getInstance().useWebvpn ||
        _personInfo == null) {
      try {
        final response = await dio.fetch<T>(options);
        return response;
      } on DioException catch (e) {
        debugPrint(
            "Direct connection failed, trying to connect through proxy: $e");
        // Do not continue to try with WebVPN if webvpn isn't enabled or UIS isn't logged in
        if (!SettingsProvider.getInstance().useWebvpn || _personInfo == null) {
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
    options.path = WebvpnProxy.getWebvpnUri(options.path);

    // Protect `POST` against 302 exceptions
    if (options.method == "POST") {
      options.validateStatus = (status) {
        return status != null && status < 400;
      };
    }

    // See: https://github.com/DanXi-Dev/DanXi/issues/362#issuecomment-2267446801
    if (options.method == "PUT") {
      options.method = "PATCH";
      options.path += "/_webvpn";
    }

    // Try logging in first, will return immediately if we've already logged in
    await loginWebvpn(dio);

    // First attempt
    Response<T> response = await dio.fetch<T>(options);
    if (checkResponse(response)) {
      return response;
    }

    // Re-login
    isLoggedIn = false;
    await loginWebvpn(dio);

    // Second attempt
    response = await dio.fetch<T>(options);
    if (checkResponse(response)) {
      return response;
    }

    // All attempts failed
    throw WebvpnRequestException(
        "Request through WebVPN failed after two attempts to login and request");
  }
}
