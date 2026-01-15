import 'dart:convert';

import 'package:dan_xi/provider/settings_provider.dart';
import 'package:dan_xi/repository/fdu/neo_login_tool.dart';
import 'package:dan_xi/util/io/dio_utils.dart';
import 'package:dio/dio.dart';
import 'package:dio_redirect_interceptor/dio_redirect_interceptor.dart';
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

/// An interceptor that intercepts requests and routes them through WebVPN if needed.
///
/// # Order of interceptors
/// This interceptor should be added BEFORE [RedirectInterceptor] but AFTER any other interceptors.
class WebVPNInterceptor extends Interceptor {
  static final Map<String, String> _vpnPrefix = {
    "www.fduhole.com":
        "https://$WEBVPN_HOST/{scheme}/77726476706e69737468656265737421e7e056d221347d5871048ce29b5a2e",
    "auth.fduhole.com":
        "https://$WEBVPN_HOST/{scheme}/77726476706e69737468656265737421f1e2559469366c45760785a9d6562c38",
    "danke.fduhole.com":
        "https://$WEBVPN_HOST/{scheme}/77726476706e69737468656265737421f4f64f97227e6e546b0086a09d1b203a73",
    "forum.fduhole.com":
        "https://$WEBVPN_HOST/{scheme}/77726476706e69737468656265737421f6f853892a7e6e546b0086a09d1b203a46",
    "image.fduhole.com":
        "https://$WEBVPN_HOST/{scheme}/77726476706e69737468656265737421f9fa409b227e6e546b0086a09d1b203ab8",
    "yjsxk.fudan.edu.cn":
        "https://$WEBVPN_HOST/{scheme}/77726476706e69737468656265737421e9fd52842c7e6e457a0987e29d51367bba7b",
    "10.64.130.6":
        "https://$WEBVPN_HOST/{scheme}/77726476706e69737468656265737421a1a70fca737e39032e46df",
  };
  static const String DIRECT_CONNECT_TEST_URL = "https://forum.fduhole.com";
  static const String EXTRA_ROUTE_TYPE = "webvpn_route_type";
  static const String EXTRA_ORIGINAL_URL = "webvpn_original_url";
  static const String WEBVPN_HOST = "webvpn.fudan.edu.cn";
  static final Uri WEBVPN_LOGIN_URL =
      Uri.parse("https://$WEBVPN_HOST/login?cas_login=true");
  static const String WEBVPN_REDIRECTED_TO_LOGIN_PREFIX = "https://$WEBVPN_HOST/login";

  static Future<bool>? tryDirectSession;
  static bool? _canConnectDirectly;

  /// Try to translate a URL to its WebVPN equivalent. Return `null` if the URL is not supported by WebVPN.
  static String? tryTranslateUrlToWebVPN(String url) {
    Uri? u = Uri.tryParse(url);
    if (u == null) {
      return null;
    }

    final uriScheme = u.scheme.isEmpty ? "http" : u.scheme;
    if (uriScheme != "http" && uriScheme != "https") {
      return null;
    }

    if (_vpnPrefix.containsKey(u.host)) {
      final vpnPrefix = _vpnPrefix[u.host]!;
      final urlPrefix = "$uriScheme://${u.host}";
      if (url.startsWith(urlPrefix)) {
        final translatedUrl =
            url.replaceFirst(urlPrefix, vpnPrefix.replaceFirst("{scheme}", uriScheme));
        return translatedUrl;
      } else {
        return null;
      }
    } else {
      return null;
    }
  }

  /// Check if we are able to connect to the service directly (without WebVPN).
  /// This method uses a low-timeout dio to reduce wait time.
  static Future<bool> tryDirect() async {
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

  /// Priorly validate the response to see if it indicates a successful request.
  ///
  /// Throws exception if the response is invalid.
  Response<dynamic> validateResponse(Response<dynamic> response) {
    if (response.realUri.toString().startsWith(WEBVPN_REDIRECTED_TO_LOGIN_PREFIX)) {
      throw WebvpnRequestException(
          "Request through WebVPN failed: not logged in");
    }
    if (response.requestOptions.responseType == ResponseType.json) {
      if (response.data is! Map && response.data is! List) {
        // If the response is not a JSON object or array, try to decode it
        jsonDecode(response.data.toString());
      }
    }
    return response;
  }

  /// Handle a request through WebVPN
  Future<void> handleWebVPNRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final translatedUrl = tryTranslateUrlToWebVPN(options.path);
    options.path = translatedUrl ?? options.path;
    options.extra[EXTRA_ROUTE_TYPE] =
        translatedUrl != null ? "webvpn_proxied" : "webvpn_direct";

    try {
      debugPrint(
          "Requesting through WebVPN: ${options.method} ${options.path}");
      final proxiedResponse = await FudanSession.request(
          options, validateResponse,
          manualLoginUrl: WEBVPN_LOGIN_URL);
      return handler.resolve(proxiedResponse, true);
    } on DioException catch (e) {
      return handler.reject(e, true);
    }
  }

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    options.extra[EXTRA_ORIGINAL_URL] = options.path;
    // Try with direct connect if we haven't even tried
    if (_canConnectDirectly == null) {
      // The first request submits the job to evaluate if direct connection works and waits for result.
      // Other concurrent requests just simply wait for the result.
      tryDirectSession ??= tryDirect();
      _canConnectDirectly = await tryDirectSession;
    }

    if (_canConnectDirectly! || !SettingsProvider.getInstance().useWebvpn) {
      // If we can connect through direct request, or WebVPN is not enabled in settings, we should try to request directly.
      options.extra[EXTRA_ROUTE_TYPE] = "direct";
      return handler.next(options);
    }

    // Turn to the proxy
    await handleWebVPNRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isNotRouted = err.requestOptions.extra[EXTRA_ROUTE_TYPE] == "direct";
    final isConnectionError = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.connectionError;
    if (isNotRouted && isConnectionError) {
      _canConnectDirectly = false;
      // FIXME: should retry the request through WebVPN here. But [onError] cannot be async.
      debugPrint(
          "Direct connection timeout, trying to connect through proxy next time: $err");
    }
    return handler.next(err);
  }
}

class WebvpnProxy {
  static Future<Response<T>> requestWithProxy<T>(
      Dio dio, RequestOptions options) async {
    return await dio.fetch<T>(options);
  }
}
