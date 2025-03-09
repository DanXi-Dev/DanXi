import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:dan_xi/model/person.dart';
import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/fdu/uis_login_tool.dart';
import 'package:dan_xi/repository/cookie/independent_cookie_jar.dart';
import 'package:dan_xi/repository/cookie/readonly_cookie_jar.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dan_xi/util/io/user_agent_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:dio5_log/interceptor/diox_log_interceptor.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/cupertino.dart';
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
  // These async session objects work like a mutex with `try_acquire`, which only allow one concurrent action and blocks all other requesters until the action completes
  static Future<void>? loginSession;
  static Future<bool>? tryDirectSession;

  static bool isLoggedIn = false;
  static bool? canConnectDirectly;

  // Cookies related with webvpn
  static final ReadonlyCookieJar webvpnCookieJar = ReadonlyCookieJar();

  static const String DIRECT_CONNECT_TEST_URL = "https://forum.fduhole.com";

  static const String WEBVPN_UIS_LOGIN_URL =
      "https://uis.fudan.edu.cn/authserver/login?service=https%3A%2F%2Fid.fudan.edu.cn%2Fidp%2FthirdAuth%2Fcas";
  static const String WEBVPN_ID_REQUEST_URL =
      "https://id.fudan.edu.cn/idp/authCenter/authenticate?service=https%3A%2F%2Fwebvpn.fudan.edu.cn%2Flogin%3Fcas_login%3Dtrue";
  static const String WEBVPN_LOGIN_URL = "https://webvpn.fudan.edu.cn/login";

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
        "https://webvpn.fudan.edu.cn/https/77726476706e69737468656265737421f9fa409b227e6e546b0086a09d1b203ab8",
    "yjsxk.fudan.edu.cn":
        "https://webvpn.fudan.edu.cn/http/77726476706e69737468656265737421e9fd52842c7e6e457a0987e29d51367bba7b"
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

  // Check if we should login to WebVPN. Return `true` if we should login now.
  static bool isResponseRequiringLogin(Response<dynamic> response) {
    // When 302 is raised when the method is `POST`, it means that we haven't logged in
    if (response.requestOptions.method == "POST" &&
        response.statusCode == 302 &&
        response.headers['location'] != null &&
        response.headers['location']!.isNotEmpty) {
      return true;
    }

    /// Get the absolute final URL of the response (after all redirects).
    ///
    /// [response.realUri] is not always the final URL, because it may be a relative URL (i.e., /login).
    String getAbsoluteFinalURL(Response<dynamic> response) {
      final realUri = response.realUri;
      if (realUri.isAbsolute) return realUri.toString();

      // find the real origin in the reverse order
      for (final redirect in response.redirects.reversed) {
        if (redirect.location.isAbsolute) {
          return redirect.location.origin + realUri.toString();
        }
      }

      return response.requestOptions.uri.origin + realUri.toString();
    }

    final finalUrl = getAbsoluteFinalURL(response);
    debugPrint("Response URL: $finalUrl");
    if (finalUrl.startsWith(WEBVPN_LOGIN_URL)) {
      return true;
    }

    return false;
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

      try {
        Dio newDio = DioUtils.newDioWithProxy();
        newDio.options = BaseOptions(
            receiveDataWhenStatusError: true,
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            sendTimeout: const Duration(seconds: 5));
        newDio.interceptors.add(UserAgentInterceptor(
            userAgent: SettingsProvider.getInstance().customUserAgent));
        // Temporary cookie jar
        IndependentCookieJar workJar = IndependentCookieJar();
        newDio.interceptors.add(CookieManager(workJar));
        newDio.interceptors.add(DioLogInterceptor());

        loginSession = _authenticateWebVPN(newDio, workJar, _personInfo);
        await loginSession;

        webvpnCookieJar.cloneFrom(workJar);
        isLoggedIn = true;
      } catch (e) {
        debugPrint("Failed to login to WebVPN: $e");
        isLoggedIn = false;
        rethrow;
      } finally {
        loginSession = null;
      }
      // Any exception thrown won't be caught and will be propagated to widgets
    }
  }

  static Future<void> _authenticateWebVPN(
      Dio dio, IndependentCookieJar jar, PersonInfo? info) async {
    Response<dynamic>? res = await dio.get(WEBVPN_ID_REQUEST_URL,
        options: DioUtils.NON_REDIRECT_OPTION_WITH_FORM_TYPE);
    if (DioUtils.getRedirectLocation(res) != null) {
      // if we are redirected to UIS, we need to login to UIS first
      await DioUtils.processRedirect(dio, res);
      res = await UISLoginTool.loginUIS(dio, WEBVPN_UIS_LOGIN_URL, jar, info);
      if (res == null) {
        throw WebvpnRequestException("Failed to login to UIS");
      }
    }
    final ticket = _retrieveTicket(res);

    Map<String, dynamic> queryParams = {
      'cas_login': 'true',
      'ticket': ticket,
    };

    final response = await dio.get(WEBVPN_LOGIN_URL,
        queryParameters: queryParams,
        options: DioUtils.NON_REDIRECT_OPTION_WITH_FORM_TYPE);
    await DioUtils.processRedirect(dio, response);
  }

  static String? _retrieveTicket(Response<dynamic> response) {
    // Check if the URL host matches the expected value
    if (response.realUri.host != "id.fudan.edu.cn") {
      return null;
    }

    BeautifulSoup soup = BeautifulSoup(response.data!);

    final element = soup.find('', selector: '#ticket');
    return element?.attributes['value'];
  }

  /// Check if we are able to connect to the service directly (without WebVPN).
  /// This method uses a low-timeout dio to reduce wait time.
  static Future<bool> tryDirect<T>() async {
    final dioOptions = BaseOptions(
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(seconds: 1),
        receiveTimeout: const Duration(seconds: 1),
        sendTimeout: const Duration(seconds: 1));
    // A low-timeout dio
    Dio fastDio = DioUtils.newDioWithProxy(dioOptions);

    try {
      await fastDio.get(DIRECT_CONNECT_TEST_URL);
      // Request succeeds
      return true;
    } on DioException catch (e) {
      // Under these circumstances, at least we can find the server successfully, so we can assume that direct request does work.
      if (e.type == DioExceptionType.badResponse ||
          e.type == DioExceptionType.badCertificate) {
        return true;
      }

      // We cannot even connect to the server
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        debugPrint(
            "Direct connection timeout, trying to connect through proxy: $e");
        return false;
      }

      // Misc errors, not related to connectivity to danta server, just leave a log and return `false`
      debugPrint("Direct connection failed due to an unexpected reason: $e");
      return false;
    } catch (e) {
      debugPrint("Unknown problem when trying direct access: $e");
      return false;
    }
  }

  /// Request with auto-fallback to WebVPN (if enabled in settings)
  static Future<Response<T>> requestWithProxy<T>(
      Dio dio, RequestOptions options) async {
    // Try with direct connect if we haven't even tried
    if (canConnectDirectly == null) {
      // The first request submits the job to evaluate if direct connection works and waits for result.
      // Other concurrent requests just simply wait for the result.
      tryDirectSession ??= tryDirect();
      canConnectDirectly = await tryDirectSession!;
    }

    // If we can connect through direct request, or webvpn is not enabled in settings, or UIS isn't logged in, we should try to request directly.
    if (canConnectDirectly! ||
        !SettingsProvider.getInstance().useWebvpn ||
        _personInfo == null) {
      try {
        final response = await dio.fetch<T>(options);
        return response;
      } on DioException catch (e) {
        // Connection timeout, may happen when we were connected to Fudan LAN when making the first request but later disconnected
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError) {
          // Not allowed to use WebVPN, we have to rethrow
          if (!SettingsProvider.getInstance().useWebvpn ||
              _personInfo == null) {
            rethrow;
          }

          canConnectDirectly = false;
          debugPrint(
              "Direct connection timeout, trying to connect through proxy: $e");
        } else {
          // Misc Internet error, just rethrow
          rethrow;
        }
      } catch (e) {
        // Misc error, just rethrow
        debugPrint("Unknown problem when trying direct access: $e");
        rethrow;
      }
    }

    // Turn to the proxy
    // Replace path with translated path
    options.path = WebvpnProxy.getWebvpnUri(options.path);

    // Protect `POST` against 302 exceptions
    if (options.method == "POST") {
      options.validateStatus = (status) {
        return status != null && status < 400;
      };
    }

    // Try logging in first, will return immediately if we've already logged in
    await loginWebvpn(dio);

    // First attempt
    try {
      Response<T> response = await DioUtils.fetchWithJsonError(dio, options);
      if (!isResponseRequiringLogin(response)) {
        return response;
      }
    } on DioException catch (e) {
      if (e.response == null) {
        rethrow;
      }
      if (!isResponseRequiringLogin(e.response!)) {
        rethrow;
      }
    }

    // Re-login
    isLoggedIn = false;
    await loginWebvpn(dio);

    // Second attempt
    try {
      Response<T> response = await DioUtils.fetchWithJsonError(dio, options);
      if (!isResponseRequiringLogin(response)) {
        return response;
      }
    } on DioException catch (e) {
      if (e.response == null) {
        rethrow;
      }
      if (!isResponseRequiringLogin(e.response!)) {
        rethrow;
      }
    }

    // All attempts failed
    throw WebvpnRequestException(
        "Request through WebVPN failed after two attempts to login and request");
  }
}
